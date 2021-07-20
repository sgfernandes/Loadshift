
# remove all days that have more than 2 NAs in the event widown
clean_eload_data <- function(cleaned_data_xts, event_hours = "T00:00/T23:59") {
  
  cleaned_data_xts_subset <- cleaned_data_xts[event_hours] # subset times during the event_window
  
  keep_days <- cleaned_data_xts_subset %>%
    tk_tbl(preserve_index = TRUE, rename_index = "time") %>%
    mutate(day = date(time)) %>%
    group_by(day) %>%
    summarise(Total_NA = sum(is.na(eload))) %>%
    filter(Total_NA <= 2) 
  
  cleaned_data <- cleaned_data_xts %>%
    tk_tbl(preserve_index = TRUE, rename_index = "time") %>%
    mutate(day = date(time)) %>%
    data.frame()
  
  cleaned_data <- subset(cleaned_data, day %in% keep_days$day) %>% 
    select(c("time", "eload", "temp")) # only keep days for which the NA values are not more than 2 in the event window
  
  cleaned_data.xts <- xts(cleaned_data[, -1], order.by = cleaned_data[, 1]) # convert back to xts
  
  return(cleaned_data.xts)
}
