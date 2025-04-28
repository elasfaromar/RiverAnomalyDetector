library(dplyr)
library(ggplot2)
library(readr)
library(zoo)

#####

THRESHOLD <- 5
CONFIDENCE <- 0.90
ROLLING_MEAN <- 5
ROUND <- 3
X_LANDSLIDE <- -122.7888

#####

load_data <- function(file, date_label) {
  df <- read_csv(file) %>%
    filter(lat >= 51.7 & lat <= 52 & lon >= -122.85 & lon <= -122.7 & river_name == "Chilcotin River") %>%
    mutate(
      lat = round(lat, ROUND),   # Round latitude 
      lon = round(lon, ROUND),   # Round longitude 
      Date = date_label      # Add a column to identify the date
    )
  
  # De-spiking data
  # Apply rolling median filter to wse
  df <- df %>%
    arrange(lon) %>%  # Ensure data is sorted before applying rolling median
    mutate(wse_filtered = rollapply(wse, width = ROLLING_MEAN, FUN = median, fill = NA, align = "center")) %>%
    filter(!is.na(wse_filtered))
  
  return(df)
}

compute_ci <- function(df_base, df_test, confidence = CONFIDENCE) {
  df_final <- data.frame(
    lat = double(0),
    lon = double(0),
    mean_wse = double(0),
    sd_wse = double(0),
    lower_ci_wse = double(0),
    upper_ci_wse = double(0)
  )
  
  unique_pairs <- df_base %>%
    group_by(lat, lon) %>%
    filter(n() >= THRESHOLD) %>%
    ungroup() %>%
    distinct(lat, lon)
  
  # Calculate Z-score based on confidence level
  alpha <- 1 - confidence
  z_score <- qnorm(1 - alpha / 2)
  
  for (i in 1:nrow(unique_pairs)) {
    curr_lat <- unique_pairs[i, 1][[1]]
    curr_lon <- unique_pairs[i, 2][[1]]
    
    result_df <- subset(df_base, lat==curr_lat & lon==curr_lon)
    
    n <- nrow(result_df)
    mean <- mean(result_df$wse_filtered, na.rm = TRUE)
    sd <- sd(result_df$wse_filtered, na.rm = TRUE)
    
    error_margin <- z_score * (sd / sqrt(n))
    
    lower_ci = mean - error_margin
    upper_ci = mean + error_margin
    
    df_final <- rbind(df_final, data.frame(
      lat = curr_lat,
      lon = curr_lon,
      mean_wse = mean,
      sd_wse = sd,
      lower_ci_wse = lower_ci,
      upper_ci_wse = upper_ci
    ))
  }
  
  return(df_final)
}

plot_graph <- function(df, num_test) {
  # Extract the unique non-NA date
  plot_date <- unique(na.omit(df$Date))
  title_date <- paste("Chilcotin River - Water Surface Elevation with Anomaly Detection -", plot_date)
  annotation <- paste(
  #  "Threshold: ", THRESHOLD,
    "Confidence: ", CONFIDENCE * 100
  #  "\nRolling mean: ", ROLLING_MEAN,
  #  "\nRound: ", ROUND,
  #  "\nSamples: ", num_test
  )
  
  ggplot(df, aes(x = lon, y = wse_filtered, color = anomaly)) +
    geom_point( # Plot wse_filtered points
      aes(y = wse_filtered, color = anomaly),
      size = 4
    ) +
    geom_line( # Plot a line for wse_filtered
      aes(y = wse_filtered, group = Date),
      alpha = 0.5
    ) +
    geom_line( # Plot a line for mean_wse
      aes(y = mean_wse),
      color = "black",
      linetype = "dashed",
      size = 0.5
    ) + 
    geom_line( # Plot a line for lower_ci_wse
      aes(y = lower_ci_wse),
      color = "darkgray",
      linetype = "dotted",
      size = 0.5
    ) + 
    geom_line( # Plot a line for upper_ci_wse
      aes(y = upper_ci_wse),
      color = "darkgray",
      linetype = "dotted",
      size = 0.5
    ) + 
    #geom_text( # Add a label to the mean_wse line
    #  data = df %>% filter(lon == min(lon)),  # Position at the beginning of the line
    #  aes(y = mean_wse, label = "Mean WSE"),
    #  color = "black",
    #  size = 3,
    #  hjust = -0.5,
    #  vjust = 9
    #) +
    #geom_text( # Add anomaly labels
    #  data = df %>% filter(anomaly == TRUE),
    #  aes(y = wse_filtered, label = paste("(", lat, ", ", lon, ")", sep = "")),
    #  size = 2,
    #  hjust = 1.25,
    #  color = "red"
    #) +
    geom_vline( # Add the vertical dashed black line
      xintercept = X_LANDSLIDE,
      color = "black",
      linetype = "dashed",
      size = 0.8
    ) +
    annotate( #Add a "Landslide" label near the vertical line
      "text",
      x = X_LANDSLIDE,
      y = 520,  # Position near the top
      label = "Landslide",
      color = "black",
      size = 4,
      angle = 90,
      vjust = -0.5,
      hjust = 1
    ) +
    scale_color_manual(
      values = c("blue", "red")
    ) +
    labs(
    #  title = title_date,
      x = "Longitude",
      y = "Water Surface Elevation (m)",
      color = "Anomaly"
    ) +
    #annotate( # Add custom annotation
    #  "text",
    #  x = -122.85,
    #  y = 515,
    #  label = annotation,
    #  color = "black",
    #  size = 4,
    #  fontface = "italic",
    #  hjust = 0
    #) +
    theme_minimal()+
    theme(
      legend.position = c(0.95, 0.95),  # normalized coordinates (x, y)
      legend.justification = c("right", "top"),
      legend.background = element_rect(fill = "white", color = "gray80"),
      legend.box.background = element_rect(color = "gray80"),
      legend.text = element_text(size = 14),      # <-- Bigger legend labels
      legend.title = element_text(size = 16),     # <-- Bigger legend title
      legend.key.size = unit(1.5, "lines")         # <-- Bigger color boxes
    )
}