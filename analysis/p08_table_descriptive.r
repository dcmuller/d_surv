#! p08_table_descriptive.r
## table 1

################################################
## required packages
req <- c("foreign", "Hmisc", "tables")
lapply(req, library, character.only = TRUE)

##############################################
analysis <- read.dta("./data/d00_analysis.dta")
tabdat <- with(analysis, 
               data.frame(Sex=factor(sex, labels=c("Male", "Female")), 
                          Country=factor(country, labels=c("Czech Republic", 
                                                           "Russia", 
                                                           "Romania")), 
                          Diabetes=factor(diabete, labels=c("Yes", "No")),
                          Hypertension=factor(hypertension, labels=c("Yes", "No")),
                          Stage=factor(stage_imputed, labels=c("I", "II", "III", "IV")),
                          Grade=factor(grade),
                          Histology=histo_grp,
                          Smoking=factor(smoke_status,
                                              labels=c("Never smoker",
                                                       "Former smoker",
                                                       "Current smoker")),
                          "Age at recruitment (years)"=cut(age_recruitment, 
                                                           breaks=c(min(age_recruitment, na.rm=TRUE),55,65,max(age_recruitment, na.rm=TRUE)),
                                                           right=FALSE,
                                                           include.lowest=TRUE),
                          "BMI (kg/m$^2$)"=cut(bmi_current,
                                              breaks=c(min(bmi_current, na.rm=TRUE), 
                                                       25, 30, 
                                                       max(bmi_current, na.rm=TRUE)),
                                              right=FALSE,
                                              include.lowest=TRUE),
                          "Season-adjusted circulating 25(OH)D$_3$ category"=factor(d3_q4, labels=c("1 (lowest)", "2", "3", "4 (highest)")), 
                          "Vital status"=factor(vitalstatus, labels=c("alive", "dead")),
                          "Total"="Total",
                          check.names=FALSE))
addlevel <- function(x) factor(x, levels=c(levels(x), "missing"))
tabdat <- data.frame(lapply(tabdat, addlevel), stringsAsFactors=FALSE, check.names=FALSE)
tabdat[is.na(tabdat)] <- "missing"
tabdat <- droplevels(tabdat)
t1 <- tabular(Total + Literal("\\\\ %") + Sex + Literal("\\\\  %") +  
                `Age at recruitment (years)` + Literal("\\\\ %") + 
                Country + Literal("\\\\ %") + `BMI (kg/m$^2$)` + Literal("\\\\ %") +
                Smoking + Literal("\\\\ %") + Diabetes + Literal("\\\\ %") + 
                Hypertension + Literal("\\\\ %") + Stage + Literal("\\\\ %") +
                Grade + Literal("\\\\ %") + Histology + Literal("\\\\ %") + 
                `Season-adjusted circulating 25(OH)D$_3$ category`
              ~ (`Vital status`*((n=1) + 
                                  Paste(Percent("col"), 
                                        digits=0, prefix="(", postfix=")", 
                                        head="(\\%)", justify="r"))
                 + (Total=(n=1))), 
              data=tabdat)
test <- booktabs(latex(t1, booktabs=TRUE, 
                       file="./analysis/output/o08_descriptive_by_vitstat.tex",
                       caption="Demographic characteristics and covariates by vital status"))

latex(tabular(Factor(Smoking) + Literal("\\newline %") + Factor(Sex) ~ Factor(`Vital status`)*((n=1) + 
                                                                 Paste(Percent("col"), 
                                                                       digits=0, prefix="(", postfix=")", 
                                                                       head="(\\%)", justify="r")), 
              data=tabdat, suppressLabels=0))
