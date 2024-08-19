library(dplyr)
library(TTR)
library(lubridate)
library(PerformanceAnalytics)
library(xts)

# Example data
data <- read.csv("/Users/rishit/Desktop/Finance/Algotrading system/data copy.csv")
data <- data %>% mutate(Local_time = dmy_hms(`Local.time`)) %>%
  arrange(Local_time) %>%
  mutate(SMA_20 = SMA(Close, n = 20),
         SD_20 = runSD(Close, n = 20),
         Z_Score = (Close - SMA_20) / SD_20,
         Signal = case_when(
           Z_Score < -2 ~ "Buy",
           Z_Score > 2 ~ "Sell",
           TRUE ~ "Hold"
         ),
         Strategy_Returns = case_when(
           Signal == "Buy" ~ (lead(Close) - Close) / Close,
           Signal == "Sell" ~ 0,
           TRUE ~ 0
         )) %>%
  na.omit()

strategy_returns_xts <- xts(data$Strategy_Returns, order.by = data$Local_time)
daily_returns_xts <- to.daily(strategy_returns_xts, indexAt = "lastof", na.pad = TRUE)

# Calculate performance metrics
sharpe_ratio <- SharpeRatio.annualized(daily_returns_xts, scale = 252)
cat("Sharpe Ratio:", sharpe_ratio, "\n")

if (length(daily_returns_xts) > 0) {
  max_drawdown <- maxDrawdown(daily_returns_xts)
  annualized_return <- Return.annualized(daily_returns_xts)
  calmar_ratio <- annualized_return / abs(max_drawdown)
  cat("Calmar Ratio:", calmar_ratio, "\n")
  cat("Annualized Return:", annualized_return, "\n")
} else {
  cat("Calmar Ratio: NA (No data available)\n")
  cat("Annualized Return: NA (No data available)\n")
}