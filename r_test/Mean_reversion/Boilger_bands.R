# Load necessary libraries
library(dplyr)
library(TTR)
library(lubridate)

# Define the path to your CSV file
file_path <- "/Users/rishit/Desktop/Finance/Algotrading system/data copy.csv"

# Load the data
data <- read.csv(file_path)
print("Data loaded:")
print(head(data))

# Convert 'Local.time' to a POSIXct date-time object
data <- data %>%
  mutate(Local_time = dmy_hms(`Local.time`)) %>%
  arrange(Local_time)

# Remove rows where volume is 0
data <- data %>%
  filter(Volume > 0)

# Calculate Bollinger Bands with standard parameters
bbands <- BBands(HLC = data[, c("High", "Low", "Close")], n = 20, sd = 2)
data <- data %>%
  mutate(
    BB_upper = bbands[, "up"],
    BB_middle = bbands[, "mavg"],
    BB_lower = bbands[, "dn"]
  )

# Generate trade signals based on Bollinger Bands breakout
data <- data %>%
  mutate(
    Signal = case_when(
      Close < BB_lower ~ "Buy",  # Buy signal when price breaks below lower band
      Close > BB_upper ~ "Sell", # Sell signal when price breaks above upper band
      TRUE ~ "Hold"  # No signal otherwise
    )
  )

# Define maximum units available for investment
total_units <- 5000  # Maximum number of units

# Calculate normalized signal strength based on distance from Bollinger Bands
data <- data %>%
  mutate(
    Signal_Strength = case_when(
      Signal == "Buy" ~ (BB_lower - Close) / BB_lower,
      Signal == "Sell" ~ (Close - BB_upper) / BB_upper,
      TRUE ~ 0
    ),
    Normalized_Signal_Strength = (Signal_Strength - min(Signal_Strength, na.rm = TRUE)) / 
      (max(Signal_Strength, na.rm = TRUE) - min(Signal_Strength, na.rm = TRUE))
  )

# Allocate position size based on normalized signal strength
data <- data %>%
  mutate(
    Position_Size = case_when(
      Signal == "Buy" ~ Normalized_Signal_Strength * total_units,
      Signal == "Sell" ~ -Normalized_Signal_Strength * total_units,
      TRUE ~ 0
    )
  )

# Calculate daily returns handling NA values
data <- data %>%
  mutate(
    Prev_Close = lag(Close, default = Close[1]),  # Get the previous day's close price
    Daily_Return = (Close - Prev_Close) * Position_Size,  # Calculate the daily return
    Clean_Daily_Return = ifelse(is.na(Daily_Return), 0, Daily_Return)  # Replace NA returns with 0
  )

# Calculate cumulative returns
data <- data %>%
  mutate(
    Cumulative_Return = cumsum(Clean_Daily_Return)  # Cumulative sum of daily returns
  )

# Calculate net profit and Sharpe ratio
net_profit <- sum(data$Clean_Daily_Return)  # Sum of all daily returns
mean_return <- mean(data$Clean_Daily_Return, na.rm = TRUE)  # Average of daily returns, ignoring NA
std_dev_return <- sd(data$Clean_Daily_Return, na.rm = TRUE)  # Standard deviation of daily returns, ignoring NA
sharpe_ratio <- mean_return / std_dev_return * sqrt(252)  # Annualized Sharpe Ratio, assuming 252 trading days

print(paste("Net Profit:", net_profit))
print(paste("Sharpe Ratio:", sharpe_ratio))

# Optionally save the processed data with signals and positions to a new CSV file
write.csv(data, "/Users/rishit/Desktop/Finance/Algotrading system/data_bollinger_with_performance.csv", row.names = FALSE)
print("Processed data with trade signals and positions saved to CSV.")