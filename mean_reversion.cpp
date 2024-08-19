#include <vector>
#include <numeric>
using namespace std;

double calculateSMA(const vector<double>& prices, int period) {
    if(prices.size()< period) return 0.0;
    double sum = accumulate(prices.end() - period, prices.end(), 0.0);
    return sum / period;

}


double calculateEMA(const std::vector<double>& prices, int period) {
    if (prices.size() < period) return 0.0;

    double multiplier = 2.0 / (period + 1);
    double ema = prices[prices.size() - period]; // Starting EMA as the first price in the period

    for (int i = prices.size() - period + 1; i < prices.size(); ++i) {
        ema = ((prices[i] - ema) * multiplier) + ema;
    }
    return ema;
}

struct BollingerBands {
    double upperBand;
    double lowerBand;
    double middleBand;
};

BollingerBands calculateBollingerBands(const std::vector<double>& prices, int period, double stdDevMultiplier = 2.0) {
    double sma = calculateSMA(prices, period);
    double sumSquares = 0.0;
    
    for (int i = prices.size() - period; i < prices.size(); ++i) {
        sumSquares += std::pow(prices[i] - sma, 2);
    }
    
    double stdDev = std::sqrt(sumSquares / period);
    BollingerBands bands;
    bands.middleBand = sma;
    bands.upperBand = sma + (stdDevMultiplier * stdDev);
    bands.lowerBand = sma - (stdDevMultiplier * stdDev);

    return bands;
}

double calculateRSI(const std::vector<double>& prices, int period) {
    if (prices.size() < period + 1) return 0.0;

    double gains = 0.0, losses = 0.0;

    for (int i = prices.size() - period; i < prices.size(); ++i) {
        double change = prices[i] - prices[i - 1];
        if (change > 0) gains += change;
        else losses -= change;
    }

    double averageGain = gains / period;
    double averageLoss = losses / period;

    double rs = averageGain / averageLoss;
    return 100.0 - (100.0 / (1.0 + rs));
}


#include <iostream>
#include <vector>

class MeanReversionStrategy {
private:
    double capital;
    double positionSize;
    double stopLossPercentage;
    int smaPeriod;
    int emaPeriod;
    int rsiPeriod;
    int bollingerPeriod;
    double stdDevMultiplier;

public:
    MeanReversionStrategy(double initCapital, double positionSizePct, double stopLossPct, int smaP, int emaP, int rsiP, int bollingerP, double stdDevMult)
        : capital(initCapital), positionSize(positionSizePct), stopLossPercentage(stopLossPct), smaPeriod(smaP), emaPeriod(emaP),
          rsiPeriod(rsiP), bollingerPeriod(bollingerP), stdDevMultiplier(stdDevMult) {}

    void execute(const std::vector<double>& prices) {
        for (size_t i = bollingerPeriod; i < prices.size(); ++i) {
            std::vector<double> currentPrices(prices.begin(), prices.begin() + i);

            double sma = calculateSMA(currentPrices, smaPeriod);
            double ema = calculateEMA(currentPrices, emaPeriod);
            BollingerBands bands = calculateBollingerBands(currentPrices, bollingerPeriod, stdDevMultiplier);
            double rsi = calculateRSI(currentPrices, rsiPeriod);

            double currentPrice = currentPrices.back();
            double positionValue = capital * positionSize;

            if (currentPrice < bands.lowerBand && rsi < 30) {
                // Buy signal
                double sharesToBuy = positionValue / currentPrice;
                double stopLoss = currentPrice * (1 - stopLossPercentage);

                std::cout << "Buying " << sharesToBuy << " shares at $" << currentPrice << " with stop loss at $" << stopLoss << std::endl;
            } else if (currentPrice > sma || currentPrice > ema) {
                // Sell signal (reversion to mean)
                std::cout << "Selling shares at $" << currentPrice << " (Mean Reversion)" << std::endl;
            }
        }
    }
};


void backtest(const std::vector<double>& historicalPrices) {
    MeanReversionStrategy strategy(100000, 0.1, 0.02, 20, 20, 14, 20, 2.0);
    strategy.execute(historicalPrices);
}

int main() {
    // Example data
    std::vector<double> historicalPrices = {
    100, 98, 97, 95, 94, // Prices drop below the Bollinger Band, triggering a buy signal
    96, 98, 100, 103, 105, // Prices rise back to the mean (SMA/EMA), triggering a sell signal
    107, 105, 103, 102, 100, 
    98, 95, 92, 90, 88, // Another drop below Bollinger Band
    91, 94, 97, 100, 103 // Reversion back to the mean
};

    backtest(historicalPrices);

    return 0;
}