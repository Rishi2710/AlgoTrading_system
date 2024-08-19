# Load necessary libraries
library(dplyr)
library(TTR)
library(zoo)
library(lubridate)

# Define the path to your CSV file
file_path <- "/Users/rishit/Desktop/Finance/Algotrading system/data copy.csv"

# Load the data
data <- read.csv(file_path)

# Ensure the 'Local.time' column is properly formatted as a character before conversion
data$Local.time <- as.character(data$Local.time)

# Convert 'Local.time' to a POSIXct date-time object
data$Local.time <- as.POSIXct(data$Local.time, format="%d.%m.%Y %H:%M:%S", tz="GMT")

# Remove rows where volume is 0
data <- data %>%
  filter(Volume > 0)

# Filter data to include only rows within the trading hours 20:00:00 to 02:30:00
data <- data %>%
  filter(format(Local.time, "%H:%M:%S") >= "20:00:00" | format(Local.time, "%H:%M:%S") <= "02:30:00")

# Calculate Bollinger Bands (20-period moving average, 2 standard deviations)
data <- data %>%
  arrange(Local.time) %>%
  mutate(
    MA = rollmean(Close, 20, fill = NA, align = 'right'),
    SD = rollapply(Close, 20, sd, fill = NA, align = 'right'),
    Upper_Band = MA + (2 * SD),
    Lower_Band = MA - (2 * SD)
  )

# Generate trade signals based on Bollinger Bands
data <- data %>%
  mutate(
    Signal = case_when(
      Close < Lower_Band ~ "Buy",
      Close > Upper_Band ~ "Sell",
      TRUE ~ "Hold"
    )
  )

# Ensure Sell signals only occur after a Buy signal
data <- data %>%
  mutate(
    Invested = lag(cumsum(Signal == "Buy") > 0, default = FALSE),
    Signal = ifelse(Signal == "Sell" & !Invested, "Hold", Signal)
  )

# Dynamic Position Sizing: allocate based on signal strength, but ensure total does not exceed 500 units
max_units <- 500

data <- data %>%
  mutate(
    Signal_Strength = case_when(
      Signal == "Buy" ~ (Lower_Band - Close) / Lower_Band,  # Normalize signal strength
      Signal == "Sell" ~ (Close - Upper_Band) / Upper_Band,
      TRUE ~ 0
    ),
    Position_Size = ifelse(Signal == "Buy", max_units * Signal_Strength, 0),
    Position_Size = ifelse(Signal == "Sell", -lag(Position_Size, default = 0), Position_Size),  # Reduce position to 0 on Sell
    Cumulative_Position = cumsum(Position_Size),
    Position_Size = ifelse(Cumulative_Position < 0, 0, Position_Size)  # Ensure no negative positions
  )

# Calculate minute-based returns
data <- data %>%
  mutate(
    Prev_Close = lag(Close, default = Close[1]),
    Minute_Return = ifelse(Position_Size < 0, 
                           (Close - lag(Close)) * -lag(Position_Size, default = 0), 
                           (Close - Prev_Close) * lag(Position_Size, default = 0))
  )

# Calculate cumulative returns
data <- data %>%
  mutate(
    Minute_Return = ifelse(is.na(Minute_Return), 0, Minute_Return),  # Replace NA with 0
    Cumulative_Return = cumsum(Minute_Return)  # Calculate cumulative sum
  )

# Calculate net returns and Sharpe ratio
net_returns <- sum(data$Minute_Return, na.rm = TRUE)
mean_return <- mean(data$Minute_Return, na.rm = TRUE)
std_dev_return <- sd(data$Minute_Return, na.rm = TRUE)
annualization_factor <- sqrt(252 * 390)  # 252 trading days, 390 minutes per day
sharpe_ratio <- (mean_return / std_dev_return) * annualization_factor

# Output results
cat("Net Returns:", net_returns, "\n")
cat("Sharpe Ratio:", sharpe_ratio, "\n")

# Optionally, save the processed data with signals and returns to a new CSV file
write.csv(data, "/Users/rishit/Desktop/Finance/Algotrading system/data_bollinger_strategy_dynamic.csv", row.names = FALSE)
cat("Processed data with trade signals saved to CSV.\n")