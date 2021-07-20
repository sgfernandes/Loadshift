
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

# Load up functions
source("complete_timeseries.R")  # Convert all data to hourly
source("find_DR_prediction_days.R")  
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
vermont_files <- list.files(path = paste0(data_directory, 'vermont/'))
vermont_files <- vermont_files[2:4] # removing the 'Icon_' file from environment

vermont_data <- list()

for (i in seq_along(vermont_files)) {
  vermont_data[[i]] <- read_csv(paste0(data_directory, 'vermont/',vermont_files[[i]]), skip = 2)
}

ls_files <- list.files(paste0(data_directory, "data1/")) # set the appropriate data directory
ls_files <- ls_files[1:240] # edit based on number of files
ls_data <- list()

for (i in seq_along(ls_files)) {
  ls_data[[i]] <- read_csv(paste0(data_directory, 'data1/',ls_files[[i]])) # set te appropriate data directory
}


# Format files

vermont_names <- substr(vermont_files, 1, nchar(vermont_files) - 4)
names(vermont_data) <- vermont_names

ls_names <- substr(ls_files, 1, nchar(ls_files) - 4)
names(ls_data) <- ls_names

ls_pre_data <- ls_data[grep("12_T_", names(ls_data))]
ls_post_data <- ls_data[grep("12_P_", names(ls_data))] 

data_colnames <- c("time", "eload", "temp") 
vermont_data <- lapply(vermont_data, setNames, data_colnames)
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

vermont_data <- purrr::map(.x = vermont_data, .f = lubridate_timestamp)
ls_data <- purrr::map(.x = ls_data, .f = lubridate_timestamp)

clean_temp_data <- function(data) {
  data <- data %>%
    filter(temp > -30 & temp < 150)
  return(data)
}

vermont_data <- purrr::map(.x = vermont_data, .f = clean_temp_data)
ls_data <- purrr::map(.x = ls_data, .f = clean_temp_data)


# Complete all datasets
ls_completed_timeseries <- purrr::map(.x = ls_data, .f = complete_timeseries)
vermont_completed_timeseries <- purrr::map(.x = vermont_data, .f = complete_timeseries)

#############################################--------------------------------------------------------------#############################################
#### 3] MATCHING (Data preprocessing)

# Extract last 365 days from the datasets
ls_completed_timeseries_last_365 <- purrr::map(.x = ls_completed_timeseries, .f = last, n = "365 days")
vermont_completed_timeseries_last_365 <- purrr::map(.x = vermont_completed_timeseries, .f = last, n = "365 days")


# Find prediction days (Using last 365 days only)
ls_DR_days <- purrr::map(.x = ls_completed_timeseries_last_365, .f = find_DR_prediction_days, event_hours = "T00:00/T23:59")
vermont_DR_days <- purrr::map(.x = vermont_completed_timeseries_last_365, .f = find_DR_prediction_days, event_hours = "T00:00/T23:59")  ## LOADSHIFT, FIND ENTIRE POST


#### TOWT 
# remove days with more than 2 NA eload values this will ensure that the baseline is robust for each prediction day

ls_cleaned_eload <- purrr::map(.x = ls_completed_timeseries, .f = clean_eload_data, event_hours = "T00:00/T23:00")
vermont_cleaned_eload <- purrr::map(.x = vermont_completed_timeseries, .f = clean_eload_data, event_hours = "T00:00/T23:00") ## LOADSHIFT


# Convert all datasets back to tibbles (for TOWT)
ls_completed_tibble <- purrr::map(.x = ls_cleaned_eload, .f = tk_tbl, preserve_index = TRUE, rename_index = "time")
vermont_completed_tibble <- purrr::map(.x = vermont_cleaned_eload, .f = tk_tbl, preserve_index = TRUE, rename_index = "time")


# ----
safe_calculate_day_matching_adjusted_baseline <- safely(calculate_day_matching_adjusted_baseline, otherwise = NA_real_)
safe_calculate_weather_matching_adjusted_baseline <- safely(calculate_weather_matching_adjusted_baseline, otherwise = NA_real_)
safe_calculate_TOWT_adjusted_baseline <- safely(calculate_TOWT_adjusted_baseline, otherwise = NA_real_)

#############################################--------------------------------------------------------------#############################################
###  4] RUN MODELS
# ls ----
ls_day_matched_baseline_pre <- purrr::map2(.x = ls_DR_days, .y = ls_completed_timeseries, .f = safe_calculate_day_matching_adjusted_baseline, pre_adjustment_only = TRUE,
                                           initial_timslice = "T00:00/T23:59", event_hours = "T00:00/T23:59",
                                           pre_adjustment_hours = "T07:00/T08:00", post_adjustment_hours = "T21:00/T22:00")
ls_day_matched_errors_pre <- lapply(ls_day_matched_baseline_pre, "[[", 2)
ls_day_matched_results_pre <- lapply(ls_day_matched_baseline_pre, "[[", 1)

ls_weather_matched_baseline_pre <- purrr::map2(.x = ls_DR_days, .y = ls_completed_timeseries, .f = safe_calculate_weather_matching_adjusted_baseline, pre_adjustment_only = TRUE,
                                               initial_timslice = "T00:00/T23:59", event_hours = "T00:00/T23:59",
                                               pre_adjustment_hours = "T07:00/T08:00", post_adjustment_hours = "T21:00/T22:00")
ls_weather_matched_errors_pre <- lapply(ls_weather_matched_baseline_pre, "[[", 2)
ls_weather_matched_results_pre <- lapply(ls_weather_matched_baseline_pre, "[[", 1)

ls_TOWT_baseline_pre <- purrr::map2(.x = ls_DR_days, .y = ls_completed_tibble, .f = safe_calculate_TOWT_adjusted_baseline, baseline_days_count = 7, timescale_days = NULL, 
                                    pre_adjustment_only = TRUE, initial_timslice = "T00:00/T23:59", event_hours = "T00:00/T23:59",
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

# vermont ----

vermont_day_matched_baseline_pre <- purrr::map2(.x = vermont_DR_days, .y = vermont_completed_timeseries, .f = safe_calculate_day_matching_adjusted_baseline, pre_adjustment_only = FALSE,
                                                initial_timslice = "T00:00/T23:59", event_hours = "T00:00/T23:59",
                                                pre_adjustment_hours = "T07:00/T08:00", post_adjustment_hours = "T21:00/T22:00")
vermont_day_matched_errors_pre <- lapply(vermont_day_matched_baseline_pre, "[[", 2)
vermont_day_matched_results_pre <- lapply(vermont_day_matched_baseline_pre, "[[", 1)

vermont_weather_matched_baseline_pre <- purrr::map2(.x = vermont_DR_days, .y = vermont_completed_timeseries, .f = safe_calculate_weather_matching_adjusted_baseline, pre_adjustment_only = FALSE,
                                                    initial_timslice = "T00:00/T23:59", event_hours = "T00:00/T23:59",
                                                    pre_adjustment_hours = "T07:00/T08:00", post_adjustment_hours = "T21:00/T22:00")
vermont_weather_matched_errors_pre <- lapply(vermont_weather_matched_baseline_pre, "[[", 2)
vermont_weather_matched_results_pre <- lapply(vermont_weather_matched_baseline_pre, "[[", 1)

vermont_TOWT_baseline_pre <- purrr::map2(.x = vermont_DR_days, .y = vermont_completed_tibble, .f = safe_calculate_TOWT_adjusted_baseline, baseline_days_count = 7, timescale_days = NULL, 
                                         pre_adjustment_only = FALSE, initial_timslice = "T00:00/T23:59", event_hours = "T00:00/T23:59",
                                         pre_adjustment_hours = "T07:00/T08:00", post_adjustment_hours = "T21:00/T22:00")
vermont_TOWT_baseline_errors_pre <- lapply(vermont_TOWT_baseline_pre, "[[", 2)
vermont_TOWT_baseline_results_pre <- lapply(vermont_TOWT_baseline_pre, "[[", 1)

vermont_TOWT_baseline_weighted_70.10 <- purrr::map2(.x = vermont_DR_days, .y = vermont_completed_tibble, .f = safe_calculate_TOWT_adjusted_baseline, baseline_days_count = 70, timescale_days = 10,
                                                    initial_timslice = "T00:00/T23:59", event_hours = "T00:00/T23:59",
                                                    pre_adjustment_hours = "T07:00/T08:00", post_adjustment_hours = "T21:00/T22:00")
vermont_TOWT_baseline_errors_weighted_70.10 <- lapply(vermont_TOWT_baseline_weighted_70.10, "[[", 2)
vermont_TOWT_baseline_results_weighted_70.10 <- lapply(vermont_TOWT_baseline_weighted_70.10, "[[", 1)

vermont_TOWT_baseline_weighted_70.14 <- purrr::map2(.x = vermont_DR_days, .y = vermont_completed_tibble, .f = safe_calculate_TOWT_adjusted_baseline, baseline_days_count = 70, timescale_days = 14,
                                                    initial_timslice = "T00:00/T23:59", event_hours = "T00:00/T23:59",
                                                    pre_adjustment_hours = "T07:00/T08:00", post_adjustment_hours = "T21:00/T22:00")
vermont_TOWT_baseline_errors_weighted_70.14 <- lapply(vermont_TOWT_baseline_weighted_70.14, "[[", 2)
vermont_TOWT_baseline_results_weighted_70.14 <- lapply(vermont_TOWT_baseline_weighted_70.14, "[[", 1)

vermont_common_prediction_events <- purrr::pmap(.l = list(vermont_day_matched_results_pre, vermont_weather_matched_results_pre, vermont_TOWT_baseline_results_pre,
                                                          vermont_TOWT_baseline_results_weighted_70.10, vermont_TOWT_baseline_results_weighted_70.14),
                                                .f = find_common_elements)

vermont_day_matched_results_pre <- purrr::map2(.x = vermont_day_matched_results_pre, .y = vermont_common_prediction_events, .f = subset_list)
vermont_weather_matched_results_pre <- purrr::map2(.x = vermont_weather_matched_results_pre, .y = vermont_common_prediction_events, .f = subset_list)
vermont_TOWT_baseline_results_pre <- purrr::map2(.x = vermont_TOWT_baseline_results_pre, .y = vermont_common_prediction_events, .f = subset_list)
vermont_TOWT_baseline_results_weighted_70.10 <-  purrr::map2(.x = vermont_TOWT_baseline_results_weighted_70.10, .y = vermont_common_prediction_events, .f = subset_list)
vermont_TOWT_baseline_results_weighted_70.14 <-  purrr::map2(.x = vermont_TOWT_baseline_results_weighted_70.14, .y = vermont_common_prediction_events, .f = subset_list)


#############################################--------------------------------------------------------------#############################################
#### 5]  METRICS (Postprocessing)


# vermont

vermont_day_matched_results_pre <- rlist::list.clean(vermont_day_matched_results_pre, function(x) length(x) == 0L | anyNA(x)) # cleaning list of NAs

vermont_day_matched_results_pre_metrics_unadjusted <- purrr::map(.x = vermont_day_matched_results_pre, .f = calculate_unadjusted_metrics)
vermont_day_matched_results_pre_unadjusted_df <- do.call(rbind.data.frame, vermont_day_matched_results_pre_metrics_unadjusted)
vermont_day_matched_results_pre_unadjusted_df <- vermont_day_matched_results_pre_unadjusted_df %>%
  mutate("meterID" = rownames(vermont_day_matched_results_pre_unadjusted_df)) %>%
  select(meterID, everything()) %>%
  mutate("location" = "vermont")  %>%
  select(location, everything()) %>%
  mutate("adjustments" = NA) %>%
  mutate("adjustments_applied" = "no") %>%
  mutate("Algorithm" = "Day Matching Unadjusted")

vermont_weather_matched_results_pre <- rlist::list.clean(vermont_weather_matched_results_pre, function(x) length(x) == 0L | anyNA(x)) # cleaning list of NAs

vermont_weather_matched_results_pre_metrics_unadjusted <- purrr::map(.x = vermont_weather_matched_results_pre, .f = calculate_unadjusted_metrics)
vermont_weather_matched_results_pre_unadjusted_df <- do.call(rbind.data.frame, vermont_weather_matched_results_pre_metrics_unadjusted)
vermont_weather_matched_results_pre_unadjusted_df <- vermont_weather_matched_results_pre_unadjusted_df %>%
  mutate("meterID" = rownames(vermont_weather_matched_results_pre_unadjusted_df)) %>%
  select(meterID, everything()) %>%
  mutate("location" = "vermont")  %>%
  select(location, everything()) %>%
  mutate("adjustments" = NA) %>%
  mutate("adjustments_applied" = "no") %>%
  mutate("Algorithm" = "Weather Matching Unadjusted")



vermont_TOWT_baseline_results_pre <- rlist::list.clean(vermont_TOWT_baseline_results_pre, function(x) length(x) == 0L | anyNA(x)) # cleaning list of NAs

vermont_TOWT_baseline_results_pre_metrics_unadjusted <- purrr::map(.x = vermont_TOWT_baseline_results_pre, .f = calculate_unadjusted_metrics)
vermont_TOWT_baseline_results_pre_metrics_unadjusted_df <- do.call(rbind.data.frame, vermont_TOWT_baseline_results_pre_metrics_unadjusted)
vermont_TOWT_baseline_results_pre_metrics_unadjusted_df <- vermont_TOWT_baseline_results_pre_metrics_unadjusted_df %>%
  mutate("meterID" = rownames(vermont_TOWT_baseline_results_pre_metrics_unadjusted_df)) %>%
  select(meterID, everything()) %>%
  mutate("location" = "vermont")  %>%
  select(location, everything()) %>%
  mutate("adjustments" = NA) %>%
  mutate("adjustments_applied" = "no") %>%
  mutate("Algorithm" = "Unweighted_TOWT_7 Days Unadjusted")


vermont_TOWT_baseline_results_weighted_70.10 <- rlist::list.clean(vermont_TOWT_baseline_results_weighted_70.10, function(x) length(x) == 0L | anyNA(x)) # cleaning list of NAs

vermont_TOWT_baseline_results_weighted_70.10_metrics <- purrr::map(.x = vermont_TOWT_baseline_results_weighted_70.10, .f = calculate_unadjusted_metrics)
vermont_TOWT_baseline_results_weighted_70.10_metrics_df <- do.call(rbind.data.frame, vermont_TOWT_baseline_results_weighted_70.10_metrics)
vermont_TOWT_baseline_results_weighted_70.10_metrics_df <- vermont_TOWT_baseline_results_weighted_70.10_metrics_df %>%
  mutate("meterID" = rownames(vermont_TOWT_baseline_results_weighted_70.10_metrics_df)) %>%
  select(meterID, everything()) %>%
  mutate("location" = "vermont")  %>%
  select(location, everything()) %>%
  mutate("adjustments" = NA) %>%
  mutate("adjustments_applied" = "no") %>%
  mutate("Algorithm" = "10_Day_Weighted_TOWT_70_Days Unadjusted")


vermont_TOWT_baseline_results_weighted_70.14 <- rlist::list.clean(vermont_TOWT_baseline_results_weighted_70.14, function(x) length(x) == 0L | anyNA(x)) # cleaning list of NAs

vermont_TOWT_baseline_results_weighted_70.14_metrics <- purrr::map(.x = vermont_TOWT_baseline_results_weighted_70.14, .f = calculate_unadjusted_metrics)
vermont_TOWT_baseline_results_weighted_70.14_metrics_df <- do.call(rbind.data.frame, vermont_TOWT_baseline_results_weighted_70.14_metrics)
vermont_TOWT_baseline_results_weighted_70.14_metrics_df <- vermont_TOWT_baseline_results_weighted_70.14_metrics_df %>%
  mutate("meterID" = rownames(vermont_TOWT_baseline_results_weighted_70.14_metrics_df)) %>%
  select(meterID, everything()) %>%
  mutate("location" = "vermont")  %>%
  select(location, everything()) %>%
  mutate("adjustments" = NA) %>%
  mutate("adjustments_applied" = "no") %>%
  mutate("Algorithm" = "14_Day_Weighted_TOWT_70_Days Unadjusted")



vermont_all_metrics <- bind_rows(vermont_day_matched_results_pre_unadjusted_df,
                                 vermont_TOWT_baseline_results_pre_metrics_unadjusted_df,
                                 vermont_TOWT_baseline_results_weighted_70.10_metrics_df, vermont_TOWT_baseline_results_weighted_70.14_metrics_df)






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


ls_all_metrics<-bind_rows(ls_TOWT_baseline_results_weighted_70.14_metrics_df)
write.xlsx(ls_day_matched_results_pre_unadjusted_df, paste0(results_directory, "ls_day_matched_results.xlsx"))


#############################################--------------------------------------------------------------#############################################
####  6] WRITE METRICS


all_metrics <- bind_rows(DC_all_metrics, ls_all_metrics, seattle_all_metrics, vermont_all_metrics)
write.xlsx(all_metrics, paste0(results_directory, "All Metrics_10-6.xlsx"))
write.xlsx(vermont_all_metrics, paste0(results_directory, "Vermont_metrics.xlsx"))  # Vermont data results




#############################################--------------------------------------------------------------#############################################
####  7] PLOTTING PREPARATION


# Vermont dataset is only used for testing purposes
vermont_all_metrics<- ls_all_metrics
## Prep for plotting
vermont_all_metrics$location<-NULL
vermont_all_metrics$`CV(RMSE)`<-NULL
vermont_all_metrics$adjustment_ratio<-NULL
vermont_all_metrics$adjustments_applied<-NULL
vermont_all_metrics$adjustments<-NULL
vermont_all_metrics$APE<-NULL
#vermont_all_metrics$AE<-abs(vermont_all_metrics$NMBE)
vermont_all_metrics<-vermont_all_metrics[,c(1,2,4,3)]
unique(vermont_all_metrics$Algorithm)


# rearrange columns data <- data[c(1,3,2)]
ls_all_metrics<-ls_weather_matched_results_pre_metrics_unadjusted  # pass to the ls_all_metrics dataframe the results
ls_all_metrics$location<-NULL
ls_all_metrics$`CV(RMSE)`<-NULL
ls_all_metrics$adjustment_ratio<-NULL
ls_all_metrics$adjustments_applied<-NULL
ls_all_metrics$adjustments<-NULL
ls_all_metrics$APE<-NULL
ls_all_metrics<-ls_all_metrics[,c(1,2,4,3)]


#DMU
vermont_all_metrics_DMU<- vermont_all_metrics[which(vermont_all_metrics$Algorithm=='Day Matching Unadjusted'),]


#UWTOWT
vermont_all_metrics_UWTOWT<- vermont_all_metrics[which(vermont_all_metrics$Algorithm=='Unweighted_TOWT_7 Days Unadjusted'),]


#10_Day_WTOWT
vermont_all_metrics_10WTOWT<- vermont_all_metrics[which(vermont_all_metrics$Algorithm=='10_Day_Weighted_TOWT_70_Days Unadjusted'),]


#14_Day_WTOWT
vermont_all_metrics_1014WTOWT<- vermont_all_metrics[which(vermont_all_metrics$Algorithm=='14_Day_Weighted_TOWT_70_Days Unadjusted'),]


## Get MAPE
vermont_all_metrics_DMU$MAPE<- vermont_all_metrics_DMU$AE*100
vermont_all_metrics_1014WTOWT$MAPE<- vermont_all_metrics_1014WTOWT$AE*100
vermont_all_metrics_10WTOWT$MAPE<- vermont_all_metrics_10WTOWT$AE*100 
vermont_all_metrics_UWTOWT$MAPE <- vermont_all_metrics_UWTOWT$AE*100


## Write
write.xlsx(vermont_all_metrics_DMU, paste0(results_directory, "vermont_all_metrics_DMU.xlsx"))
write.xlsx(vermont_all_metrics_UWTOWT, paste0(results_directory, "vermont_all_metrics_UWTOWT.xlsx"))
write.xlsx(vermont_all_metrics_10WTOWT, paste0(results_directory, "vermont_all_metrics_10WTOWT.xlsx"))
write.xlsx(vermont_all_metrics_1014WTOWT, paste0(results_directory, "vermont_all_metrics_1014WTOWT.xlsx"))

write.xlsx(vermont_all_metrics, paste0(results_directory, "vermont_all_metrics_test.xlsx"))

write.xlsx(ls_all_metrics, paste0(results_directory, "WMU_120_final.xlsx"))



#############################################--------------------------------------------------------------#############################################
###

### 8] Saving and Loading entire RData
save.image(file = "my_work_space.RData")
load("my_work_space.RData")


# For post processing see the python code to take the mean by horu of weekend and weekday.

