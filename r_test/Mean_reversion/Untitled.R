# Load necessary libraries
library(dplyr)
library(TTR)
library(lubridate)
library(PerformanceAnalytics)
library(xts)

# Define the path to your CSV file
file_path <- "/Users/rishit/Desktop/Finance/Algotrading system/data copy.csv"

# Load the data
data <- read.csv(file_path)
print("Data loaded:")
print(head(data))

# Convert 'Local.time' to a POSIXct date-time object
data <- data %>%
  mutate(Local_time = dmy_hms(`Local.time`))
print("Local.time converted to POSIXct:")
print(head(data))

# Ensure data is sorted by time
data <- data %>%
  arrange(Local_time)
print("Data sorted by Local_time:")
print(head(data))

# Calculate the 20-period Exponential Moving Average (EMA)
data <- data %>%
  mutate(EMA_20 = EMA(Close, n = 20))
print("20-period EMA calculated:")
print(head(data, 30))  # Print more rows to check for NA values

# Calculate the 20-period rolling standard deviation
data <- data %>%
  mutate(SD_20 = runSD(Close, n = 20))
print("20-period rolling standard deviation calculated:")
print(head(data, 30))  # Print more rows to check for NA values

# Calculate the Z-Score
data <- data %>%
  mutate(Z_Score = (Close - EMA_20) / SD_20)
print("Z-Score calculated:")
print(head(data, 30))  # Print more rows to check for NA values

# Define Z-Score thresholds for trade signals
buy_threshold <- -2   # Example threshold for buy signal
sell_threshold <- 2   # Example threshold for sell signal

# Generate trade signals
data <- data %>%
  mutate(
    Signal = case_when(
      Z_Score < buy_threshold ~ "Buy",
      Z_Score > sell_threshold ~ "Sell",
      TRUE ~ "Hold"
    )
  )
print("Trade signals generated:")
print(head(data, 30))  # Print more rows to see trade signals

# Define capital and risk management parameters
capital <- 100000        # Example total capital
risk_per_trade <- 0.02   # Risk 2% of capital per trade
stop_loss_percentage <- 0.02  # Example stop-loss percentage

# Calculate risk amount and position size
risk_amount <- capital * risk_per_trade

# Note: Ensure there is at least one Buy signal to calculate position sizes
data <- data %>%
  mutate(
    Position_Size = if_else(Signal == "Buy", risk_amount / (stop_loss_percentage * Close), 0)
  )
print("Position size calculated:")
print(head(data, 30))  # Print more rows to check position sizes

# Calculate strategy returns
data <- data %>%
  mutate(
    Next_Close = lead(Close),
    Strategy_Returns = case_when(
      Signal == "Buy" ~ (Next_Close - Close) / Close * Position_Size,
      Signal == "Sell" ~ (Close - Next_Close) / Close * Position_Size,
      TRUE ~ 0
    )
  )
print("Strategy returns calculated:")
print(head(data, 30))  # Print more rows to see strategy returns

# Convert strategy returns to xts object
strategy_returns_xts <- xts(data$Strategy_Returns, order.by = data$Local_time)

# Calculate performance metrics
sharpe_ratio <- SharpeRatio.annualized(strategy_returns_xts, scale = 252)

# Print performance metrics
cat("Sharpe Ratio:", sharpe_ratio, "\n")
