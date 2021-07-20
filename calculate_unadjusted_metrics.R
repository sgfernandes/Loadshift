

calculate_unadjusted_metrics <- function(bldg_results) {
  
  calculate_metrics_per_event <- function(meter_results) {
    
    residuals <- meter_results$eload - meter_results$unadjusted_baseline
    n <- length(residuals)
    
    # CVRMSE <- residuals %>%
    #   magrittr::raise_to_power(2) %>%
    #   sum(., na.rm = T) %>% # # prediction days were chosen such that there were no NA values in the event window. Baseline groups had days with less than or equal to 2 NA values
    #   magrittr::divide_by(n) %>%
    #   magrittr::raise_to_power(0.5) %>%
    #   magrittr::divide_by(mean(meter_results$eload, na.rm = T))
    
    CVRMSE <- residuals %>%
        magrittr::raise_to_power(2) %>%
        magrittr::divide_by(meter_results$eload)
    
    # NMBE <- residuals %>%
    #   sum(., na.rm = T) %>% # # prediction days were chosen such that there were no NA values in the event window. Baseline groups had days with less than or equal to 2 NA values
    #   magrittr::divide_by(n*mean(meter_results$eload, na.rm = T))
    
    mape <- residuals %>%
    magrittr::divide_by(meter_results$eload)
    
    adjustment_ratio <- meter_results$adjustment_ratio[1]
    
    metrics <- data.frame(matrix(nrow = nrow(meter_results), ncol = 3))  # nrow(meter_results)
    names(metrics) <- c("Date","CV(RMSE)", "APE")
    metrics$`Date` <- meter_results$time
    metrics$`CV(RMSE)` <- CVRMSE
    metrics$NMBE <- mape
    metrics$adjustment_ratio <- adjustment_ratio
    
    return(metrics)
    
  }
  
  if(is.list(bldg_results)) {
    
    metrics_list <- purrr::map(.x = bldg_results, .f = calculate_metrics_per_event)
    df = do.call(rbind.data.frame, metrics_list)
    
    df_total = NULL
    df_total <- rbind(df_total,df)
    rownames(df_total) <- NULL
    return(df_total)
    
  } else {
    
    return(NULL)
  }
  
}
