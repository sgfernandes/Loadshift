

calculate_day_matching_adjusted_baseline <- function(DR_days, completed_timeseries, pre_adjustment_only = FALSE, 
                                                     initial_timslice = "T00:00/T23:59", event_hours = "T00:00/T23:59",
                                                     pre_adjustment_hours = "T07:00/T08:00", post_adjustment_hours = "T21:00/T22:00") {
  
  if(is.character(DR_days)) { # No DR days found
    
    return("No Data Available")
    
  } else {
    
    # add in columns: 'day_name', 'day', 'federal_holidays', 'event_day' -----
      
    data <- clean_eload_data(completed_timeseries) # keep only days that have 2 or less than 2 hours of NA eload values in a day
    
    # mutate day_name, day, federal_holidays, and ebent_days  
    data <-  tk_tbl(data, preserve_index = TRUE, rename_index = "time") %>%
      mutate(day_name = weekdays(time)) %>%
      mutate(day = as_date(time))
      
    data <- data %>%
      mutate(federal_holidays = ifelse(as.Date(data$time)  %in% federal_holidays$time, 1, 0)) %>%
      mutate(event_day = ifelse(as.Date(data$time) %in% DR_days$selected_days$day, 1, 0))
      
    # create baseline days' groups ----- 
      
    data_daily <- data %>%
      group_by("day" = date(time)) %>%
      summarize(eload = sum(eload, na.rm = T), max_temp = max(temp, na.rm = T))# calculating eload and max daily temp after removing NAs, because there may be instances when there are only a handful of NAs in a day
      
    data_daily <- do.call(data.frame,lapply(data_daily, function(x) replace(x, is.infinite(x),NA))) %>% # if all values are NAs for a day, replace the '-Inf' with an NA
      filter(!is.na(eload)) %>% # then filter out the NA values 
      filter(!is.na(max_temp))
      
    baseline_days <- unique(data.frame("day" = data$day, "day_name" = data$day_name)) %>% # remove all days that have NA values from the baseline_days, max and min baseline days are calculated from non-NA days
      inner_join(data_daily, by = "day") # baseline days are calculated as the most recent non-NA days - no restriction on the pool of baseline days
                                                            
    # identify baseline_df -----
    
    create_hourly_baseline <- function(selected_day, baseline_days, data) {
          
      baseline_days <- baseline_days %>%
        mutate(federal_holidays = ifelse(baseline_days$day  %in% federal_holidays$time, 1, 0)) %>%
        mutate(event_day = ifelse(baseline_days$day %in% DR_days$selected_days$day, 1, 0)) %>%
        #filter(day_name != "Saturday" & day_name != "Sunday") %>%
        filter(federal_holidays != 1, event_day != 1) %>%
        filter(day < selected_day$day) # select baseline days from days leading up to the event day
              
      max_baseline_date <- baseline_days$day[which.min(abs(baseline_days$day - selected_day$day))] # select one day before the selected date

      min_baseline_row <- which(grepl(max_baseline_date, baseline_days$day)) - 9
      if(min_baseline_row < 0 | min_baseline_row == 0) {
       return(NULL) # ensuring that only events whose baseline groups consist of 10 days are used
      } else {
        
        min_baseline_date <- baseline_days[min_baseline_row, 1]
              
        data_baseline_df <- data %>%
           #filter(day_name != "Saturday"& day_name != "Sunday") %>%
           filter(federal_holidays != 1, event_day != 1) %>%
           filter(!is.na(eload)) %>%
           filter(day < selected_day$day, day >= min_baseline_date) %>%
           select(time, eload, temp) %>%
           data.frame(.)
                
        # determine the temperature variability of the baseline group
        temp_variability <- determine_temp_variability(data_baseline_df) 
        max_same_temp_pct <- temp_variability/nrow(data_baseline_df)
  
        if(max_same_temp_pct > 0.05){ # return NULL for baseline_df if its temperature variability is less than 5%
          return (NULL)
        } else {
          return(data_baseline_df)
        }
      }
    }
        
    selected_day_list <- split(DR_days$selected_days, seq(nrow(DR_days$selected_days)))
    
    # calculate baseline_df for each prediction/event day    
    baseline_for_DR <- purrr::map(.x = selected_day_list, .f = create_hourly_baseline, baseline_days = baseline_days, data = data)
    baseline_for_DR <- rlist::list.clean(baseline_for_DR, fun = is.null)

    # slice baseline DR data for generating adjusted baselines ------
        
    baseline_for_DR <- purrr::map(.x = baseline_for_DR, .f = coerce_to_xts)
        
    time_slice <- initial_timslice # using endpoints for data slicing - beginning at 6am and ending at 10pm
        
    baseline_hours_for_DR <- lapply(baseline_for_DR, "[", time_slice)
        
    # update selected_day_list to match the number of elements in baseline_for_DR ----
    if(! assertive::is_empty(baseline_for_DR)) {
      
      selected_day_list <- selected_day_list[names(baseline_hours_for_DR)]
      updated_selected_days <- lapply(selected_day_list, `[[`, 1)
      updated_selected_days <- do.call(rbind.data.frame, updated_selected_days)
      names(updated_selected_days) <- "day"
     
      DR_days_data <- data %>%
        filter(day %in% updated_selected_days$day) %>%
        data.frame(.)
          
      DR_days_data_xts <- xts(DR_days_data[ , c("eload", "temp")], order.by = DR_days_data[, "time"])
        
      DR_event_hours_xts <- DR_days_data_xts[time_slice] # slice from 7:00 AM to 10:00 PM initially
          
      # unadjusted baselines (from 7AM to 10PM) ---- 
          
      create_unadjusted_baseline <- function(selected_day, baseline_hours_for_DR, DR_event_hours_xts){
            
        selected_date <- selected_day[1,1]
            
        results_df <- DR_event_hours_xts$eload[as.character(selected_date)]
        results_df <- tk_tbl(results_df, preserve_index = TRUE, rename_index = "time")

        unadjusted_baseline <- data.frame("unadjusted_baseline" = stats::aggregate(baseline_hours_for_DR$eload, hour(index(baseline_hours_for_DR)), mean))
            
        unadjusted_baseline <- data.frame("time" = results_df$time, "unadjusted_baseline" = unadjusted_baseline$unadjusted_baseline)
        results_df <- left_join(results_df, unadjusted_baseline, by = "time") %>%
          data.frame()
        
        return(results_df)
        
      }
          
      prediction_DR <- purrr::map2(.x = selected_day_list, .y = baseline_hours_for_DR, .f = create_unadjusted_baseline, DR_event_hours_xts = DR_event_hours_xts)
      prediction_DR <- purrr::map(.x = prediction_DR, .f = coerce_to_xts)

      # same-day adjustement
      
      event_hours <- event_hours  # using endpoints for data slicing - beginning at 10am and ending at 6pm
          
      pre_adjustment_hours <- pre_adjustment_hours # using endpoints for data slicing - beginning at 6am and ending at 8am
      kWh_pre_adjustment_hours <- DR_event_hours_xts[pre_adjustment_hours] 
      
      if (! pre_adjustment_only) {
        post_adjustment_hours <- post_adjustment_hours # using endpoints for data slicing - beginning at 8pm and ending at 10pm
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
        
        df <- prediction_DR[event_hours] %>% # using endpoints for data slicing - beginning at 10am and ending at 6pm
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
          
          if(adjustment_ratio > 1.2) {
            df <- df %>%
              mutate("adjusted_baseline" = unadjusted_baseline*1.2) 
          } else if (adjustment_ratio < 0.83) {
            df <- df %>%
            mutate("adjusted_baseline" = unadjusted_baseline*0.83)
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
          
      return("No Data Available")
          
    }
  } 
}

  


  