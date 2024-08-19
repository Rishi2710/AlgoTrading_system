# Load necessary libraries
library(dplyr)
library(TTR)
library(lubridate)
library(PerformanceAnalytics)
library(xts) # For performance metrics

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

# Check number of rows in data
cat("Number of rows in data:", nrow(data), "\n")

# Calculate the 20-period Simple Moving Average (SMA)
data <- data %>%
  mutate(SMA_20 = SMA(Close, n = 20))
print("20-period SMA calculated:")
print(head(data, 30))  # Print more rows to check for NA values

# Calculate the 20-period rolling standard deviation
data <- data %>%
  mutate(SD_20 = runSD(Close, n = 20))
print("20-period rolling standard deviation calculated:")
print(head(data, 30))  # Print more rows to check for NA values

# Calculate the Z-Score
data <- data %>%
  mutate(Z_Score = (Close - SMA_20) / SD_20)
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

# Inspect the final data with all columns and trade signals
print("Final data with all columns and trade signals:")
print(head(data, 30))
# Calculate strategy returns based on trade signals
data <- data %>%
  mutate(
    Strategy_Returns = case_when(
      Signal == "Buy" ~ (lead(Close) - Close) / Close,  # Return if we buy today and close the position next period
      Signal == "Sell" ~ 0,                            # No return if we sell (i.e., we are out of the market)
      TRUE ~ 0
    )
  )
print("Strategy returns calculated:")
print(head(data, 30))


data <- na.omit(data)
print("NA values removed:")
print(head(data, 30))


strategy_returns_xts <- xts(data$Strategy_Returns, order.by = data$Local_time)
print("Strategy returns converted to xts:")

daily_returns_xts <- to.daily(strategy_returns_xts, indexAt = "lastof", na.pad = TRUE)
print("Converted strategy returns to daily frequency:")


sharpe_ratio <- SharpeRatio.annualized(daily_returns_xts, scale = 252)  # Annualized using 252 trading days
cat("Sharpe Ratio:", sharpe_ratio, "\n")

print(head(daily_returns_xts))