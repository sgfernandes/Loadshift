# 1pm-4pm event window

# Extract last 365 days from the datasets
#china_completed_timeseries_last_365 <- purrr::map(.x = china_completed_timeseries, .f = last, n = "365 days")
DC_completed_timeseries_last_365 <- purrr::map(.x = DC_completed_timeseries, .f = last, n = "365 days")
FC_completed_timeseries_last_365 <- purrr::map(.x = FC_completed_timeseries, .f = last, n = "365 days")
seattle_completed_timeseries_last_365 <- purrr::map(.x = seattle_completed_timeseries, .f = last, n = "365 days")
vermont_completed_timeseries_last_365 <- purrr::map(.x = vermont_completed_timeseries, .f = last, n = "365 days")

# Find DR prediction days (Using last 365 days only)
#china_DR_days <- purrr::map(.x = china_completed_timeseries_last_365, .f = find_DR_prediction_new, event_hours = "T13:00/T16:00")
DC_DR_days <- purrr::map(.x = DC_completed_timeseries_last_365, .f = find_DR_prediction_new, event_hours = "T13:00/T16:00")
FC_DR_days <- purrr::map(.x = FC_completed_timeseries_last_365, .f = find_DR_prediction_new)
seattle_DR_days <- purrr::map(.x = seattle_completed_timeseries_last_365, .f = find_DR_prediction_new, event_hours = "T13:00/T16:00")
vermont_DR_days <- purrr::map(.x = vermont_completed_timeseries_last_365, .f = find_DR_prediction_new, event_hours = "T13:00/T16:00")

# For TOWT ----
# remove days with more than 2 NA eload values in the 10AM to 6PM window - this will ensure that the baseline window is robust for each prediction day
#china_cleaned_eload <- purrr::map(.x = china_completed_timeseries, .f = clean_eload_data, event_hours = "T13:00/T16:00")
DC_cleaned_eload <- purrr::map(.x = DC_completed_timeseries, .f = clean_eload_data, event_hours = "T13:00/T16:00")
FC_cleaned_eload <- purrr::map(.x = FC_completed_timeseries, .f = clean_eload_data, event_hours = "T13:00/T16:00")
seattle_cleaned_eload <- purrr::map(.x = seattle_completed_timeseries, .f = clean_eload_data, event_hours = "T13:00/T16:00")
vermont_cleaned_eload <- purrr::map(.x = vermont_completed_timeseries, .f = clean_eload_data, event_hours = "T13:00/T16:00")

# Convert all datasets back to tibbles (for TOWT)
#china_completed_tibble <- purrr::map(.x = china_cleaned_eload, .f = tk_tbl, preserve_index = TRUE, rename_index = "time")
DC_completed_tibble <- purrr::map(.x = DC_cleaned_eload, .f = tk_tbl, preserve_index = TRUE, rename_index = "time")
FC_completed_tibble <- purrr::map(.x = FC_cleaned_eload, .f = tk_tbl, preserve_index = TRUE, rename_index = "time")
seattle_completed_tibble <- purrr::map(.x = seattle_cleaned_eload, .f = tk_tbl, preserve_index = TRUE, rename_index = "time")
vermont_completed_tibble <- purrr::map(.x = vermont_cleaned_eload, .f = tk_tbl, preserve_index = TRUE, rename_index = "time")
# ----

safe_calculate_day_matching_adjusted_baseline <- safely(calculate_day_matching_adjusted_baseline, otherwise = NA_real_)
safe_calculate_weather_matching_adjusted_baseline <- safely(calculate_weather_matching_adjusted_baseline, otherwise = NA_real_)
safe_calculate_TOWT_adjusted_baseline <- safely(calculate_TOWT_adjusted_baseline, otherwise = NA_real_)


# # china ----
# china_day_matched_baseline_pre <- purrr::map2(.x = china_DR_days, .y = china_completed_timeseries, .f = safe_calculate_day_matching_adjusted_baseline, pre_adjustment_only = TRUE,
#                                               initial_timslice = "T09:00/T22:00", event_hours = "T13:00/T16:00",
#                                               pre_adjustment_hours = "T09:00/T10:00", post_adjustment_hours = "T21:00/T22:00")
# china_day_matched_errors_pre <- lapply(china_day_matched_baseline_pre, "[[", 2)
# china_day_matched_results_pre <- lapply(china_day_matched_baseline_pre, "[[", 1)
# 
# china_weather_matched_baseline_pre <- purrr::map2(.x = china_DR_days, .y = china_completed_timeseries, .f = safe_calculate_weather_matching_adjusted_baseline, pre_adjustment_only = TRUE,
#                                                   initial_timslice = "T09:00/T22:00", event_hours = "T13:00/T16:00",
#                                                   pre_adjustment_hours = "T09:00/T10:00", post_adjustment_hours = "T21:00/T22:00")
# china_weather_matched_errors_pre <- lapply(china_weather_matched_baseline_pre, "[[", 2)
# china_weather_matched_results_pre <- lapply(china_weather_matched_baseline_pre, "[[", 1)
# 
# china_TOWT_baseline_pre <- purrr::map2(.x = china_DR_days, .y = china_completed_tibble, .f = safe_calculate_TOWT_adjusted_baseline, baseline_days_count = 7, timescale_days = NULL, 
#                                        pre_adjustment_only = TRUE, initial_timslice = "T09:00/T22:00", event_hours = "T13:00/T16:00",
#                                        pre_adjustment_hours = "T09:00/T10:00", post_adjustment_hours = "T21:00/T22:00")
# china_TOWT_baseline_errors_pre <- lapply(china_TOWT_baseline_pre, "[[", 2)
# china_TOWT_baseline_results_pre <- lapply(china_TOWT_baseline_pre, "[[", 1)
# 
# china_TOWT_baseline_weighted_70.10 <- purrr::map2(.x = china_DR_days, .y = china_completed_tibble, .f = safe_calculate_TOWT_adjusted_baseline, baseline_days_count = 70, timescale_days = 10,
#                                                   initial_timslice = "T09:00/T22:00", event_hours = "T13:00/T16:00",
#                                                   pre_adjustment_hours = "T09:00/T10:00", post_adjustment_hours = "T21:00/T22:00")
# china_TOWT_baseline_errors_weighted_70.10 <- lapply(china_TOWT_baseline_weighted_70.10, "[[", 2)
# china_TOWT_baseline_results_weighted_70.10 <- lapply(china_TOWT_baseline_weighted_70.10, "[[", 1)
# 
# china_TOWT_baseline_weighted_70.14 <- purrr::map2(.x = china_DR_days, .y = china_completed_tibble, .f = safe_calculate_TOWT_adjusted_baseline, baseline_days_count = 70, timescale_days = 14,
#                                                   initial_timslice = "T09:00/T22:00", event_hours = "T13:00/T16:00",
#                                                   pre_adjustment_hours = "T09:00/T10:00", post_adjustment_hours = "T21:00/T22:00")
# china_TOWT_baseline_errors_weighted_70.14 <- lapply(china_TOWT_baseline_weighted_70.14, "[[", 2)
# china_TOWT_baseline_results_weighted_70.14 <- lapply(china_TOWT_baseline_weighted_70.14, "[[", 1)
# 
# china_common_prediction_events <- purrr::pmap(.l = list(china_day_matched_results_pre, china_weather_matched_results_pre, china_TOWT_baseline_results_pre,
#                                                         china_TOWT_baseline_results_weighted_70.10, china_TOWT_baseline_results_weighted_70.14),
#                                               .f = find_common_elements)
# 
# china_day_matched_results_pre <- purrr::map2(.x = china_day_matched_results_pre, .y = china_common_prediction_events, .f = subset_list)
# china_weather_matched_results_pre <- purrr::map2(.x = china_weather_matched_results_pre, .y = china_common_prediction_events, .f = subset_list)
# china_TOWT_baseline_results_pre <- purrr::map2(.x = china_TOWT_baseline_results_pre, .y = china_common_prediction_events, .f = subset_list)
# china_TOWT_baseline_results_weighted_70.10 <-  purrr::map2(.x = china_TOWT_baseline_results_weighted_70.10, .y = china_common_prediction_events, .f = subset_list)
# china_TOWT_baseline_results_weighted_70.14 <-  purrr::map2(.x = china_TOWT_baseline_results_weighted_70.14, .y = china_common_prediction_events, .f = subset_list)
# 
# 

# DC ----
DC_day_matched_baseline_pre <- purrr::map2(.x = DC_DR_days, .y = DC_completed_timeseries, .f = safe_calculate_day_matching_adjusted_baseline, pre_adjustment_only = TRUE,
                                           initial_timslice = "T09:00/T22:00", event_hours = "T13:00/T16:00",
                                           pre_adjustment_hours = "T09:00/T10:00", post_adjustment_hours = "T21:00/T22:00")
DC_day_matched_errors_pre <- lapply(DC_day_matched_baseline_pre, "[[", 2)
DC_day_matched_results_pre <- lapply(DC_day_matched_baseline_pre, "[[", 1)

DC_weather_matched_baseline_pre <- purrr::map2(.x = DC_DR_days, .y = DC_completed_timeseries, .f = safe_calculate_weather_matching_adjusted_baseline, pre_adjustment_only = TRUE,
                                               initial_timslice = "T09:00/T22:00", event_hours = "T13:00/T16:00",
                                               pre_adjustment_hours = "T09:00/T10:00", post_adjustment_hours = "T21:00/T22:00")
DC_weather_matched_errors_pre <- lapply(DC_weather_matched_baseline_pre, "[[", 2)
DC_weather_matched_results_pre <- lapply(DC_weather_matched_baseline_pre, "[[", 1)

DC_TOWT_baseline_pre <- purrr::map2(.x = DC_DR_days, .y = DC_completed_tibble, .f = safe_calculate_TOWT_adjusted_baseline, baseline_days_count = 7, timescale_days = NULL, 
                                    pre_adjustment_only = TRUE, initial_timslice = "T09:00/T22:00", event_hours = "T13:00/T16:00",
                                    pre_adjustment_hours = "T09:00/T10:00", post_adjustment_hours = "T21:00/T22:00")
DC_TOWT_baseline_errors_pre <- lapply(DC_TOWT_baseline_pre, "[[", 2)
DC_TOWT_baseline_results_pre <- lapply(DC_TOWT_baseline_pre, "[[", 1)

DC_TOWT_baseline_weighted_70.10 <- purrr::map2(.x = DC_DR_days, .y = DC_completed_tibble, .f = safe_calculate_TOWT_adjusted_baseline, baseline_days_count = 70, timescale_days = 10,
                                               pre_adjustment_only = TRUE, initial_timslice = "T09:00/T22:00", event_hours = "T13:00/T16:00",
                                               pre_adjustment_hours = "T09:00/T10:00", post_adjustment_hours = "T21:00/T22:00")
DC_TOWT_baseline_errors_weighted_70.10 <- lapply(DC_TOWT_baseline_weighted_70.10, "[[", 2)
DC_TOWT_baseline_results_weighted_70.10 <- lapply(DC_TOWT_baseline_weighted_70.10, "[[", 1)

DC_TOWT_baseline_weighted_70.14 <- purrr::map2(.x = DC_DR_days, .y = DC_completed_tibble, .f = safe_calculate_TOWT_adjusted_baseline, baseline_days_count = 70, timescale_days = 14,
                                               pre_adjustment_only = TRUE, initial_timslice = "T09:00/T22:00", event_hours = "T13:00/T16:00",
                                               pre_adjustment_hours = "T09:00/T10:00", post_adjustment_hours = "T21:00/T22:00")
DC_TOWT_baseline_errors_weighted_70.14 <- lapply(DC_TOWT_baseline_weighted_70.14, "[[", 2)
DC_TOWT_baseline_results_weighted_70.14 <- lapply(DC_TOWT_baseline_weighted_70.14, "[[", 1)

DC_common_prediction_events <- purrr::pmap(.l = list(DC_day_matched_results_pre, DC_weather_matched_results_pre, DC_TOWT_baseline_results_pre,
                                                     DC_TOWT_baseline_results_weighted_70.10, DC_TOWT_baseline_results_weighted_70.14),
                                           .f = find_common_elements)

DC_day_matched_results_pre <- purrr::map2(.x = DC_day_matched_results_pre, .y = DC_common_prediction_events, .f = subset_list)
DC_weather_matched_results_pre <- purrr::map2(.x = DC_weather_matched_results_pre, .y = DC_common_prediction_events, .f = subset_list)
DC_TOWT_baseline_results_pre <- purrr::map2(.x = DC_TOWT_baseline_results_pre, .y = DC_common_prediction_events, .f = subset_list)
DC_TOWT_baseline_results_weighted_70.10 <-  purrr::map2(.x = DC_TOWT_baseline_results_weighted_70.10, .y = DC_common_prediction_events, .f = subset_list)
DC_TOWT_baseline_results_weighted_70.14 <-  purrr::map2(.x = DC_TOWT_baseline_results_weighted_70.14, .y = DC_common_prediction_events, .f = subset_list)

# FC ----
FC_day_matched_baseline_pre <- purrr::map2(.x = FC_DR_days, .y = FC_completed_timeseries, .f = safe_calculate_day_matching_adjusted_baseline, pre_adjustment_only = TRUE,
                                           initial_timslice = "T09:00/T22:00", event_hours = "T13:00/T16:00",
                                           pre_adjustment_hours = "T09:00/T10:00", post_adjustment_hours = "T21:00/T22:00")
FC_day_matched_errors_pre <- lapply(FC_day_matched_baseline_pre, "[[", 2)
FC_day_matched_results_pre <- lapply(FC_day_matched_baseline_pre, "[[", 1)

FC_weather_matched_baseline_pre <- purrr::map2(.x = FC_DR_days, .y = FC_completed_timeseries, .f = safe_calculate_weather_matching_adjusted_baseline, pre_adjustment_only = TRUE,
                                               initial_timslice = "T09:00/T22:00", event_hours = "T13:00/T16:00",
                                               pre_adjustment_hours = "T09:00/T10:00", post_adjustment_hours = "T21:00/T22:00")
FC_weather_matched_errors_pre <- lapply(FC_weather_matched_baseline_pre, "[[", 2)
FC_weather_matched_results_pre <- lapply(FC_weather_matched_baseline_pre, "[[", 1)

FC_TOWT_baseline_pre <- purrr::map2(.x = FC_DR_days, .y = FC_completed_tibble, .f = safe_calculate_TOWT_adjusted_baseline, baseline_days_count = 7, timescale_days = NULL, 
                                    pre_adjustment_only = TRUE, initial_timslice = "T09:00/T22:00", event_hours = "T13:00/T16:00",
                                    pre_adjustment_hours = "T09:00/T10:00", post_adjustment_hours = "T21:00/T22:00")
FC_TOWT_baseline_errors_pre <- lapply(FC_TOWT_baseline_pre, "[[", 2)
FC_TOWT_baseline_results_pre <- lapply(FC_TOWT_baseline_pre, "[[", 1)

FC_TOWT_baseline_weighted_70.10 <- purrr::map2(.x = FC_DR_days, .y = FC_completed_tibble, .f = safe_calculate_TOWT_adjusted_baseline, baseline_days_count = 70, timescale_days = 10,
                                               pre_adjustment_only = TRUE, initial_timslice = "T09:00/T22:00", event_hours = "T13:00/T16:00",
                                               pre_adjustment_hours = "T09:00/T10:00", post_adjustment_hours = "T21:00/T22:00")
FC_TOWT_baseline_errors_weighted_70.10 <- lapply(FC_TOWT_baseline_weighted_70.10, "[[", 2)
FC_TOWT_baseline_results_weighted_70.10 <- lapply(FC_TOWT_baseline_weighted_70.10, "[[", 1)

FC_TOWT_baseline_weighted_70.14 <- purrr::map2(.x = FC_DR_days, .y = FC_completed_tibble, .f = safe_calculate_TOWT_adjusted_baseline, baseline_days_count = 70, timescale_days = 14,
                                               pre_adjustment_only = TRUE, initial_timslice = "T09:00/T22:00", event_hours = "T13:00/T16:00",
                                               pre_adjustment_hours = "T09:00/T10:00", post_adjustment_hours = "T21:00/T22:00")
FC_TOWT_baseline_errors_weighted_70.14 <- lapply(FC_TOWT_baseline_weighted_70.14, "[[", 2)
FC_TOWT_baseline_results_weighted_70.14 <- lapply(FC_TOWT_baseline_weighted_70.14, "[[", 1)

FC_common_prediction_events <- purrr::pmap(.l = list(FC_day_matched_results_pre, FC_weather_matched_results_pre, FC_TOWT_baseline_results_pre,
                                                     FC_TOWT_baseline_results_weighted_70.10, FC_TOWT_baseline_results_weighted_70.14),
                                           .f = find_common_elements)

FC_day_matched_results_pre <- purrr::map2(.x = FC_day_matched_results_pre, .y = FC_common_prediction_events, .f = subset_list)
FC_weather_matched_results_pre <- purrr::map2(.x = FC_weather_matched_results_pre, .y = FC_common_prediction_events, .f = subset_list)
FC_TOWT_baseline_results_pre <- purrr::map2(.x = FC_TOWT_baseline_results_pre, .y = FC_common_prediction_events, .f = subset_list)
FC_TOWT_baseline_results_weighted_70.10 <-  purrr::map2(.x = FC_TOWT_baseline_results_weighted_70.10, .y = FC_common_prediction_events, .f = subset_list)
FC_TOWT_baseline_results_weighted_70.14 <-  purrr::map2(.x = FC_TOWT_baseline_results_weighted_70.14, .y = FC_common_prediction_events, .f = subset_list)

# seattle -----
seattle_day_matched_baseline_pre <- purrr::map2(.x = seattle_DR_days, .y = seattle_completed_timeseries, .f = safe_calculate_day_matching_adjusted_baseline, pre_adjustment_only = TRUE,
                                                initial_timslice = "T09:00/T22:00", event_hours = "T13:00/T16:00",
                                                pre_adjustment_hours = "T09:00/T10:00", post_adjustment_hours = "T21:00/T22:00")
seattle_day_matched_errors_pre <- lapply(seattle_day_matched_baseline_pre, "[[", 2)
seattle_day_matched_results_pre <- lapply(seattle_day_matched_baseline_pre, "[[", 1)

seattle_weather_matched_baseline_pre <- purrr::map2(.x = seattle_DR_days, .y = seattle_completed_timeseries, .f = safe_calculate_weather_matching_adjusted_baseline, pre_adjustment_only = TRUE,
                                                    initial_timslice = "T09:00/T22:00", event_hours = "T13:00/T16:00",
                                                    pre_adjustment_hours = "T09:00/T10:00", post_adjustment_hours = "T21:00/T22:00")
seattle_weather_matched_errors_pre <- lapply(seattle_weather_matched_baseline_pre, "[[", 2)
seattle_weather_matched_results_pre <- lapply(seattle_weather_matched_baseline_pre, "[[", 1)

seattle_TOWT_baseline_pre <- purrr::map2(.x = seattle_DR_days, .y = seattle_completed_tibble, .f = safe_calculate_TOWT_adjusted_baseline, baseline_days_count = 7, timescale_days = NULL, 
                                         pre_adjustment_only = TRUE, initial_timslice = "T09:00/T22:00", event_hours = "T13:00/T16:00",
                                         pre_adjustment_hours = "T09:00/T10:00", post_adjustment_hours = "T21:00/T22:00")
seattle_TOWT_baseline_errors_pre <- lapply(seattle_TOWT_baseline_pre, "[[", 2)
seattle_TOWT_baseline_results_pre <- lapply(seattle_TOWT_baseline_pre, "[[", 1)

seattle_TOWT_baseline_weighted_70.10 <- purrr::map2(.x = seattle_DR_days, .y = seattle_completed_tibble, .f = safe_calculate_TOWT_adjusted_baseline, baseline_days_count = 70, timescale_days = 10,
                                                    initial_timslice = "T09:00/T22:00", event_hours = "T13:00/T16:00",
                                                    pre_adjustment_hours = "T09:00/T10:00", post_adjustment_hours = "T21:00/T22:00")
seattle_TOWT_baseline_errors_weighted_70.10 <- lapply(seattle_TOWT_baseline_weighted_70.10, "[[", 2)
seattle_TOWT_baseline_results_weighted_70.10 <- lapply(seattle_TOWT_baseline_weighted_70.10, "[[", 1)

seattle_TOWT_baseline_weighted_70.14 <- purrr::map2(.x = seattle_DR_days, .y = seattle_completed_tibble, .f = safe_calculate_TOWT_adjusted_baseline, baseline_days_count = 70, timescale_days = 14,
                                                    initial_timslice = "T09:00/T22:00", event_hours = "T13:00/T16:00",
                                                    pre_adjustment_hours = "T09:00/T10:00", post_adjustment_hours = "T21:00/T22:00")
seattle_TOWT_baseline_errors_weighted_70.14 <- lapply(seattle_TOWT_baseline_weighted_70.14, "[[", 2)
seattle_TOWT_baseline_results_weighted_70.14 <- lapply(seattle_TOWT_baseline_weighted_70.14, "[[", 1)

seattle_common_prediction_events <- purrr::pmap(.l = list(seattle_day_matched_results_pre, seattle_weather_matched_results_pre, seattle_TOWT_baseline_results_pre,
                                                          seattle_TOWT_baseline_results_weighted_70.10, seattle_TOWT_baseline_results_weighted_70.14),
                                                .f = find_common_elements)

seattle_day_matched_results_pre <- purrr::map2(.x = seattle_day_matched_results_pre, .y = seattle_common_prediction_events, .f = subset_list)
seattle_weather_matched_results_pre <- purrr::map2(.x = seattle_weather_matched_results_pre, .y = seattle_common_prediction_events, .f = subset_list)
seattle_TOWT_baseline_results_pre <- purrr::map2(.x = seattle_TOWT_baseline_results_pre, .y = seattle_common_prediction_events, .f = subset_list)
seattle_TOWT_baseline_results_weighted_70.10 <-  purrr::map2(.x = seattle_TOWT_baseline_results_weighted_70.10, .y = seattle_common_prediction_events, .f = subset_list)
seattle_TOWT_baseline_results_weighted_70.14 <-  purrr::map2(.x = seattle_TOWT_baseline_results_weighted_70.14, .y = seattle_common_prediction_events, .f = subset_list)


# vermont ----

vermont_day_matched_baseline_pre <- purrr::map2(.x = vermont_DR_days, .y = vermont_completed_timeseries, .f = safe_calculate_day_matching_adjusted_baseline, pre_adjustment_only = TRUE,
                                                initial_timslice = "T09:00/T22:00", event_hours = "T13:00/T16:00",
                                                pre_adjustment_hours = "T09:00/T10:00", post_adjustment_hours = "T21:00/T22:00")
vermont_day_matched_errors_pre <- lapply(vermont_day_matched_baseline_pre, "[[", 2)
vermont_day_matched_results_pre <- lapply(vermont_day_matched_baseline_pre, "[[", 1)

vermont_weather_matched_baseline_pre <- purrr::map2(.x = vermont_DR_days, .y = vermont_completed_timeseries, .f = safe_calculate_weather_matching_adjusted_baseline, 
                                                    pre_adjustment_only = TRUE, initial_timslice = "T09:00/T22:00", event_hours = "T13:00/T16:00",
                                                    pre_adjustment_hours = "T09:00/T10:00", post_adjustment_hours = "T21:00/T22:00")
vermont_weather_matched_errors_pre <- lapply(vermont_weather_matched_baseline_pre, "[[", 2)
vermont_weather_matched_results_pre <- lapply(vermont_weather_matched_baseline_pre, "[[", 1)

vermont_TOWT_baseline_pre <- purrr::map2(.x = vermont_DR_days, .y = vermont_completed_tibble, .f = safe_calculate_TOWT_adjusted_baseline, baseline_days_count = 7, timescale_days = NULL,
                                         pre_adjustment_only = TRUE, initial_timslice = "T09:00/T22:00", event_hours = "T13:00/T16:00",
                                         pre_adjustment_hours = "T09:00/T10:00", post_adjustment_hours = "T21:00/T22:00")
vermont_TOWT_baseline_errors_pre <- lapply(vermont_TOWT_baseline_pre, "[[", 2)
vermont_TOWT_baseline_results_pre <- lapply(vermont_TOWT_baseline_pre, "[[", 1)

vermont_TOWT_baseline_weighted_70.10 <- purrr::map2(.x = vermont_DR_days, .y = vermont_completed_tibble, .f = safe_calculate_TOWT_adjusted_baseline, baseline_days_count = 70, timescale_days = 10,
                                                    pre_adjustment_only = TRUE, initial_timslice = "T09:00/T22:00", event_hours = "T13:00/T16:00",
                                                    pre_adjustment_hours = "T09:00/T10:00", post_adjustment_hours = "T21:00/T22:00")
vermont_TOWT_baseline_errors_weighted_70.10 <- lapply(vermont_TOWT_baseline_weighted_70.10, "[[", 2)
vermont_TOWT_baseline_results_weighted_70.10 <- lapply(vermont_TOWT_baseline_weighted_70.10, "[[", 1)

vermont_TOWT_baseline_weighted_70.14 <- purrr::map2(.x = vermont_DR_days, .y = vermont_completed_tibble, .f = safe_calculate_TOWT_adjusted_baseline, baseline_days_count = 70, timescale_days = 14,
                                                    pre_adjustment_only = TRUE, initial_timslice = "T09:00/T22:00", event_hours = "T13:00/T16:00",
                                                    pre_adjustment_hours = "T09:00/T10:00", post_adjustment_hours = "T21:00/T22:00")
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



# Metrics ---

# # china
# 
# china_day_matched_results_pre <- rlist::list.clean(china_day_matched_results_pre, function(x) length(x) == 0L | anyNA(x)) # cleaning list of NAs
# 
# china_day_matched_results_pre_metrics_unadjusted <- purrr::map(.x = china_day_matched_results_pre, .f = calculate_unadjusted_metrics)
# china_day_matched_results_pre_unadjusted_df <- do.call(rbind.data.frame, china_day_matched_results_pre_metrics_unadjusted)
# china_day_matched_results_pre_unadjusted_df <- china_day_matched_results_pre_unadjusted_df %>%
#   mutate("meterID" = rownames(china_day_matched_results_pre_unadjusted_df)) %>%
#   select(meterID, everything()) %>%
#   mutate("location" = "china")  %>%
#   select(location, everything()) %>%
#   mutate("adjustments" = NA) %>%
#   mutate("adjustments_applied" = "no") %>%
#   mutate("Algorithm" = "Day Matching Unadjusted")
# 
# china_day_matched_results_pre_metrics_adjusted <- purrr::map(.x = china_day_matched_results_pre, .f = calculate_adjusted_metrics)
# china_day_matched_results_pre_adjusted_df <- do.call(rbind.data.frame, china_day_matched_results_pre_metrics_adjusted)
# china_day_matched_results_pre_adjusted_df <- china_day_matched_results_pre_adjusted_df %>%
#   mutate("meterID" = rownames(china_day_matched_results_pre_adjusted_df)) %>%
#   select(meterID, everything()) %>%
#   mutate("location" = "china")  %>%
#   select(location, everything()) %>%
#   mutate("adjustments" = "pre") %>%
#   mutate("adjustments_applied" = "yes") %>%
#   mutate("Algorithm" = "Day Matching pre-adjusted")
# 
# china_weather_matched_results_pre <- rlist::list.clean(china_weather_matched_results_pre, function(x) length(x) == 0L | anyNA(x)) # cleaning list of NAs
# 
# china_weather_matched_results_pre_metrics_unadjusted <- purrr::map(.x = china_weather_matched_results_pre, .f = calculate_unadjusted_metrics)
# china_weather_matched_results_pre_unadjusted_df <- do.call(rbind.data.frame, china_weather_matched_results_pre_metrics_unadjusted)
# china_weather_matched_results_pre_unadjusted_df <- china_weather_matched_results_pre_unadjusted_df %>%
#   mutate("meterID" = rownames(china_weather_matched_results_pre_unadjusted_df)) %>%
#   select(meterID, everything()) %>%
#   mutate("location" = "china")  %>%
#   select(location, everything()) %>%
#   mutate("adjustments" = NA) %>%
#   mutate("adjustments_applied" = "no") %>%
#   mutate("Algorithm" = "Weather Matching Unadjusted")
# 
# china_weather_matched_results_pre_metrics_adjusted <- purrr::map(.x = china_weather_matched_results_pre, .f = calculate_adjusted_metrics)
# china_weather_matched_results_pre_adjusted_df <- do.call(rbind.data.frame, china_weather_matched_results_pre_metrics_adjusted)
# china_weather_matched_results_pre_adjusted_df <- china_weather_matched_results_pre_adjusted_df %>%
#   mutate("meterID" = rownames(china_weather_matched_results_pre_adjusted_df)) %>%
#   select(meterID, everything()) %>%
#   mutate("location" = "china")  %>%
#   select(location, everything()) %>%
#   mutate("adjustments" = "pre") %>%
#   mutate("adjustments_applied" = "yes") %>%
#   mutate("Algorithm" = "Weather Matching pre-adjusted")
# 
# 
# china_TOWT_baseline_results_pre <- rlist::list.clean(china_TOWT_baseline_results_pre, function(x) length(x) == 0L | anyNA(x)) # cleaning list of NAs
# 
# china_TOWT_baseline_results_pre_metrics_unadjusted <- purrr::map(.x = china_TOWT_baseline_results_pre, .f = calculate_unadjusted_metrics)
# china_TOWT_baseline_results_pre_metrics_unadjusted_df <- do.call(rbind.data.frame, china_TOWT_baseline_results_pre_metrics_unadjusted)
# china_TOWT_baseline_results_pre_metrics_unadjusted_df <- china_TOWT_baseline_results_pre_metrics_unadjusted_df %>%
#   mutate("meterID" = rownames(china_TOWT_baseline_results_pre_metrics_unadjusted_df)) %>%
#   select(meterID, everything()) %>%
#   mutate("location" = "china")  %>%
#   select(location, everything()) %>%
#   mutate("adjustments" = NA) %>%
#   mutate("adjustments_applied" = "no") %>%
#   mutate("Algorithm" = "Unweighted_TOWT_7 Days Unadjusted")
# 
# china_TOWT_baseline_results_pre_metrics_adjusted <- purrr::map(.x = china_TOWT_baseline_results_pre, .f = calculate_adjusted_metrics)
# china_TOWT_baseline_results_pre_metrics_adjusted_df <- do.call(rbind.data.frame, china_TOWT_baseline_results_pre_metrics_adjusted)
# china_TOWT_baseline_results_pre_metrics_adjusted_df <- china_TOWT_baseline_results_pre_metrics_adjusted_df %>%
#   mutate("meterID" = rownames(china_TOWT_baseline_results_pre_metrics_adjusted_df)) %>%
#   select(meterID, everything()) %>%
#   mutate("location" = "china")  %>%
#   select(location, everything()) %>%
#   mutate("adjustments" = "pre") %>%
#   mutate("adjustments_applied" = "yes") %>%
#   mutate("Algorithm" = "Unweighted_TOWT_7 Days pre-adjusted")
# 
# 
# china_TOWT_baseline_results_weighted_70.10 <- rlist::list.clean(china_TOWT_baseline_results_weighted_70.10, function(x) length(x) == 0L | anyNA(x)) # cleaning list of NAs
# 
# china_TOWT_baseline_results_weighted_70.10_metrics <- purrr::map(.x = china_TOWT_baseline_results_weighted_70.10, .f = calculate_unadjusted_metrics)
# china_TOWT_baseline_results_weighted_70.10_metrics_df <- do.call(rbind.data.frame, china_TOWT_baseline_results_weighted_70.10_metrics)
# china_TOWT_baseline_results_weighted_70.10_metrics_df <- china_TOWT_baseline_results_weighted_70.10_metrics_df %>%
#   mutate("meterID" = rownames(china_TOWT_baseline_results_weighted_70.10_metrics_df)) %>%
#   select(meterID, everything()) %>%
#   mutate("location" = "china")  %>%
#   select(location, everything()) %>%
#   mutate("adjustments" = NA) %>%
#   mutate("adjustments_applied" = "no") %>%
#   mutate("Algorithm" = "10_Day_Weighted_TOWT_70_Days Unadjusted")
# 
# 
# china_TOWT_baseline_results_weighted_70.14 <- rlist::list.clean(china_TOWT_baseline_results_weighted_70.14, function(x) length(x) == 0L | anyNA(x)) # cleaning list of NAs
# 
# china_TOWT_baseline_results_weighted_70.14_metrics <- purrr::map(.x = china_TOWT_baseline_results_weighted_70.14, .f = calculate_unadjusted_metrics)
# china_TOWT_baseline_results_weighted_70.14_metrics_df <- do.call(rbind.data.frame, china_TOWT_baseline_results_weighted_70.14_metrics)
# china_TOWT_baseline_results_weighted_70.14_metrics_df <- china_TOWT_baseline_results_weighted_70.14_metrics_df %>%
#   mutate("meterID" = rownames(china_TOWT_baseline_results_weighted_70.14_metrics_df)) %>%
#   select(meterID, everything()) %>%
#   mutate("location" = "china")  %>%
#   select(location, everything()) %>%
#   mutate("adjustments" = NA) %>%
#   mutate("adjustments_applied" = "no") %>%
#   mutate("Algorithm" = "14_Day_Weighted_TOWT_70_Days Unadjusted")
# 
# china_all_metrics <- bind_rows(china_day_matched_results_pre_unadjusted_df, china_day_matched_results_pre_adjusted_df, china_weather_matched_results_pre_unadjusted_df,
#                                china_weather_matched_results_pre_adjusted_df, china_TOWT_baseline_results_pre_metrics_unadjusted_df, china_TOWT_baseline_results_pre_metrics_adjusted_df,
#                                china_TOWT_baseline_results_weighted_70.10_metrics_df, china_TOWT_baseline_results_weighted_70.14_metrics_df)

# DC

DC_day_matched_results_pre <- rlist::list.clean(DC_day_matched_results_pre, function(x) length(x) == 0L | anyNA(x)) # cleaning list of NAs

DC_day_matched_results_pre_metrics_unadjusted <- purrr::map(.x = DC_day_matched_results_pre, .f = calculate_unadjusted_metrics)
DC_day_matched_results_pre_unadjusted_df <- do.call(rbind.data.frame, DC_day_matched_results_pre_metrics_unadjusted)
DC_day_matched_results_pre_unadjusted_df <- DC_day_matched_results_pre_unadjusted_df %>%
  mutate("meterID" = rownames(DC_day_matched_results_pre_unadjusted_df)) %>%
  select(meterID, everything()) %>%
  mutate("location" = "DC")  %>%
  select(location, everything()) %>%
  mutate("adjustments" = NA) %>%
  mutate("adjustments_applied" = "no") %>%
  mutate("Algorithm" = "Day Matching Unadjusted")

DC_day_matched_results_pre_metrics_adjusted <- purrr::map(.x = DC_day_matched_results_pre, .f = calculate_adjusted_metrics)
DC_day_matched_results_pre_adjusted_df <- do.call(rbind.data.frame, DC_day_matched_results_pre_metrics_adjusted)
DC_day_matched_results_pre_adjusted_df <- DC_day_matched_results_pre_adjusted_df %>%
  mutate("meterID" = rownames(DC_day_matched_results_pre_adjusted_df)) %>%
  select(meterID, everything()) %>%
  mutate("location" = "DC")  %>%
  select(location, everything()) %>%
  mutate("adjustments" = "pre") %>%
  mutate("adjustments_applied" = "yes") %>%
  mutate("Algorithm" = "Day Matching pre-adjusted")

DC_weather_matched_results_pre <- rlist::list.clean(DC_weather_matched_results_pre, function(x) length(x) == 0L | anyNA(x)) # cleaning list of NAs

DC_weather_matched_results_pre_metrics_unadjusted <- purrr::map(.x = DC_weather_matched_results_pre, .f = calculate_unadjusted_metrics)
DC_weather_matched_results_pre_unadjusted_df <- do.call(rbind.data.frame, DC_weather_matched_results_pre_metrics_unadjusted)
DC_weather_matched_results_pre_unadjusted_df <- DC_weather_matched_results_pre_unadjusted_df %>%
  mutate("meterID" = rownames(DC_weather_matched_results_pre_unadjusted_df)) %>%
  select(meterID, everything()) %>%
  mutate("location" = "DC")  %>%
  select(location, everything()) %>%
  mutate("adjustments" = NA) %>%
  mutate("adjustments_applied" = "no") %>%
  mutate("Algorithm" = "Weather Matching Unadjusted")

DC_weather_matched_results_pre_metrics_adjusted <- purrr::map(.x = DC_weather_matched_results_pre, .f = calculate_adjusted_metrics)
DC_weather_matched_results_pre_adjusted_df <- do.call(rbind.data.frame, DC_weather_matched_results_pre_metrics_adjusted)
DC_weather_matched_results_pre_adjusted_df <- DC_weather_matched_results_pre_adjusted_df %>%
  mutate("meterID" = rownames(DC_weather_matched_results_pre_adjusted_df)) %>%
  select(meterID, everything()) %>%
  mutate("location" = "DC")  %>%
  select(location, everything()) %>%
  mutate("adjustments" = "pre") %>%
  mutate("adjustments_applied" = "yes") %>%
  mutate("Algorithm" = "Weather Matching pre-adjusted")


DC_TOWT_baseline_results_pre <- rlist::list.clean(DC_TOWT_baseline_results_pre, function(x) length(x) == 0L | anyNA(x)) # cleaning list of NAs

DC_TOWT_baseline_results_pre_metrics_unadjusted <- purrr::map(.x = DC_TOWT_baseline_results_pre, .f = calculate_unadjusted_metrics)
DC_TOWT_baseline_results_pre_metrics_unadjusted_df <- do.call(rbind.data.frame, DC_TOWT_baseline_results_pre_metrics_unadjusted)
DC_TOWT_baseline_results_pre_metrics_unadjusted_df <- DC_TOWT_baseline_results_pre_metrics_unadjusted_df %>%
  mutate("meterID" = rownames(DC_TOWT_baseline_results_pre_metrics_unadjusted_df)) %>%
  select(meterID, everything()) %>%
  mutate("location" = "DC")  %>%
  select(location, everything()) %>%
  mutate("adjustments" = NA) %>%
  mutate("adjustments_applied" = "no") %>%
  mutate("Algorithm" = "Unweighted_TOWT_7 Days Unadjusted")

DC_TOWT_baseline_results_pre_metrics_adjusted <- purrr::map(.x = DC_TOWT_baseline_results_pre, .f = calculate_adjusted_metrics)
DC_TOWT_baseline_results_pre_metrics_adjusted_df <- do.call(rbind.data.frame, DC_TOWT_baseline_results_pre_metrics_adjusted)
DC_TOWT_baseline_results_pre_metrics_adjusted_df <- DC_TOWT_baseline_results_pre_metrics_adjusted_df %>%
  mutate("meterID" = rownames(DC_TOWT_baseline_results_pre_metrics_adjusted_df)) %>%
  select(meterID, everything()) %>%
  mutate("location" = "DC")  %>%
  select(location, everything()) %>%
  mutate("adjustments" = "pre") %>%
  mutate("adjustments_applied" = "yes") %>%
  mutate("Algorithm" = "Unweighted_TOWT_7 Days pre-adjusted")


DC_TOWT_baseline_results_weighted_70.10 <- rlist::list.clean(DC_TOWT_baseline_results_weighted_70.10, function(x) length(x) == 0L | anyNA(x)) # cleaning list of NAs

DC_TOWT_baseline_results_weighted_70.10_metrics <- purrr::map(.x = DC_TOWT_baseline_results_weighted_70.10, .f = calculate_unadjusted_metrics)
DC_TOWT_baseline_results_weighted_70.10_metrics_df <- do.call(rbind.data.frame, DC_TOWT_baseline_results_weighted_70.10_metrics)
DC_TOWT_baseline_results_weighted_70.10_metrics_df <- DC_TOWT_baseline_results_weighted_70.10_metrics_df %>%
  mutate("meterID" = rownames(DC_TOWT_baseline_results_weighted_70.10_metrics_df)) %>%
  select(meterID, everything()) %>%
  mutate("location" = "DC")  %>%
  select(location, everything()) %>%
  mutate("adjustments" = NA) %>%
  mutate("adjustments_applied" = "no") %>%
  mutate("Algorithm" = "10_Day_Weighted_TOWT_70_Days Unadjusted")


DC_TOWT_baseline_results_weighted_70.14 <- rlist::list.clean(DC_TOWT_baseline_results_weighted_70.14, function(x) length(x) == 0L | anyNA(x)) # cleaning list of NAs

DC_TOWT_baseline_results_weighted_70.14_metrics <- purrr::map(.x = DC_TOWT_baseline_results_weighted_70.14, .f = calculate_unadjusted_metrics)
DC_TOWT_baseline_results_weighted_70.14_metrics_df <- do.call(rbind.data.frame, DC_TOWT_baseline_results_weighted_70.14_metrics)
DC_TOWT_baseline_results_weighted_70.14_metrics_df <- DC_TOWT_baseline_results_weighted_70.14_metrics_df %>%
  mutate("meterID" = rownames(DC_TOWT_baseline_results_weighted_70.14_metrics_df)) %>%
  select(meterID, everything()) %>%
  mutate("location" = "DC")  %>%
  select(location, everything()) %>%
  mutate("adjustments" = NA) %>%
  mutate("adjustments_applied" = "no") %>%
  mutate("Algorithm" = "14_Day_Weighted_TOWT_70_Days Unadjusted")

DC_all_metrics <- bind_rows(DC_day_matched_results_pre_unadjusted_df, DC_day_matched_results_pre_adjusted_df, DC_weather_matched_results_pre_unadjusted_df,
                            DC_weather_matched_results_pre_adjusted_df, DC_TOWT_baseline_results_pre_metrics_unadjusted_df, DC_TOWT_baseline_results_pre_metrics_adjusted_df,
                            DC_TOWT_baseline_results_weighted_70.10_metrics_df, DC_TOWT_baseline_results_weighted_70.14_metrics_df)


# FC

FC_day_matched_results_pre <- rlist::list.clean(FC_day_matched_results_pre, function(x) length(x) == 0L | anyNA(x)) # cleaning list of NAs

FC_day_matched_results_pre_metrics_unadjusted <- purrr::map(.x = FC_day_matched_results_pre, .f = calculate_unadjusted_metrics)
FC_day_matched_results_pre_unadjusted_df <- do.call(rbind.data.frame, FC_day_matched_results_pre_metrics_unadjusted)
FC_day_matched_results_pre_unadjusted_df <- FC_day_matched_results_pre_unadjusted_df %>%
  mutate("meterID" = rownames(FC_day_matched_results_pre_unadjusted_df)) %>%
  select(meterID, everything()) %>%
  mutate("location" = "FC")  %>%
  select(location, everything()) %>%
  mutate("adjustments" = NA) %>%
  mutate("adjustments_applied" = "no") %>%
  mutate("Algorithm" = "Day Matching Unadjusted")

FC_day_matched_results_pre_metrics_adjusted <- purrr::map(.x = FC_day_matched_results_pre, .f = calculate_adjusted_metrics)
FC_day_matched_results_pre_adjusted_df <- do.call(rbind.data.frame, FC_day_matched_results_pre_metrics_adjusted)
FC_day_matched_results_pre_adjusted_df <- FC_day_matched_results_pre_adjusted_df %>%
  mutate("meterID" = rownames(FC_day_matched_results_pre_adjusted_df)) %>%
  select(meterID, everything()) %>%
  mutate("location" = "FC")  %>%
  select(location, everything()) %>%
  mutate("adjustments" = "pre") %>%
  mutate("adjustments_applied" = "yes") %>%
  mutate("Algorithm" = "Day Matching pre-adjusted")

FC_weather_matched_results_pre <- rlist::list.clean(FC_weather_matched_results_pre, function(x) length(x) == 0L | anyNA(x)) # cleaning list of NAs

FC_weather_matched_results_pre_metrics_unadjusted <- purrr::map(.x = FC_weather_matched_results_pre, .f = calculate_unadjusted_metrics)
FC_weather_matched_results_pre_unadjusted_df <- do.call(rbind.data.frame, FC_weather_matched_results_pre_metrics_unadjusted)
FC_weather_matched_results_pre_unadjusted_df <- FC_weather_matched_results_pre_unadjusted_df %>%
  mutate("meterID" = rownames(FC_weather_matched_results_pre_unadjusted_df)) %>%
  select(meterID, everything()) %>%
  mutate("location" = "FC")  %>%
  select(location, everything()) %>%
  mutate("adjustments" = NA) %>%
  mutate("adjustments_applied" = "no") %>%
  mutate("Algorithm" = "Weather Matching Unadjusted")

FC_weather_matched_results_pre_metrics_adjusted <- purrr::map(.x = FC_weather_matched_results_pre, .f = calculate_adjusted_metrics)
FC_weather_matched_results_pre_adjusted_df <- do.call(rbind.data.frame, FC_weather_matched_results_pre_metrics_adjusted)
FC_weather_matched_results_pre_adjusted_df <- FC_weather_matched_results_pre_adjusted_df %>%
  mutate("meterID" = rownames(FC_weather_matched_results_pre_adjusted_df)) %>%
  select(meterID, everything()) %>%
  mutate("location" = "FC")  %>%
  select(location, everything()) %>%
  mutate("adjustments" = "pre") %>%
  mutate("adjustments_applied" = "yes") %>%
  mutate("Algorithm" = "Weather Matching pre-adjusted")


FC_TOWT_baseline_results_pre <- rlist::list.clean(FC_TOWT_baseline_results_pre, function(x) length(x) == 0L | anyNA(x)) # cleaning list of NAs

FC_TOWT_baseline_results_pre_metrics_unadjusted <- purrr::map(.x = FC_TOWT_baseline_results_pre, .f = calculate_unadjusted_metrics)
FC_TOWT_baseline_results_pre_metrics_unadjusted_df <- do.call(rbind.data.frame, FC_TOWT_baseline_results_pre_metrics_unadjusted)
FC_TOWT_baseline_results_pre_metrics_unadjusted_df <- FC_TOWT_baseline_results_pre_metrics_unadjusted_df %>%
  mutate("meterID" = rownames(FC_TOWT_baseline_results_pre_metrics_unadjusted_df)) %>%
  select(meterID, everything()) %>%
  mutate("location" = "FC")  %>%
  select(location, everything()) %>%
  mutate("adjustments" = NA) %>%
  mutate("adjustments_applied" = "no") %>%
  mutate("Algorithm" = "Unweighted_TOWT_7 Days Unadjusted")

FC_TOWT_baseline_results_pre_metrics_adjusted <- purrr::map(.x = FC_TOWT_baseline_results_pre, .f = calculate_adjusted_metrics)
FC_TOWT_baseline_results_pre_metrics_adjusted_df <- do.call(rbind.data.frame, FC_TOWT_baseline_results_pre_metrics_adjusted)
FC_TOWT_baseline_results_pre_metrics_adjusted_df <- FC_TOWT_baseline_results_pre_metrics_adjusted_df %>%
  mutate("meterID" = rownames(FC_TOWT_baseline_results_pre_metrics_adjusted_df)) %>%
  select(meterID, everything()) %>%
  mutate("location" = "FC")  %>%
  select(location, everything()) %>%
  mutate("adjustments" = "pre") %>%
  mutate("adjustments_applied" = "yes") %>%
  mutate("Algorithm" = "Unweighted_TOWT_7 Days pre-adjusted")


FC_TOWT_baseline_results_weighted_70.10 <- rlist::list.clean(FC_TOWT_baseline_results_weighted_70.10, function(x) length(x) == 0L | anyNA(x)) # cleaning list of NAs

FC_TOWT_baseline_results_weighted_70.10_metrics <- purrr::map(.x = FC_TOWT_baseline_results_weighted_70.10, .f = calculate_unadjusted_metrics)
FC_TOWT_baseline_results_weighted_70.10_metrics_df <- do.call(rbind.data.frame, FC_TOWT_baseline_results_weighted_70.10_metrics)
FC_TOWT_baseline_results_weighted_70.10_metrics_df <- FC_TOWT_baseline_results_weighted_70.10_metrics_df %>%
  mutate("meterID" = rownames(FC_TOWT_baseline_results_weighted_70.10_metrics_df)) %>%
  select(meterID, everything()) %>%
  mutate("location" = "FC")  %>%
  select(location, everything()) %>%
  mutate("adjustments" = NA) %>%
  mutate("adjustments_applied" = "no") %>%
  mutate("Algorithm" = "10_Day_Weighted_TOWT_70_Days Unadjusted")


FC_TOWT_baseline_results_weighted_70.14 <- rlist::list.clean(FC_TOWT_baseline_results_weighted_70.14, function(x) length(x) == 0L | anyNA(x)) # cleaning list of NAs

FC_TOWT_baseline_results_weighted_70.14_metrics <- purrr::map(.x = FC_TOWT_baseline_results_weighted_70.14, .f = calculate_unadjusted_metrics)
FC_TOWT_baseline_results_weighted_70.14_metrics_df <- do.call(rbind.data.frame, FC_TOWT_baseline_results_weighted_70.14_metrics)
FC_TOWT_baseline_results_weighted_70.14_metrics_df <- FC_TOWT_baseline_results_weighted_70.14_metrics_df %>%
  mutate("meterID" = rownames(FC_TOWT_baseline_results_weighted_70.14_metrics_df)) %>%
  select(meterID, everything()) %>%
  mutate("location" = "FC")  %>%
  select(location, everything()) %>%
  mutate("adjustments" = NA) %>%
  mutate("adjustments_applied" = "no") %>%
  mutate("Algorithm" = "14_Day_Weighted_TOWT_70_Days Unadjusted")

FC_all_metrics <- bind_rows(FC_day_matched_results_pre_unadjusted_df, FC_day_matched_results_pre_adjusted_df, FC_weather_matched_results_pre_unadjusted_df,
                            FC_weather_matched_results_pre_adjusted_df, FC_TOWT_baseline_results_pre_metrics_unadjusted_df, FC_TOWT_baseline_results_pre_metrics_adjusted_df,
                            FC_TOWT_baseline_results_weighted_70.10_metrics_df, FC_TOWT_baseline_results_weighted_70.14_metrics_df)


# seattle

seattle_day_matched_results_pre <- rlist::list.clean(seattle_day_matched_results_pre, function(x) length(x) == 0L | anyNA(x)) # cleaning list of NAs

seattle_day_matched_results_pre_metrics_unadjusted <- purrr::map(.x = seattle_day_matched_results_pre, .f = calculate_unadjusted_metrics)
seattle_day_matched_results_pre_unadjusted_df <- do.call(rbind.data.frame, seattle_day_matched_results_pre_metrics_unadjusted)
seattle_day_matched_results_pre_unadjusted_df <- seattle_day_matched_results_pre_unadjusted_df %>%
  mutate("meterID" = rownames(seattle_day_matched_results_pre_unadjusted_df)) %>%
  select(meterID, everything()) %>%
  mutate("location" = "seattle")  %>%
  select(location, everything()) %>%
  mutate("adjustments" = NA) %>%
  mutate("adjustments_applied" = "no") %>%
  mutate("Algorithm" = "Day Matching Unadjusted")

seattle_day_matched_results_pre_metrics_adjusted <- purrr::map(.x = seattle_day_matched_results_pre, .f = calculate_adjusted_metrics)
seattle_day_matched_results_pre_adjusted_df <- do.call(rbind.data.frame, seattle_day_matched_results_pre_metrics_adjusted)
seattle_day_matched_results_pre_adjusted_df <- seattle_day_matched_results_pre_adjusted_df %>%
  mutate("meterID" = rownames(seattle_day_matched_results_pre_adjusted_df)) %>%
  select(meterID, everything()) %>%
  mutate("location" = "seattle")  %>%
  select(location, everything()) %>%
  mutate("adjustments" = "pre") %>%
  mutate("adjustments_applied" = "yes") %>%
  mutate("Algorithm" = "Day Matching pre-adjusted")

seattle_weather_matched_results_pre <- rlist::list.clean(seattle_weather_matched_results_pre, function(x) length(x) == 0L | anyNA(x)) # cleaning list of NAs

seattle_weather_matched_results_pre_metrics_unadjusted <- purrr::map(.x = seattle_weather_matched_results_pre, .f = calculate_unadjusted_metrics)
seattle_weather_matched_results_pre_unadjusted_df <- do.call(rbind.data.frame, seattle_weather_matched_results_pre_metrics_unadjusted)
seattle_weather_matched_results_pre_unadjusted_df <- seattle_weather_matched_results_pre_unadjusted_df %>%
  mutate("meterID" = rownames(seattle_weather_matched_results_pre_unadjusted_df)) %>%
  select(meterID, everything()) %>%
  mutate("location" = "seattle")  %>%
  select(location, everything()) %>%
  mutate("adjustments" = NA) %>%
  mutate("adjustments_applied" = "no") %>%
  mutate("Algorithm" = "Weather Matching Unadjusted")

seattle_weather_matched_results_pre_metrics_adjusted <- purrr::map(.x = seattle_weather_matched_results_pre, .f = calculate_adjusted_metrics)
seattle_weather_matched_results_pre_adjusted_df <- do.call(rbind.data.frame, seattle_weather_matched_results_pre_metrics_adjusted)
seattle_weather_matched_results_pre_adjusted_df <- seattle_weather_matched_results_pre_adjusted_df %>%
  mutate("meterID" = rownames(seattle_weather_matched_results_pre_adjusted_df)) %>%
  select(meterID, everything()) %>%
  mutate("location" = "seattle")  %>%
  select(location, everything()) %>%
  mutate("adjustments" = "pre") %>%
  mutate("adjustments_applied" = "yes") %>%
  mutate("Algorithm" = "Weather Matching pre-adjusted")


seattle_TOWT_baseline_results_pre <- rlist::list.clean(seattle_TOWT_baseline_results_pre, function(x) length(x) == 0L | anyNA(x)) # cleaning list of NAs

seattle_TOWT_baseline_results_pre_metrics_unadjusted <- purrr::map(.x = seattle_TOWT_baseline_results_pre, .f = calculate_unadjusted_metrics)
seattle_TOWT_baseline_results_pre_metrics_unadjusted_df <- do.call(rbind.data.frame, seattle_TOWT_baseline_results_pre_metrics_unadjusted)
seattle_TOWT_baseline_results_pre_metrics_unadjusted_df <- seattle_TOWT_baseline_results_pre_metrics_unadjusted_df %>%
  mutate("meterID" = rownames(seattle_TOWT_baseline_results_pre_metrics_unadjusted_df)) %>%
  select(meterID, everything()) %>%
  mutate("location" = "seattle")  %>%
  select(location, everything()) %>%
  mutate("adjustments" = NA) %>%
  mutate("adjustments_applied" = "no") %>%
  mutate("Algorithm" = "Unweighted_TOWT_7 Days Unadjusted")

seattle_TOWT_baseline_results_pre_metrics_adjusted <- purrr::map(.x = seattle_TOWT_baseline_results_pre, .f = calculate_adjusted_metrics)
seattle_TOWT_baseline_results_pre_metrics_adjusted_df <- do.call(rbind.data.frame, seattle_TOWT_baseline_results_pre_metrics_adjusted)
seattle_TOWT_baseline_results_pre_metrics_adjusted_df <- seattle_TOWT_baseline_results_pre_metrics_adjusted_df %>%
  mutate("meterID" = rownames(seattle_TOWT_baseline_results_pre_metrics_adjusted_df)) %>%
  select(meterID, everything()) %>%
  mutate("location" = "seattle")  %>%
  select(location, everything()) %>%
  mutate("adjustments" = "pre") %>%
  mutate("adjustments_applied" = "yes") %>%
  mutate("Algorithm" = "Unweighted_TOWT_7 Days pre-adjusted")


seattle_TOWT_baseline_results_weighted_70.10 <- rlist::list.clean(seattle_TOWT_baseline_results_weighted_70.10, function(x) length(x) == 0L | anyNA(x)) # cleaning list of NAs

seattle_TOWT_baseline_results_weighted_70.10_metrics <- purrr::map(.x = seattle_TOWT_baseline_results_weighted_70.10, .f = calculate_unadjusted_metrics)
seattle_TOWT_baseline_results_weighted_70.10_metrics_df <- do.call(rbind.data.frame, seattle_TOWT_baseline_results_weighted_70.10_metrics)
seattle_TOWT_baseline_results_weighted_70.10_metrics_df <- seattle_TOWT_baseline_results_weighted_70.10_metrics_df %>%
  mutate("meterID" = rownames(seattle_TOWT_baseline_results_weighted_70.10_metrics_df)) %>%
  select(meterID, everything()) %>%
  mutate("location" = "seattle")  %>%
  select(location, everything()) %>%
  mutate("adjustments" = NA) %>%
  mutate("adjustments_applied" = "no") %>%
  mutate("Algorithm" = "10_Day_Weighted_TOWT_70_Days Unadjusted")


seattle_TOWT_baseline_results_weighted_70.14 <- rlist::list.clean(seattle_TOWT_baseline_results_weighted_70.14, function(x) length(x) == 0L | anyNA(x)) # cleaning list of NAs

seattle_TOWT_baseline_results_weighted_70.14_metrics <- purrr::map(.x = seattle_TOWT_baseline_results_weighted_70.14, .f = calculate_unadjusted_metrics)
seattle_TOWT_baseline_results_weighted_70.14_metrics_df <- do.call(rbind.data.frame, seattle_TOWT_baseline_results_weighted_70.14_metrics)
seattle_TOWT_baseline_results_weighted_70.14_metrics_df <- seattle_TOWT_baseline_results_weighted_70.14_metrics_df %>%
  mutate("meterID" = rownames(seattle_TOWT_baseline_results_weighted_70.14_metrics_df)) %>%
  select(meterID, everything()) %>%
  mutate("location" = "seattle")  %>%
  select(location, everything()) %>%
  mutate("adjustments" = NA) %>%
  mutate("adjustments_applied" = "no") %>%
  mutate("Algorithm" = "14_Day_Weighted_TOWT_70_Days Unadjusted")

seattle_all_metrics <- bind_rows(seattle_day_matched_results_pre_unadjusted_df, seattle_day_matched_results_pre_adjusted_df, seattle_weather_matched_results_pre_unadjusted_df,
                                 seattle_weather_matched_results_pre_adjusted_df, seattle_TOWT_baseline_results_pre_metrics_unadjusted_df, seattle_TOWT_baseline_results_pre_metrics_adjusted_df,
                                 seattle_TOWT_baseline_results_weighted_70.10_metrics_df, seattle_TOWT_baseline_results_weighted_70.14_metrics_df)


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

vermont_day_matched_results_pre_metrics_adjusted <- purrr::map(.x = vermont_day_matched_results_pre, .f = calculate_adjusted_metrics)
vermont_day_matched_results_pre_adjusted_df <- do.call(rbind.data.frame, vermont_day_matched_results_pre_metrics_adjusted)
vermont_day_matched_results_pre_adjusted_df <- vermont_day_matched_results_pre_adjusted_df %>%
  mutate("meterID" = rownames(vermont_day_matched_results_pre_adjusted_df)) %>%
  select(meterID, everything()) %>%
  mutate("location" = "vermont")  %>%
  select(location, everything()) %>%
  mutate("adjustments" = "pre") %>%
  mutate("adjustments_applied" = "yes") %>%
  mutate("Algorithm" = "Day Matching pre-adjusted")

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

vermont_weather_matched_results_pre_metrics_adjusted <- purrr::map(.x = vermont_weather_matched_results_pre, .f = calculate_adjusted_metrics)
vermont_weather_matched_results_pre_adjusted_df <- do.call(rbind.data.frame, vermont_weather_matched_results_pre_metrics_adjusted)
vermont_weather_matched_results_pre_adjusted_df <- vermont_weather_matched_results_pre_adjusted_df %>%
  mutate("meterID" = rownames(vermont_weather_matched_results_pre_adjusted_df)) %>%
  select(meterID, everything()) %>%
  mutate("location" = "vermont")  %>%
  select(location, everything()) %>%
  mutate("adjustments" = "pre") %>%
  mutate("adjustments_applied" = "yes") %>%
  mutate("Algorithm" = "Weather Matching pre-adjusted")


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

vermont_TOWT_baseline_results_pre_metrics_adjusted <- purrr::map(.x = vermont_TOWT_baseline_results_pre, .f = calculate_adjusted_metrics)
vermont_TOWT_baseline_results_pre_metrics_adjusted_df <- do.call(rbind.data.frame, vermont_TOWT_baseline_results_pre_metrics_adjusted)
vermont_TOWT_baseline_results_pre_metrics_adjusted_df <- vermont_TOWT_baseline_results_pre_metrics_adjusted_df %>%
  mutate("meterID" = rownames(vermont_TOWT_baseline_results_pre_metrics_adjusted_df)) %>%
  select(meterID, everything()) %>%
  mutate("location" = "vermont")  %>%
  select(location, everything()) %>%
  mutate("adjustments" = "pre") %>%
  mutate("adjustments_applied" = "yes") %>%
  mutate("Algorithm" = "Unweighted_TOWT_7 Days pre-adjusted")


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

vermont_all_metrics <- bind_rows(vermont_day_matched_results_pre_unadjusted_df, vermont_day_matched_results_pre_adjusted_df, vermont_weather_matched_results_pre_unadjusted_df,
                                 vermont_weather_matched_results_pre_adjusted_df, vermont_TOWT_baseline_results_pre_metrics_unadjusted_df, vermont_TOWT_baseline_results_pre_metrics_adjusted_df,
                                 vermont_TOWT_baseline_results_weighted_70.10_metrics_df, vermont_TOWT_baseline_results_weighted_70.14_metrics_df)

#all_metrics <- bind_rows(china_all_metrics, DC_all_metrics, FC_all_metrics, seattle_all_metrics, vermont_all_metrics)
all_metrics <- bind_rows(DC_all_metrics, FC_all_metrics, seattle_all_metrics, vermont_all_metrics)
write.xlsx(all_metrics, paste0(results_directory, "All Metrics_1-4.xlsx"))

