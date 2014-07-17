interacted <- function(mod, main_var, strata_var, eform=TRUE) {
  ## Function to create linear combinations of coefficients, in
  ## particular main effects and their interaction terms, in order
  ## to get stratum specific estimates with confidence intervals
  ##
  ## David C Muller <davidmull@gmail.com>
    
  require(aod)
  ## linear combination
  labs <- c(main_var,
            paste0(main_var, ":", strata_var, levels(with(mod, model)[, strata_var])[-1]))
  cmat <- diag(length(labs)) 
  cmat[, 1] <- 1
  colnames(cmat) <- labs
  b <- coef(mod)[labs]
  V <- vcov(mod)[labs, labs]
  est <- cmat %*% b
  se <- sqrt(diag(cmat %*% V %*% t(cmat)))
  lincom <- cbind(est, est - 1.96*se, est + 1.96*se)
  colnames(lincom) <- c("Estimate", "Lower.CI", "Upper.CI")
  if (eform) {
    lincom <- exp(lincom)
  }
  res <- lincom
  rownames(res) <- levels(with(mod, model)[, strata_var])
  res <- data.frame(val=as.character(rownames(res)), res)
  res <- rbind(rep("", ncol(res)), res)
  res$Estimate <- as.numeric(res$Estimate)
  res$Lower.CI <- as.numeric(res$Lower.CI)
  res$Upper.CI <- as.numeric(res$Upper.CI)
  
  ## test of interaction terms
  intterms <- paste0(main_var, ":", 
                     strata_var, levels(with(mod, model)[, strata_var]))
  coefindx <- (1:length(coef(mod)))[names(coef(mod)) %in% intterms]
  Chi2 <- aod::wald.test(vcov(mod), coef(mod), Terms=coefindx)$result$chi2
  return(list(estimates=res, Chi2=Chi2))
}
