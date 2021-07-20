

calculate_TOWT_adjusted_baseline <- function(DR_days, completed_tibble, baseline_days_count, timescale_days, pre_adjustment_only = FALSE,
                                             initial_timslice = "T00:00/T23:59", event_hours = "T00:00/T23:59",
                                             pre_adjustment_hours = "T07:00/T08:00", post_adjustment_hours = "T21:00/T22:00") {
  
  if(is.character(DR_days)) { # 'No DR days found'
    
    return("No Data Available")
    
  } else { 
    
    # note that clean_eload_data() has been implemented outside of this function already
    
    # add in columns: 'day_name', 'day', 'federal_holidays', 'event_day' -----
      
    completed_tibble <-  completed_tibble %>%
      mutate(day_name = weekdays(time)) %>%
      mutate(day = as_date(time)) %>%
      mutate(federal_holidays = ifelse(as.Date(completed_tibble$time)  %in% federal_holidays$time, 1, 0)) %>%
      mutate(event_day = ifelse(as.Date(completed_tibble$time) %in% DR_days$selected_days$day, 1, 0))
      
    # identify baseline_df ----- 
    
    create_hourly_baseline_tibble <- function(selected_day, completed_tibble){
          
    baseline_tibble <- completed_tibble %>%
      #filter(day_name != "Saturday" & day_name != "Sunday") %>% # removing weekends from baseline, keep for loadshift
      filter(federal_holidays != 1, event_day != 1) %>%
      filter(day < selected_day$day) # select baseline days from days leading up to the event day
          
      if (! is.null(baseline_days_count)) { 
       baseline_days <- unique(baseline_tibble[, c("day", "day_name")]) %>%
         tail(n = baseline_days_count) # picking last n days for baseline
      } else {
        baseline_days <- unique(baseline_tibble[, c("day", "day_name")]) # if baseline_days_count is not provided, use all days - [option not used yet]
      }
              
      selected_baseline_tibble <- baseline_tibble %>%
       semi_join(baseline_days, by = "day") # create baseline tibble using the user input of baseline days
          
      baseline_df <- nmecr::create_dataframe(eload_data = selected_baseline_tibble[, c("time", "eload")],
                                              temp_data = selected_baseline_tibble[, c("time", "temp")])  %>%
       data.frame(.)
       
      if(is.null(baseline_df) | nrow(baseline_df) < 168) { # have at least 7 days of data for prediction
        return(NULL)
      } else {
        # determine the temperature variability of the baseline group
        temp_variability <- determine_temp_variability(baseline_df) 
        max_same_temp_pct <- temp_variability/nrow(baseline_df)
        
        if(max_same_temp_pct > 0.05){ # return NULL for baseline_df if its temperature variability is less than 5%
          return (NULL)
        } else {
          return(baseline_df)
        }
      }
    }
        
    selected_day_list <- split(DR_days$selected_days, seq(nrow(DR_days$selected_days)))
     
    # calculate baseline_df for each prediction/event day    
    baseline_for_DR <- purrr::map(.x = selected_day_list, .f = create_hourly_baseline_tibble, completed_tibble = completed_tibble)
    baseline_for_DR <- rlist::list.clean(baseline_for_DR, fun = is.null)
     
    # slice baseline DR data for generating adjusted baselines ------
     
    baseline_for_DR <- purrr::map(.x = baseline_for_DR, .f = coerce_to_xts)
     
    time_slice <- initial_timslice # using endpoints for data slicing
    
    baseline_hours_for_DR <- lapply(baseline_for_DR, "[", time_slice)
        
    # update selected_day_list to match the number of elements in baseline_for_DR ----
    if(! assertive::is_empty(baseline_for_DR)) {
      
      selected_day_list <- selected_day_list[names(baseline_hours_for_DR)]
      updated_selected_days <- lapply(selected_day_list, `[[`, 1)
       
      # while different from day-matching and weather-matching, this ensure that date formats are maintained
      updated_selected_days <- data.frame(t(bind_rows(updated_selected_days)))
      names(updated_selected_days) <- "day" 
      updated_selected_days$day <- as.Date(updated_selected_days$day)
          
      DR_days_data <- completed_tibble %>%
       filter(day %in% updated_selected_days$day) %>%
       data.frame(.)
    
      DR_days_data_xts <- xts(DR_days_data[ , c("eload", "temp")], order.by = DR_days_data[, "time"])
        
      DR_event_hours_xts <- DR_days_data_xts[time_slice]  # slice from 7:00 AM to 10:00 PM initially

      # unadjusted baseline ---- (from 7AM to 10PM) ----
          
      create_unadjusted_baseline <- function(selected_day, baseline_for_DR, DR_event_hours_xts){
        
        selected_date <- selected_day[1,1]
         
        DR_event_hours_xts <- tk_tbl(DR_event_hours_xts, preserve_index = TRUE, rename_index = "time")
        baseline_for_DR <- tk_tbl(baseline_for_DR, preserve_index = TRUE, rename_index = "time")
         
        prediction_data <- DR_event_hours_xts %>%
         filter(as.Date(time) == selected_date)
        
        unadjusted_baseline <- nmecr::model_with_TOWT(training_data = baseline_for_DR, prediction_data = prediction_data, 
                                                         model_input_options = assign_model_inputs(timescale_days = timescale_days))
         
        results_df <- unadjusted_baseline$prediction_data%>%
         data.frame(.)
        names(results_df) <- c("time", "eload", "temp", "unadjusted_baseline")
        return(results_df)
      }
          
      prediction_DR <- purrr::map2(.x = selected_day_list, .y = baseline_for_DR, .f = create_unadjusted_baseline, DR_event_hours_xts = DR_event_hours_xts)
      prediction_DR <- rlist::list.clean(prediction_DR, fun = is.null)
      prediction_DR <- purrr::map(.x = prediction_DR, .f = coerce_to_xts)
      
      # same-day adjustement
       
      if( is.null(timescale_days)) {
        
        event_hours <- event_hours
         
        pre_adjustment_hours <- pre_adjustment_hours
        kWh_pre_adjustment_hours <- DR_event_hours_xts[pre_adjustment_hours] 
         
        if (! pre_adjustment_only) {
          post_adjustment_hours <- post_adjustment_hours
          kWh_post_adjustment_hours <- DR_event_hours_xts[post_adjustment_hours]
          adjustment_hours <- rbind(kWh_pre_adjustment_hours, kWh_post_adjustment_hours)
        } else {
          adjustment_hours <- kWh_pre_adjustment_hours
        }
         
        adjustment_hours <- tk_tbl(adjustment_hours, preserve_index = TRUE, rename_index = "time") 
         
        adjustment_hours_kWh <- adjustment_hours %>%
         group_by("time" = as.Date(time)) %>%
         summarize('Average kWh' = mean(eload, na.rm = T)) 
         
        names(prediction_DR) <- adjustment_hours_kWh$time
         
        adjustment_hours_kWh <- setNames(split(adjustment_hours_kWh, seq(nrow(adjustment_hours_kWh))), adjustment_hours_kWh$time)
         
        calculate_baseline_adjustment_hours_kWh <- function(prediction_DR){
           
          baseline_pre_adjustment_hours <- prediction_DR$unadjusted_baseline[pre_adjustment_hours]
           
          if (! pre_adjustment_only) {
            baseline_post_adjustment_hours <- prediction_DR$unadjusted_baseline[post_adjustment_hours]
            baseline_adjustment_hours_kWh <-  rbind(baseline_pre_adjustment_hours, baseline_post_adjustment_hours)
          } else {
            baseline_adjustment_hours_kWh <- baseline_pre_adjustment_hours
          }
           
          baseline_adjustment_hours_kWh <- tk_tbl(baseline_adjustment_hours_kWh, preserve_index = TRUE, rename_index = "time") 
           
          baseline_adjustment_hours_kWh <- baseline_adjustment_hours_kWh %>%
            summarize('Average kWh' = mean(unadjusted_baseline, na.rm = T))
        }
         
        baseline_adjustment_hours_kWh <- purrr::map(.x = prediction_DR, .f = calculate_baseline_adjustment_hours_kWh)
         
        calculate_adjusted_baseline <- function(adjustment_hours_kWh, baseline_adjustment_hours_kWh, prediction_DR){
          
          df <- prediction_DR[event_hours] %>%
            tk_tbl(preserve_index = TRUE, rename_index = "time")
           
          if(baseline_adjustment_hours_kWh$`Average kWh` == 0 |
             is.nan(baseline_adjustment_hours_kWh$`Average kWh`)) {
            
            df <- df %>%
              mutate("adjustment_ratio" = NA) %>% # no adjustment if the adjustment hours have zero baseline adjustment hours average kWh
              mutate("adjusted_baseline" = unadjusted_baseline) 
             
          } else {
             
            adjustment_ratio <- adjustment_hours_kWh$`Average kWh`/baseline_adjustment_hours_kWh$`Average kWh`
             
            df <- df %>%
             mutate("adjustment_ratio" = adjustment_ratio) # note that the adjustment ratio is one number applied to all hours within the 10AM to 6PM window  
             
            if(adjustment_ratio > 1.4) {
              df <- df %>%
              mutate("adjusted_baseline" = unadjusted_baseline*1.4) 
            } else if (adjustment_ratio < 0.71) {
              df <- df %>%
               mutate("adjusted_baseline" = unadjusted_baseline*0.71)
            } else {
              df <- df %>%
                mutate("adjusted_baseline" = unadjusted_baseline*adjustment_ratio)
            }
          }
        }
         
        prediction_DR_adjusted <- purrr::pmap(.l = list(adjustment_hours_kWh = adjustment_hours_kWh, baseline_adjustment_hours_kWh = baseline_adjustment_hours_kWh, prediction_DR = prediction_DR),
                                               .f = calculate_adjusted_baseline)
        
        prediction_DR_adjusted <- purrr::map(.x = prediction_DR_adjusted, .f = remove_events_with_NA_load)
        prediction_DR_adjusted <- rlist::list.clean(prediction_DR_adjusted, fun = is.null)
        
         
        return(prediction_DR_adjusted)
         
      } else { 
        
        # naming prediction_DR
        event_hours <- tk_tbl(DR_event_hours_xts, preserve_index = TRUE, rename_index = "time") 
        event_hours_kWh <- event_hours %>%
          group_by("time" = as.Date(time)) %>%
          summarize('Average kWh' = mean(eload, na.rm = T)) 
        
        names(prediction_DR) <- event_hours_kWh$time
        
        prediction_DR <- purrr::map(.x = prediction_DR, .f = remove_events_with_NA_load)
        prediction_DR <- rlist::list.clean(prediction_DR, fun = is.null)
         
        return(prediction_DR)
         
      }
       
    } else { 
       
     return("No Data Available")
    }
  }
}
         
         