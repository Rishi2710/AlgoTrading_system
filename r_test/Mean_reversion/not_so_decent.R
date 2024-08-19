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
  mutate(hour = hour(Local.time),
         minute = minute(Local.time),
         time_value = hour * 100 + minute) %>%
  filter((time_value >= 2000) | (time_value <= 230))

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
    ),
    Cumulative_Buys = cumsum(Signal == "Buy"),
    Can_Sell = Cumulative_Buys > 0
  ) %>%
  mutate(
    Signal = case_when(
      Signal == "Sell" & Can_Sell ~ "Sell",
      Signal == "Sell" & !Can_Sell ~ "Hold",
      TRUE ~ Signal
    )
  )

# Dynamic Position Sizing: allocate based on signal strength, but ensure total does not exceed 500 units
max_units <- 500

data <- data %>%
  mutate(
    Signal_Strength = case_when(
      Signal == "Buy" ~ (Lower_Band - Close) / Lower_Band,
      Signal == "Sell" & Can_Sell ~ (Close - Upper_Band) / Upper_Band,
      TRUE ~ 0
    ),
    Position_Size = ifelse(Signal == "Buy", max_units * Signal_Strength, 0),
    Position_Size = ifelse(Signal == "Sell", -lag(Position_Size, default = 0), Position_Size)
  ) %>%
  mutate(
    Cumulative_Position = cumsum(Position_Size),
    Position_Size = ifelse(Cumulative_Position < 0, 0, Position_Size)
  )

# Calculate minute-based returns
data <- data %>%
  mutate(
    Prev_Close = lag(Close, default = Close[1]),
    Minute_Return = ifelse(Signal == "Sell",
                           (Close - Prev_Close) * abs(Position_Size),
                           (Close - Prev_Close) * Position_Size)
  )

# Calculate cumulative returns
data <- data %>%
  mutate(
    Minute_Return = ifelse(is.na(Minute_Return), 0, Minute_Return),
    Cumulative_Return = cumsum(Minute_Return)
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
write.csv(data, "/Users/rishit/Desktop/Finance/Algotrading system/data_bollinger_strategy_final.csv", row.names = FALSE)
cat("Processed data with trade signals saved to CSV.\n")