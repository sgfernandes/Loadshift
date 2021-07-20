
find_DR_prediction_days <- function(completed_timeseries, event_hours = "T00:00/T23:59"){ # KEEP TIME FOR THE ENTIRE DAY FOR THE LOADSHIFT TASK
  
  data_pred <- completed_timeseries[event_hours] # Extract all data between 10am and 6pm

  data_pred_tbl <- tk_tbl(data_pred, preserve_index = TRUE, rename_index = "time") # convert ts object to tibble
  
  max_peak_load_tbl <- data_pred_tbl %>% # finding DR days : defined as days with max peak and no NA values within the event window.
    mutate(day = as_date(time)) %>%
    mutate(day_name = lubridate::wday(as_date(time), label = TRUE)) %>%
    group_by(day) %>%
    mutate(peak_load = max(eload)) %>%
    mutate(max_temp = max(temp)) %>%
    filter(!is.na(peak_load)) %>% # remove any day that has NA peak load - this essentially removes all days that have 1 or more NA values in the event window
    filter(!is.na(max_temp))# %>% # remove any day that has NA peak temp - this essentially removes all days that have 1 or more NA values in the event window
    #filter(day_name != "Sat" & day_name != "Sun") # remove weekend DR days. KEEP THIS IN FOR THE LOADSHIFT TASK
   
  
  if(nrow(max_peak_load_tbl) != 0 ){

    sorted_peak_load_tbl <- unique(max_peak_load_tbl[, c("day", "peak_load", "max_temp")])
    sorted_peak_load_tbl <- sorted_peak_load_tbl[order(sorted_peak_load_tbl$peak_load, decreasing = TRUE), ] 
    
    selected_prediction_days <- sorted_peak_load_tbl[1:364, ]  # WE WANT ALL THE DAYS FOR THE LOAD SHIFT TASK
    selected_prediction_days <- data.frame(selected_prediction_days[order(selected_prediction_days$day), ]) %>%
      filter(peak_load != 0) %>% # remove all days that have zero eload as peak load. sometimes this leads to a zero row df. the algorithms check for this and remove events accordingly.
      mutate(day_name = weekdays(day))
    
    prediction_df <- data_pred_tbl %>%
      filter(as_date(time) %in% selected_prediction_days$day) %>%
      mutate(day_name = weekdays(time)) 
    
    if (nrow(selected_prediction_days) != 0) {
      return(list("selected_days" = selected_prediction_days, "prediction_df" = prediction_df))
    } else {
      return("No DR days found")
    }
  } else {
    return("No DR days found")
  }
    
}
