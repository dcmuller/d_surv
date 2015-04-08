#! p11_in_vs_out.r
## Compare characteristics of those selected into
## the sample with those not selected

################################################
## required packages
req <- c("haven", "foreign", "Hmisc", "tables")
lapply(req, library, character.only = TRUE)
rm(req)

################################################
## load full cohort data
fulldat <- haven::read_sas("./data/full_cohort_25mar2015.sas7bdat")
names(fulldat) <- tolower(names(fulldat))

## load eligible cohort data
elgbldat <- haven::read_sas("./data/eligible_cohort_28oct2013.sas7bdat")
elgbl_ids <- elgbldat$id
rm(elgbldat)

## load case-cohort data
cacoh_dat <- read_dta("./data/k2survivaldata_23apr2014.dta") 
names(cacoh_dat) <- tolower(names(cacoh_dat))
cacoh_dat$eligible <- 1
length(intersect(names(cacoh_dat),names(fulldat)))
cacoh_dat$country <- factor(cacoh_dat$country, levels=1:4,
                            labels = c("Czech", "Romani", "Russia", "Serbia"))
fulldat$country <- factor(fulldat$country)


## make sure that common variables are all the correct class
cacoh_dat$date_surgery <- cacoh_dat$surg_dte
cacoh_dat$date_lastinfo_vitalstatus <- cacoh_dat$lastfup_dte
cacoh_dat$date_interview <- cacoh_dat$interview_dte
cacoh_dat$date_recruitment <- cacoh_dat$recr_dte
cacoh_dat$dob <- NULL

# cacoh_dat$renalfailure <- NULL
# cacoh_dat$othercancer <- NULL
# cacoh_dat$kidneycancer <- NULL
# cacoh_dat$kidneychronic <- NULL
# cacoh_dat$lungmeta <- NULL
# cacoh_dat$brainmeta <- NULL
# cacoh_dat$bonemeta <- NULL
# cacoh_dat$othermeta<- NULL
# cacoh_dat$othermeta_txt<- NULL
# cacoh_dat$livermeta <- NULL
# 
# cacoh_dat$pstage <- NULL
# cacoh_dat$stage_imputed <- NULL
# cacoh_dat$surgery_type <- NULL 
# 
# cacoh_dat$ttt_hypertension <- NULL
# fulldat$ttt_hypertension <- NULL
# 
# cacoh_dat$alcohol_dur <- NULL
# fulldat$alcohol_dur <- NULL
# 
# cacoh_dat$smoke_dur <- NULL
# fulldat$smoke_dur <- NULL
# 
# cacoh_dat$educ_level <- NULL
# fulldat$educ_level <- NULL

## merge on all common variables
common <- intersect(names(fulldat), names(cacoh_dat))

fulldat_restr <- fulldat[, common]
merged <- merge(cacoh_dat, fulldat_restr, all = TRUE, by="id")
(inboth <- intersect(names(fulldat), names(cacoh_dat)))
(ninmerged <- setdiff(names(cacoh_dat), names(merged)))
merged$insample <- merged$id %in% cacoh_dat$id
table(merged$insample)

## use the value from the case-cohort dataset, otherwise use the value from the
## full cohort dataset
dupvars <- merged[, c("id", paste0(ninmerged, ".x"), paste0(ninmerged, ".y")),] 
newvars <- data.frame(matrix(data=NA, nrow=nrow(merged), ncol=length(ninmerged)))
colnames(newvars) <- ninmerged
for (i in 1:length(ninmerged)) {
  newvars[,i] <- ifelse(merged$insample, 
                        merged[, paste0(ninmerged[i], ".x")],
                        merged[, paste0(ninmerged[i], ".y")])
  merged[, paste0(ninmerged[i], ".x")] <- NULL
  merged[, paste0(ninmerged[i], ".y")] <- NULL
}
merged <- cbind(merged, newvars)

## replace age_recruitment=ageint for those not in the subcohort
merged$age_recruitment <- ifelse(merged$insample, 
                                 merged$age_recruitment,
                                 merged$ageint)

## flag those that were eligible for the case-cohort selection
merged$eligible <- merged$id %in% elgbl_ids

## create table
tabdat <- with(merged, 
               data.frame(Sex=factor(sex, labels=c("Male", "Female")), 
                          Country=factor(country, levels=1:4,
                          labels = c("Czech", "Romani", "Russia", "Serbia")),               
                          Diabetes=factor(diabete, levels=c(1,2),labels=c("Yes", "No")),
                          Hypertension=factor(hypertension, levels=c(1,2), labels=c("Yes", "No")),
                          Stage=factor(stage_imputed, levels=1:4, labels=c("I", "II", "III", "IV")),
                          Grade=factor(grade),
                          Smoking=factor(smoke_status,
                                         levels=0:2,
                                         labels=c("Never smoker",
                                                  "Former smoker",
                                                  "Current smoker")),
                          "Age at recruitment (years)"=cut(age_recruitment, 
                                                           breaks=c(min(age_recruitment, na.rm=TRUE),55,65,max(age_recruitment, na.rm=TRUE)),
                                                           right=FALSE,
                                                           include.lowest=TRUE),
                          "BMI (kg/m$^2$)"=cut(as.numeric(bmi_current),
                                              breaks=c(min(as.numeric(bmi_current), na.rm=TRUE), 
                                                       25, 30, 
                                                       max(as.numeric(bmi_current), na.rm=TRUE)),
                                              right=FALSE,
                                              include.lowest=TRUE),
                          "Included in study"=factor(insample, labels=c("No", "Yes")),
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
                Hypertension 
              ~ (`Included in study`*((n=1) + 
                                  Paste(Percent("col"), 
                                        digits=0, prefix="(", postfix=")", 
                                        head="(\\%)", justify="r"))), 
              data=tabdat)
test <- booktabs(latex(t1, booktabs=TRUE, 
                       file="./analysis/output/o11_descriptive_by_insample.tex",
                       caption="Demographic characteristics and covariates for those included and not included in the present study"))


with(merged, table(country, eligible))
with(merged, table(country, insample))
