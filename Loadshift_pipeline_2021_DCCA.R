
#############################################--------------------------------------------------------------#############################################
### 1] SETUP 
# Remove unnecessary files from the environment
rm(list = ls())  

# Install necessary packages
install.packages('nmecr')
install.packages("devtools")
devtools::install_github("kW-Labs/nmecr")

# Set the relevant directories
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
data_directory <- "/Users/samwise/Desktop/Loadshift/" # Keep the forward slash at the end, insert data directory path here/
results_directory <- "/Users/samwise/Desktop/Loadshift/results/" # Keep the forward slash at the end, insert the results directory path here/

# Install the following packages if not already installed
require(nmecr)
require(xts)
require(data.table)
require(timetk)
require(timeDate)
require(rlist)
require(dplyr)
require(tidyverse)
# Load up functions


source("complete_timeseries.R")  # Convert all data to hourly
source("find_DR_prediction_days_loadshift.R")  # Make sure to load the DR prediction days loadshift find_DR_prediction_days_loadshift.R
source("federal_holidays.R")
source("determine_temp_variability.R")
source("clean_eload_data.R")
source("calculate_day_matching_adjusted_baseline.R")
source("calculate_weather_matching_adjusted_baseline.R")
source("calculate_TOWT_adjusted_baseline.R")
source("calculate_unadjusted_metrics.R")
source("helper_functions.R")

#############################################--------------------------------------------------------------#############################################
### 2] READ (Read in and clean data)
# Load files

ls_files <- list.files(paste0(data_directory, "data1/")) # set the appropriate data directory
ls_files <- ls_files[1:240] # edit based on number of files
ls_data <- list()

for (i in seq_along(ls_files)) {
  ls_data[[i]] <- read_csv(paste0(data_directory, 'data1/',ls_files[[i]])) # set te appropriate data directory
}

# Format files
ls_names <- substr(ls_files, 1, nchar(ls_files) - 4)
names(ls_data) <- ls_names

ls_pre_data <- ls_data[grep("12_T_", names(ls_data))]
ls_post_data <- ls_data[grep("12_P_", names(ls_data))] 

data_colnames <- c("time", "eload", "temp") 

ls_pre_data <- lapply(ls_pre_data, setNames, data_colnames)
ls_post_data <- lapply(ls_post_data, setNames, data_colnames)

ls_data <- purrr::map2(ls_pre_data, ls_post_data, bind_rows)

# Format timestamp and temperature
lubridate_timestamp <- function(data) {
  if(is.character(data$time)) {
    data$time <- lubridate::mdy_hm(data$time)
  }
  
  return(data)
}

ls_data <- purrr::map(.x = ls_data, .f = lubridate_timestamp)

clean_temp_data <- function(data) {
  data <- data %>%
    filter(temp > -30 & temp < 150)
  return(data)
}

ls_data <- purrr::map(.x = ls_data, .f = clean_temp_data)

# Complete all datasets
ls_completed_timeseries <- purrr::map(.x = ls_data, .f = complete_timeseries)


#############################################--------------------------------------------------------------#############################################
#### 3] MATCHING (Data preprocessing)

# Extract last 365 days from the datasets
ls_completed_timeseries_last_365 <- purrr::map(.x = ls_completed_timeseries, .f = last, n = "365 days")

# Find prediction days (Using last 365 days only)
ls_DR_days <- purrr::map(.x = ls_completed_timeseries_last_365, .f = find_DR_prediction_days_loadshift, event_hours = "T00:00/T23:59")## LOADSHIFT, FIND ENTIRE POST

#### TOWT 
# remove days with more than 2 NA eload values this will ensure that the baseline is robust for each prediction day
ls_cleaned_eload <- purrr::map(.x = ls_completed_timeseries, .f = clean_eload_data, event_hours = "T00:00/T23:00")## LOADSHIFT

# Convert all datasets back to tibbles (for TOWT)
ls_completed_tibble <- purrr::map(.x = ls_cleaned_eload, .f = tk_tbl, preserve_index = TRUE, rename_index = "time")

# ----
safe_calculate_day_matching_adjusted_baseline <- safely(calculate_day_matching_adjusted_baseline_ls, otherwise = NA_real_)
safe_calculate_weather_matching_adjusted_baseline <- safely(calculate_weather_matching_adjusted_baseline, otherwise = NA_real_)
safe_calculate_TOWT_adjusted_baseline <- safely(calculate_TOWT_adjusted_baseline, otherwise = NA_real_)

#############################################--------------------------------------------------------------#############################################
###  4] RUN MODELS
# ls ----
ls_day_matched_baseline_pre <- purrr::map2(.x = ls_DR_days, .y = ls_completed_timeseries, .f = safe_calculate_day_matching_adjusted_baseline, pre_adjustment_only = FALSE,
                                           initial_timslice = "T00:00/T23:59", event_hours = "T00:00/T23:59",
                                           pre_adjustment_hours = "T07:00/T08:00", post_adjustment_hours = "T21:00/T22:00")
ls_day_matched_errors_pre <- lapply(ls_day_matched_baseline_pre, "[[", 2)
ls_day_matched_results_pre <- lapply(ls_day_matched_baseline_pre, "[[", 1)

ls_weather_matched_baseline_pre <- purrr::map2(.x = ls_DR_days, .y = ls_completed_timeseries, .f = safe_calculate_weather_matching_adjusted_baseline, pre_adjustment_only = FALSE,
                                               initial_timslice = "T00:00/T23:59", event_hours = "T00:00/T23:59",
                                               pre_adjustment_hours = "T07:00/T08:00", post_adjustment_hours = "T21:00/T22:00")
ls_weather_matched_errors_pre <- lapply(ls_weather_matched_baseline_pre, "[[", 2)
ls_weather_matched_results_pre <- lapply(ls_weather_matched_baseline_pre, "[[", 1)

ls_TOWT_baseline_pre <- purrr::map2(.x = ls_DR_days, .y = ls_completed_tibble, .f = safe_calculate_TOWT_adjusted_baseline, baseline_days_count = 7, timescale_days = NULL, 
                                    pre_adjustment_only = FALSE, initial_timslice = "T00:00/T23:59", event_hours = "T00:00/T23:59",
                                    pre_adjustment_hours = "T07:00/T08:00", post_adjustment_hours = "T21:00/T22:00")
ls_TOWT_baseline_errors_pre <- lapply(ls_TOWT_baseline_pre, "[[", 2)
ls_TOWT_baseline_results_pre <- lapply(ls_TOWT_baseline_pre, "[[", 1)

ls_TOWT_baseline_weighted_70.10 <- purrr::map2(.x = ls_DR_days, .y = ls_completed_tibble, .f = safe_calculate_TOWT_adjusted_baseline, baseline_days_count = 70, timescale_days = 10,
                                               initial_timslice = "T00:00/T23:59", event_hours = "T00:00/T23:59",
                                               pre_adjustment_hours = "T07:00/T08:00", post_adjustment_hours = "T21:00/T22:00")
ls_TOWT_baseline_errors_weighted_70.10 <- lapply(ls_TOWT_baseline_weighted_70.10, "[[", 2)
ls_TOWT_baseline_results_weighted_70.10 <- lapply(ls_TOWT_baseline_weighted_70.10, "[[", 1)

ls_TOWT_baseline_weighted_70.14 <- purrr::map2(.x = ls_DR_days, .y = ls_completed_tibble, .f = safe_calculate_TOWT_adjusted_baseline, baseline_days_count = 70, timescale_days = 14,
                                               initial_timslice = "T00:00/T23:59", event_hours = "T00:00/T23:59",
                                               pre_adjustment_hours = "T07:00/T08:00", post_adjustment_hours = "T21:00/T22:00")
ls_TOWT_baseline_errors_weighted_70.14 <- lapply(ls_TOWT_baseline_weighted_70.14, "[[", 2)
ls_TOWT_baseline_results_weighted_70.14 <- lapply(ls_TOWT_baseline_weighted_70.14, "[[", 1)

ls_common_prediction_events <- purrr::pmap(.l = list(ls_day_matched_results_pre, ls_weather_matched_results_pre, ls_TOWT_baseline_results_pre,
                                                     ls_TOWT_baseline_results_weighted_70.10, ls_TOWT_baseline_results_weighted_70.14),
                                           .f = find_common_elements)

ls_day_matched_results_pre <- purrr::map2(.x = ls_day_matched_results_pre, .y = ls_common_prediction_events, .f = subset_list)
ls_weather_matched_results_pre <- purrr::map2(.x = ls_weather_matched_results_pre, .y = ls_common_prediction_events, .f = subset_list)
ls_TOWT_baseline_results_pre <- purrr::map2(.x = ls_TOWT_baseline_results_pre, .y = ls_common_prediction_events, .f = subset_list)
ls_TOWT_baseline_results_weighted_70.10 <-  purrr::map2(.x = ls_TOWT_baseline_results_weighted_70.10, .y = ls_common_prediction_events, .f = subset_list)
ls_TOWT_baseline_results_weighted_70.14 <-  purrr::map2(.x = ls_TOWT_baseline_results_weighted_70.14, .y = ls_common_prediction_events, .f = subset_list)

#############################################--------------------------------------------------------------#############################################
#### 5]  METRICS (Postprocessing)
# LS

ls_day_matched_results_pre <- rlist::list.clean(ls_day_matched_results_pre, function(x) length(x) == 0L | anyNA(x)) # cleaning list of NAs

ls_day_matched_results_pre_metrics_unadjusted <- purrr::map(.x = ls_day_matched_results_pre, .f = calculate_unadjusted_metrics)
ls_day_matched_results_pre_unadjusted_df <- do.call(rbind.data.frame, ls_day_matched_results_pre_metrics_unadjusted)
ls_day_matched_results_pre_unadjusted_df <- ls_day_matched_results_pre_unadjusted_df %>%
  mutate("meterID" = rownames(ls_day_matched_results_pre_unadjusted_df)) %>%
  select(meterID, everything()) %>%
  mutate("location" = "ls")  %>%
  select(location, everything()) %>%
  mutate("adjustments" = NA) %>%
  mutate("adjustments_applied" = "no") %>%
  mutate("Algorithm" = "Day Matching Unadjusted")

ls_weather_matched_results_pre <- rlist::list.clean(ls_weather_matched_results_pre, function(x) length(x) == 0L | anyNA(x)) # cleaning list of NAs

ls_weather_matched_results_pre_metrics_unadjusted <- purrr::map(.x = ls_weather_matched_results_pre, .f = calculate_unadjusted_metrics)
ls_weather_matched_results_pre_unadjusted_df <- do.call(rbind.data.frame, ls_weather_matched_results_pre_metrics_unadjusted)
ls_weather_matched_results_pre_unadjusted_df <- ls_weather_matched_results_pre_unadjusted_df %>%
  mutate("meterID" = rownames(ls_weather_matched_results_pre_unadjusted_df)) %>%
  select(meterID, everything()) %>%
  mutate("location" = "ls")  %>%
  select(location, everything()) %>%
  mutate("adjustments" = NA) %>%
  mutate("adjustments_applied" = "no") %>%
  mutate("Algorithm" = "Weather Matching Unadjusted")


ls_TOWT_baseline_results_pre <- rlist::list.clean(ls_TOWT_baseline_results_pre, function(x) length(x) == 0L | anyNA(x)) # cleaning list of NAs

ls_TOWT_baseline_results_pre_metrics_unadjusted <- purrr::map(.x = ls_TOWT_baseline_results_pre, .f = calculate_unadjusted_metrics)
ls_TOWT_baseline_results_pre_metrics_unadjusted_df <- do.call(rbind.data.frame, ls_TOWT_baseline_results_pre_metrics_unadjusted)
ls_TOWT_baseline_results_pre_metrics_unadjusted_df <- ls_TOWT_baseline_results_pre_metrics_unadjusted_df %>%
  mutate("meterID" = rownames(ls_TOWT_baseline_results_pre_metrics_unadjusted_df)) %>%
  select(meterID, everything()) %>%
  mutate("location" = "ls")  %>%
  select(location, everything()) %>%
  mutate("adjustments" = NA) %>%
  mutate("adjustments_applied" = "no") %>%
  mutate("Algorithm" = "Unweighted_TOWT_7 Days Unadjusted")


ls_TOWT_baseline_results_weighted_70.10 <- rlist::list.clean(ls_TOWT_baseline_results_weighted_70.10, function(x) length(x) == 0L | anyNA(x)) # cleaning list of NAs

ls_TOWT_baseline_results_weighted_70.10_metrics <- purrr::map(.x = ls_TOWT_baseline_results_weighted_70.10, .f = calculate_unadjusted_metrics)
ls_TOWT_baseline_results_weighted_70.10_metrics_df <- do.call(rbind.data.frame, ls_TOWT_baseline_results_weighted_70.10_metrics)
ls_TOWT_baseline_results_weighted_70.10_metrics_df <- ls_TOWT_baseline_results_weighted_70.10_metrics_df %>%
  mutate("meterID" = rownames(ls_TOWT_baseline_results_weighted_70.10_metrics_df)) %>%
  select(meterID, everything()) %>%
  mutate("location" = "ls")  %>%
  select(location, everything()) %>%
  mutate("adjustments" = NA) %>%
  mutate("adjustments_applied" = "no") %>%
  mutate("Algorithm" = "10_Day_Weighted_TOWT_70_Days Unadjusted")


ls_TOWT_baseline_results_weighted_70.14 <- rlist::list.clean(ls_TOWT_baseline_results_weighted_70.14, function(x) length(x) == 0L | anyNA(x)) # cleaning list of NAs

ls_TOWT_baseline_results_weighted_70.14_metrics <- purrr::map(.x = ls_TOWT_baseline_results_weighted_70.14, .f = calculate_unadjusted_metrics)
ls_TOWT_baseline_results_weighted_70.14_metrics_df <- do.call(rbind.data.frame, ls_TOWT_baseline_results_weighted_70.14_metrics)
ls_TOWT_baseline_results_weighted_70.14_metrics_df <- ls_TOWT_baseline_results_weighted_70.14_metrics_df %>%
  mutate("meterID" = rownames(ls_TOWT_baseline_results_weighted_70.14_metrics_df)) %>%
  select(meterID, everything()) %>%
  mutate("location" = "ls")  %>%
  select(location, everything()) %>%
  mutate("adjustments" = NA) %>%
  mutate("adjustments_applied" = "no") %>%
  mutate("Algorithm" = "14_Day_Weighted_TOWT_70_Days Unadjusted")

ls_all_metrics <- bind_rows(ls_day_matched_results_pre_unadjusted_df, ls_day_matched_results_pre_adjusted_df, ls_weather_matched_results_pre_unadjusted_df,
                            ls_weather_matched_results_pre_adjusted_df, ls_TOWT_baseline_results_pre_metrics_unadjusted_df, ls_TOWT_baseline_results_pre_metrics_adjusted_df,
                            ls_TOWT_baseline_results_weighted_70.10_metrics_df, ls_TOWT_baseline_results_weighted_70.14_metrics_df)


ls_all_metrics<-bind_rows(ls_TOWT_baseline_results_pre_metrics_unadjusted_df) # When working with 1 model at a time
write.xlsx(ls_TOWT_baseline_results_pre_metrics_unadjusted_df, paste0(results_directory, "testing_TOWT1.xlsx"))


#############################################--------------------------------------------------------------#############################################
####  6] WRITE METRICS


all_metrics <- bind_rows(DC_all_metrics, ls_all_metrics, seattle_all_metrics, vermont_all_metrics)
write.xlsx(all_metrics, paste0(results_directory, "All Metrics_10-6.xlsx"))
write.xlsx(vermont_all_metrics, paste0(results_directory, "Vermont_metrics.xlsx"))  # Vermont data results




#############################################--------------------------------------------------------------#############################################
####  7] PLOTTING PREPARATION





# rearrange columns data <- data[c(1,3,2)]
ls_all_metrics<-ls_day_matched_results_pre  # pass to the ls_all_metrics dataframe the results
ls_all_metrics$location<-NULL
ls_all_metrics$`CV(RMSE)`<-NULL
ls_all_metrics$adjustment_ratio<-NULL
ls_all_metrics$adjustments_applied<-NULL
ls_all_metrics$adjustments<-NULL
ls_all_metrics$APE<-NULL
ls_all_metrics<-ls_all_metrics[,c(1,2,4,3)]


write.xlsx(ls_all_metrics, paste0(results_directory, "WMU_120_final.xlsx"))



#############################################--------------------------------------------------------------#############################################
###

### 8] Saving and Loading entire RData
save.image(file = "my_work_space.RData")
load("my_work_space.RData")


# For post processing see the python code to take the mean by horu of weekend and weekday.

