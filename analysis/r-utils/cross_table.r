fptable <- function(rowv, colv, rown, useNA, margin, pct, pct_rnd, latex) {
  f <- table(rowv, colv, useNA=useNA)
  p <- prop.table(f, margin)
  if (pct == TRUE) {
    p <- 100*p
  }
  p <- round(p, pct_rnd)
  row <- dim(f)[1]
  col <- dim(f)[2]
  fp <- matrix(NA, row, col)
  for (i in 1:row) {
    for (j in 1:col) {
      fp[i, j] <- paste0(f[i, j], " (", p[i, j], ")")
    }
  }
  ## label levels of the variable
  if (latex == TRUE) {
    vallabs <- paste("\\hspace{1.5em}", as.character(rownames(f)))
  }
  else {
    vallabs <- paste("  ", as.character(rownames(f)))
  }
  fp <- cbind(vallabs, fp)
  ## label the variable itself
  fp <- rbind(c(rown, rep("", ncol(fp)-1)), fp)
  return(fp)
}

cross_table <- function(rowv, # character vector of variable names to tabulate
                        colv, # character vector of length 1 to cross-tabluate
                        data, # data.frame in which to look for rowv and colv
                        useNA = "ifany", # passed to table
                        varlabs, # character vector of variable labels 
                        margin = 2, # passed to table, default to columns
                        pct = TRUE, # multiply proportions by 100
                        pct_rnd = 0, # number of digits to round to for percent
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
    reslist[[i]] <- fptable(x, y, rown, useNA, margin, pct, pct_rnd, latex)
  }
  res <- do.call(rbind, reslist)
  rownames(res) <- res[, 1]
  res <- res[, -1]
  colnames(res) <- levels(as.factor(y))
  return(res)
}

