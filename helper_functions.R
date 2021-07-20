#helper functions

coerce_to_xts <- function(data){
  data_xts <- xts(data[, -1], order.by = data[,1])
  return(data_xts)
}


find_common_elements <- function(list1, list2, list3, list4, list5) {
  
  list1_2 <- list1[names(list2)]
  list2_3 <- list2[names(list3)]
  list3_4 <- list3[names(list4)]
  list4_5 <- list4[names(list5)]
  
  list1_3 <- list1_2[names(list2_3)]
  list3_5 <- list3_4[names(list4_5)]
  
  list <- list1_3[names(list3_5)]
  
  list <- rlist::list.clean(list)
  
  return(list)
}


subset_list <- function(list, common_elements) {
  
  list <- list[names(common_elements)]
  
  return(list)
  
}


remove_events_with_NA_load <- function(df) {
  
  if(sum(df$unadjusted_baseline, na.rm = T) == 0) {
    return(NULL)
  } else {
    return(df)
  }
  
}
