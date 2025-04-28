source("functions.R")
library(lubridate)
setwd("C:/Users/omare/Documents")

dates <- c("20230803", "20230808", "20240627", "20240702",
           "20240707",
           "20240712",
           "20240718",
           "20240728")
ts_date <- "20240813"

#####

df_test <- load_data(paste0(ts_date, ".csv"), format(ymd(ts_date), "%B %d, %Y"))
formatted_dates <- format(ymd(dates), "%B %d, %Y")
df_base_list <- Map(load_data, paste0(dates, ".csv"), formatted_dates)

#####

df_base <- bind_rows(df_base_list)

# Apply CI calculations and anomaly detection
df_base <- compute_ci(df_base, df_test)
df_data <- left_join(df_base, df_test, by = c("lat", "lon"))

df_data$anomaly <- ifelse(is.na(df_data$wse_filtered) | df_data$wse_filtered < df_data$lower_ci_wse | df_data$wse_filtered > df_data$upper_ci_wse, TRUE, FALSE)
df_data$anomaly <- ifelse(is.na(df_data$wse_filtered), FALSE, df_data$anomaly)

df_anomalies_only <- df_data %>% filter(anomaly == TRUE)

print(df_data, na.print = "NA", n = 1000)
plot_graph(df_data, length(dates))
