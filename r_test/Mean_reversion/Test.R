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
  mutate(Local_time = dmy_hms(`Local.time`))
print("Local.time converted to POSIXct:")
print(head(data))

# Ensure data is sorted by time
data <- data %>%
  arrange(Local_time)
print("Data sorted by Local_time:")
print(head(data))

# Remove rows where volume is 0
data <- data %>%
  filter(Volume > 0)
print("Rows with volume = 0 removed:")
print(head(data))

# Calculate the 20-period Exponential Moving Average
data <- data %>%
  mutate(EMA = EMA(Close, n = 20))
print("20-period EMA calculated:")
print(head(data, 30))  # Print more rows to check for NA values

# Calculate Bollinger Bands
bbands <- BBands(HLC = data[, c("High", "Low", "Close")], n = 20, sd = 2)
data <- data %>%
  mutate(
    BB_upper = bbands[, "up"],
    BB_middle = bbands[, "mavg"],
    BB_lower = bbands[, "dn"]
  )
print("Bollinger Bands calculated:")
print(head(data, 30))  # Print more rows to check for NA values

# Calculate MACD and Signal Line
macd_values <- MACD(data$Close, nFast = 12, nSlow = 26, nSig = 9)
data <- data %>%
  mutate(
    MACD = macd_values[, "macd"],
    MACD_signal = macd_values[, "signal"]
  )
print("MACD and Signal Line calculated:")
print(head(data, 30))  # Print more rows to check for NA values

# Normalize the indicators between 0 and 1
normalize <- function(x) {
  (x - min(x, na.rm = TRUE)) / (max(x, na.rm = TRUE) - min(x, na.rm = TRUE))
}

data <- data %>%
  mutate(
    Norm_EMA = normalize(EMA),
    Norm_BB_upper = normalize(BB_upper),
    Norm_BB_lower = normalize(BB_lower),
    Norm_MACD = normalize(MACD),
    Norm_MACD_signal = normalize(MACD_signal)
  )
print("Indicators normalized:")
print(head(data, 30))  # Print more rows to check normalization

# Combine normalized indicators with weights
data <- data %>%
  mutate(
    Combined_Score = (Norm_EMA * 0.4) + (Norm_BB_lower * 0.3) + (Norm_MACD * 0.3)
  )
print("Combined Score calculated:")
print(head(data, 30))  # Print more rows to check combined score

# Generate combined trade signals based on the combined score
data <- data %>%
  mutate(
    Signal = case_when(
      Combined_Score > 0.6 ~ "Buy",  # Adjust threshold as needed
      Combined_Score < 0.4 ~ "Sell",  # Adjust threshold as needed
      TRUE ~ "Hold"
    )
  )
print("Trade signals generated:")
print(head(data, 30))  # Print more rows to see trade signals

# Define risk parameters and maximum shares
total_shares <- 5000  # Maximum number of shares to be bought or sold

# Initialize tracking variables
current_position <- 0

# Function to calculate trade size while staying within the limit
calculate_trade_size <- function(signal, current_position, max_shares) {
  if (signal == "Buy") {
    trade_size <- min(max_shares - current_position, max_shares)
  } else if (signal == "Sell") {
    trade_size <- min(current_position, max_shares)
  } else {
    trade_size <- 0
  }
  return(trade_size)
}

# Allocate shares and adjust position based on signals
data <- data %>%
  rowwise() %>%
  mutate(
    Trade_Size = calculate_trade_size(Signal, current_position, total_shares),
    current_position = ifelse(Signal == "Buy", current_position + Trade_Size, 
                              ifelse(Signal == "Sell", current_position - Trade_Size, current_position))
  ) %>%
  ungroup()

print("Data with Trade Size and Adjusted Position:")
print(head(data, 30))  # Print more rows to check trade sizes and positions

# Optionally save the processed data with trade signals to a new CSV file
write.csv(data, "/Users/rishit/Desktop/Finance/Algotrading system/data_processed_with_signals_and_positions.csv", row.names = FALSE)
print("Processed data with trade signals and positions saved to CSV.")