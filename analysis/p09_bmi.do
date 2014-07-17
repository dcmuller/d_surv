*! p09_bmi.do
*! 20140521 dcmuller
* Cox models for BMI

set more off
clear all
capture log close
log using ./analysis/output/l09_bmi.log, replace
version 12.1
********************************************************

use ./data/d01_cacoh_stset_barlow.dta, clear

gen bmi_g3 = 1 if bmi_current < 25
recode bmi_g3 .=2 if bmi_current < 30
recode bmi_g3 .=3 if bmi_current < .

stcox i.bmi_g3 i.sex age_recruitment  
stcox i.bmi_g3 i.sex age_recruitment i.stage_imputed  
stcox i.bmi_g3 i.sex age_recruitment i.stage_imputed i.d3_q4

log close
