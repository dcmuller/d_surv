pctile_table <- function(rowv, # character vector of variable names to tabulate
                         colv, # character vector of length 1 to cross-tabluate
                         data, # data.frame in which to look for rowv and colv
                         varlabs, # character vector of variable labels 
                         digits = 1, # number of decimal places to round to
                         latex = FALSE) {
  ## if varlabs have not been supplied, use the varnames
  if (hasArg(varlabs)) {
    if (length(varlabs) != length(rowv)) {
      stop("length(varlabs) != length(rowv)")
    }
  }
  else {
    varlabs <- rowv
  }
  ## list for collecting tables
  reslist <- vector("list", length(rowv))
  y <- get(colv, data)
  for (i in 1:length(rowv)) {
    x <- get(rowv[i], data)
    rown <- as.character(varlabs[i])
    dt <- data.table(x, y)
    setkey(dt, y)
    pctiles <- dt[, 
                  format(round(quantile(x, 
                                        probs=c(0.5, 0.05, 0.95), na.rm = TRUE)
                               , 1)), 
                  by=y]
    ## remove NA's
    pctiles[V1=="NA", V1 := ""]
    pctiles_vec <- pctiles[, 
                           ifelse(V1[1]=="", 
                                  "", 
                                  paste0(V1[1], " (", V1[2], ", ", V1[3], ")")), 
                           by=key(pctiles)][, V1]
    reslist[[i]] <- c(rown, pctiles_vec)
  }
  res <- do.call(rbind, reslist)
  rownames(res) <- res[, 1]
  res <- res[, -1]
  colnames(res) <- levels(as.factor(y))
  return(res)
}
