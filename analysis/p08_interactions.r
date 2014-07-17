#! p08_interactions.r
#! 20140514 dcmuller
## Interactions with log(b6)

################################################
## required packages
req <- c("survival", "ggplot2", "foreign", "Hmisc", "Cairo", "gridExtra", "plyr", 
         "lmtest", "gmodels", "extrafont")
lapply(req, library, character.only = TRUE)

## source interacted.r to create linear combinations
source("./analysis/r-utils/interacted.r")

## source forest_interactions.r for drawing the figure
source("./analysis/r-utils/forest_interactions.r")


## read data from Stata
analysis <- read.dta("data/d01_cacoh_stset_barlow.dta", convert.underscore=TRUE)

## generate neccesary categorical variables
analysis$sex <- factor(analysis$sex, labels=c("Male", "Female")) 
analysis$country <- factor(analysis$country, labels=c("Czech Republic", 
                                                      "Russia", 
                                                      "Romania"))
analysis$diabetic <- factor(analysis$diabete, labels=c("Yes", "No"))
analysis$hypertension <- factor(analysis$hypertension, labels=c("Yes", "No"))
analysis$stage <- factor(analysis$stage.imputed, labels=c("I", "II", "III", "IV"))
analysis$smoking <- factor(analysis$smoke.status,labels=c("Never",
                                                          "Former",
                                                          "Current"))
analysis$alcohol <- factor(analysis$alcohol.status, 
                           levels=0:2, 
                           labels=c("Never", "Former", "Current"))
analysis$age <- cut(analysis$age.recruitment, 
                    breaks=c(min(analysis$age.recruitment, na.rm=TRUE),
                             55,65,75,
                             max(analysis$age.recruitment, na.rm=TRUE)),
                    right=FALSE,
                    include.lowest=TRUE)
analysis$bmi <- cut(analysis$bmi.current,
                  breaks=c(min(analysis$bmi.current, na.rm=TRUE), 
                           25, 30, 
                           max(analysis$bmi.current, na.rm=TRUE)),
                  right=FALSE,
                  include.lowest=TRUE)
analysis$hist <- analysis$histo.grp2


## short name for log2 b6
analysis$b6 <- analysis$b6.log2


## model without interactions
noint <- coxph(Surv(time=.t0, time2=.t, event=.d) ~ b6 + 
                 age.recruitment + sex + stage + strata(country), 
               data=analysis, weights=wgt.stratified, robust=TRUE, model=TRUE)
summary(noint)
b_b6 <- coef(noint)["b6"]
se_b6 <- sqrt(vcov(noint)["b6","b6"])
est_overall <- data.frame(b_b6, b_b6 - 1.96*se_b6, b_b6 + 1.96*se_b6)
colnames(est_overall) <- c("Estimate", "Lower.CI", "Upper.CI")
est_overall <- exp(est_overall)
est_overall <- data.frame(val="", as.matrix(est_overall))
rownames(est_overall) <- c("")
name_overall <- "Overall"

## sex
sex <- coxph(Surv(time=.t0, time2=.t, event=.d) ~ b6*sex + 
               age.recruitment + stage + strata(country), 
             data=analysis, weights=wgt.stratified, robust=TRUE, model=TRUE)
summary(sex)
est_sex_full <- interacted(mod=sex, main_var="b6", strata_var="sex")
est_sex <- est_sex_full$estimates
name_sex<- vector(mode = "character", length = nrow(est_sex))
name_sex[1] <- paste0("Sex, p = ", 
                      format.pval(pv = est_sex_full$Chi2["P"], 
                                  digits = 2, eps = 0.01)) 

## age
age <- coxph(Surv(time=.t0, time2=.t, event=.d) ~ b6*age +
               age.recruitment + stage + sex + strata(country), 
             data=analysis, weights=wgt.stratified, robust=TRUE, model=TRUE)
summary(age)
est_age_full <- interacted(mod=age, main_var="b6", strata_var="age")
est_age <- est_age_full$estimates
name_age <- vector(mode = "character", length = nrow(est_age))
name_age[1] <- paste0("Age, p = ", 
                      format.pval(pv = est_age_full$Chi2["P"], 
                                  digits = 2, eps = 0.01)) 
## country (dropping romania from the analysis)
country <- coxph(Surv(time=.t0, time2=.t, event=.d) ~ b6*country +
                   age.recruitment + stage + sex, 
                 data=droplevels(analysis[analysis$country!="Romania",]), weights=wgt.stratified, robust=TRUE, model=TRUE)
summary(country)
est_country_full <- interacted(mod=country, main_var="b6", strata_var="country")
est_country <- est_country_full$estimates
name_country <- vector(mode = "character", length = nrow(est_country))
name_country[1] <- paste0("Country, p = ", 
                      format.pval(pv = est_country_full$Chi2["P"], 
                                  digits = 2, eps = 0.01)) 

## stage
stage <- coxph(Surv(time=.t0, time2=.t, event=.d) ~ b6*stage +
               age.recruitment + stage + sex + strata(country), 
             data=analysis, weights=wgt.stratified, robust=TRUE, model=TRUE)
summary(stage)
est_stage_full <- interacted(mod=stage, main_var="b6", strata_var="stage")
est_stage <- est_stage_full$estimates
name_stage <- vector(mode = "character", length = nrow(est_stage))
name_stage[1] <- paste0("Stage, p = ", 
                      format.pval(pv = est_stage_full$Chi2["P"], 
                                  digits = 2, eps = 0.01)) 
## hist
hist <- coxph(Surv(time=.t0, time2=.t, event=.d) ~ b6*hist +
                age.recruitment + stage + sex + strata(country), 
              data=analysis, weights=wgt.stratified, robust=TRUE, model=TRUE)
summary(hist)
est_hist_full <- interacted(mod=hist, main_var="b6", strata_var="hist")
est_hist <- est_hist_full$estimates
name_hist <- vector(mode = "character", length = nrow(est_hist))
name_hist[1] <- paste0("Histology, p = ", 
                      format.pval(pv = est_hist_full$Chi2["P"], 
                                  digits = 2, eps = 0.01)) 

## diabetes
diab <- coxph(Surv(time=.t0, time2=.t, event=.d) ~ b6*diabetic +
               age.recruitment + stage + sex + strata(country), 
             data=analysis, weights=wgt.stratified, robust=TRUE, model=TRUE)
summary(diab)
est_diab_full <- interacted(mod=diab, main_var="b6", strata_var="diabetic")
est_diab <- est_diab_full$estimates
name_diab <- vector(mode = "character", length = nrow(est_diab))
name_diab[1] <- paste0("Diabetes, p = ", 
                      format.pval(pv = est_diab_full$Chi2["P"], 
                                  digits = 2, eps = 0.01)) 

## hypertension
hyp <- coxph(Surv(time=.t0, time2=.t, event=.d) ~ b6*hypertension +
               age.recruitment + stage + sex + strata(country), 
             data=analysis, weights=wgt.stratified, robust=TRUE, model=TRUE)
summary(hyp)
est_hyp_full <- interacted(mod=hyp, main_var="b6", strata_var="hypertension")
est_hyp <- est_hyp_full$estimates
name_hyp <- vector(mode = "character", length = nrow(est_hyp))
name_hyp[1] <- paste0("Hypertension, p = ", 
                      format.pval(pv = est_hyp_full$Chi2["P"], 
                                  digits = 2, eps = 0.01)) 

## BMI
bmi <- coxph(Surv(time=.t0, time2=.t, event=.d) ~ b6*bmi +
               age.recruitment + stage + sex + strata(country), 
             data=analysis, weights=wgt.stratified, robust=TRUE, model=TRUE)
summary(bmi)
est_bmi_full <- interacted(mod=bmi, main_var="b6", strata_var="bmi")
est_bmi <- est_bmi_full$estimates
name_bmi <- vector(mode = "character", length = nrow(est_bmi))
name_bmi[1] <- paste0("BMI, p = ", 
                      format.pval(pv = est_bmi_full$Chi2["P"], 
                                  digits = 2, eps = 0.01)) 

## smoking
smk <- coxph(Surv(time=.t0, time2=.t, event=.d) ~ b6*smoking +
               age.recruitment + stage + sex + strata(country), 
             data=analysis, weights=wgt.stratified, robust=TRUE, model=TRUE)
summary(smk)
est_smk_full <- interacted(mod=smk, main_var="b6", strata_var="smoking")
est_smk <- est_smk_full$estimates
name_smk <- vector(mode = "character", length = nrow(est_smk))
name_smk[1] <- paste0("Smoking status, p = ", 
                      format.pval(pv = est_smk_full$Chi2["P"], 
                                  digits = 2, eps = 0.01)) 
## smoking
alc <- coxph(Surv(time=.t0, time2=.t, event=.d) ~ b6*alcohol +
               age.recruitment + stage + sex + strata(country), 
             data=analysis, weights=wgt.stratified, robust=TRUE, model=TRUE)
summary(alc)
est_alc_full <- interacted(mod=alc, main_var="b6", strata_var="alcohol")
est_alc <- est_alc_full$estimates
name_alc <- vector(mode = "character", length = nrow(est_alc))
name_alc [1] <- paste0("Alcohol drinking status, p = ", 
                      format.pval(pv = est_alc_full$Chi2["P"], 
                                  digits = 2, eps = 0.01)) 



res <- rbind(est_overall, est_country, est_age, est_sex, est_stage, est_hist, est_diab, est_hyp, est_smk, est_alc, est_bmi)
names <- c(name_overall, name_country, name_age, name_sex, name_stage, name_hist, name_diab, name_hyp, name_smk, name_alc, name_bmi)
res <- data.frame(index=seq(length(names), 1, -1), 
                  names = names, 
                  res)
rownames(res) <- NULL

CairoFonts(regular    = "Palatino:style=Regular", 
           bold       = "Palatino:style=Bold", 
           italic     = "Palatino:style=Italic",
           bolditalic = "Palatino:style=Bold Italic,BoldItalic",
           symbol     = "Symbol")
CairoPDF(file="./analysis/output/g08_interactions.pdf", 
         width=8.2, 
         height=8.5, 
         pointsize=5)
plot <- gg_eclplot(results = res,  
                   est_colnames = c("Estimate", "Lower.CI", "Upper.CI"),
                   mindecimals = 2,
                   x_title = "Hazard ratio [95% CI]",
                   x_breaks = c(0.25, 0.5, 0.75, 1),
                   x_lim = c(0.25, 1.25),
                   table_width = .56,
                   header = TRUE,
                   headings = c("", "", "HR [95% CI]"))
dev.off()

