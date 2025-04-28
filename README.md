# Chilcotin River Water Surface Elevation (WSE) Anomaly Detection

## Overview

This project analyzes **Water Surface Elevation (WSE)** data along the **Chilcotin River** to detect anomalies potentially related to landslide events.  
It processes **SWOT Level 2 River Single-Pass Vector Data Product (Version C Node)** datasets from [Earthdata NASA](https://earthdata.nasa.gov/), computes confidence intervals, identifies anomalies, and visualizes the results.

The workflow includes:
- Filtering and smoothing river node data.
- Calculating confidence intervals (CIs) for river WSE.
- Detecting anomalous WSE values outside expected CIs.
- Visualizing anomalies relative to known landslide locations.

---

## Files

### `main.R`
Main script that:
- Sources `functions.R`.
- Loads historical and test date WSE `.csv` data.
- Prepares datasets and applies confidence interval (CI) calculations.
- Identifies and labels anomalies.
- Prints processed data.
- Visualizes the WSE profile and anomalies across longitude.

### `functions.R`
Contains helper functions:
- `load_data(file, date_label)`:  
  Loads, filters, rounds coordinates, labels, and applies a rolling median filter to despike WSE data.
  
- `compute_ci(df_base, df_test, confidence)`:  
  Computes mean WSE, standard deviation, and confidence intervals (upper and lower bounds) for locations with sufficient historical data points.

- `plot_graph(df, num_test)`:  
  Creates a visual plot showing WSE points, confidence interval bounds, and highlights detected anomalies. Marks the approximate location of a known landslide event.

---

## Data Source

All input `.csv` files used in this project are sourced from:  
**Earthdata NASA - SWOT Level 2 River Single-Pass Vector Data Product (Version C Node)**.  
More information can be found [here](https://earthdata.nasa.gov/).

The analysis specifically focuses on the **Chilcotin River**, British Columbia, Canada.

---

## How It Works

1. **Data Loading**
   - Loads multiple `.csv` files for historical dates.
   - Loads a `.csv` file for the test date.
   - Filters nodes based on latitudes between `51.7` and `52`, longitudes between `-122.85` and `-122.7`, and river name == "Chilcotin River".
   - Rounds latitude and longitude to 3 decimal places.

2. **Data Preprocessing**
   - Applies a rolling median filter (window size = 5) to WSE to reduce noise (de-spiking).

3. **Confidence Interval Computation**
   - Only keeps nodes with at least 5 historical measurements.
   - Calculates 90% confidence intervals for each `(lat, lon)` point.

4. **Anomaly Detection**
   - Compares the test data against the computed historical CIs.
   - Flags points where the test WSE falls outside the confidence intervals.

5. **Visualization**
   - Scatter plot of WSE vs Longitude.
   - Points colored by anomaly status (red for anomalies).
   - Mean WSE, upper CI, and lower CI plotted for reference.
   - A vertical line marks the approximate landslide location at longitude `-122.7888`.

---

## Key Parameters

| Parameter        | Value     | Description                                        |
|------------------|-----------|----------------------------------------------------|
| `THRESHOLD`      | 5         | Minimum number of historical samples per location. |
| `CONFIDENCE`     | 0.90      | Confidence level for CI calculations (90%).        |
| `ROLLING_MEAN`   | 5         | Window size for rolling median filter.             |
| `ROUND`          | 3         | Number of decimal places for rounding coordinates. |
| `X_LANDSLIDE`    | -122.7888 | Approximate longitude of known landslide.          |

---

## Requirements

Make sure the following R packages are installed:
- `lubridate`
- `dplyr`
- `ggplot2`
- `readr`
- `zoo`

Install them with:

```r
install.packages(c("lubridate", "dplyr", "ggplot2", "readr", "zoo"))
```

---

## Usage

1. Place all relevant `.csv` data files into the working directory (`C:/Users/omare/Documents`).
2. Edit the `dates` and `ts_date` vectors in `main.R` to match your available data filenames.
3. Run `main.R` to process and visualize the anomalies.

---

## Example Output

- A printed data frame showing all river nodes with computed WSE, CI bounds, and anomaly flags.
- A plot displaying WSE points across longitude, highlighting detected anomalies and the location of the landslide.

---

