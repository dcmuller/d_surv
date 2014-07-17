## function takes a character vector and returns a comma separated list
##    that can be added directly to a sentence.
## e.g., c("this", "that", "the other") will be turned in to: 
##    "this, that, and the other"
sentence_list <- function(x) {
  n <- length(x)
  for (i in 1:n) {
    if (i == 1) {
      s <- x[i]
    }
    else if (i < n) {
      s <- paste0(s, ", ", x[i])
    }
    else {
      s <- paste0(s, ", and ", x[i])
    }
    i <- i+1
  }
  return(s)
}
