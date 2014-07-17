*! p02_eda.do
*! 20140409 dcmuller
* set as survival data and calculate sampling weights

set more off
clear all
capture log close
log using ./analysis/output/l02_eda.log, replace
version 12.1
********************************************************
use ./data/d01_cacoh_stset_barlow.dta, clear

// unadjusted
stcox b6_log2, strata(country)
stcox i.b6_q4, strata(country)

// unadjusted, missing stage removed
stcox b6_log2 if stage < ., strata(country)
stcox i.b6_q4 if stage < ., strata(country)

// adjusted by stage
stcox b6_log2 i.stage, strata(country)
stcox i.b6_q4 i.stage, strata(country)

// interacted with stage
stcox c.b6_log2##i.stage, strata(country)
lincom b6_log2 + 1.stage#c.b6_log2, eform
lincom b6_log2 + 2.stage#c.b6_log2, eform
lincom b6_log2 + 3.stage#c.b6_log2, eform 
lincom b6_log2 + 4.stage#c.b6_log2, eform
stcox i.b6_q4##i.stage, strata(country)

// adjusted by stage and grade
stcox b6_log2 i.stage i.grade, strata(country)
stcox i.b6_q4 i.stage i.grade, strata(country)

log close
