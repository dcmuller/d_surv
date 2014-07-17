*! p04_survpred.do
*! 20140430 dcmuller
* create table of HR and CI from Cox models

set more off
clear all
capture log close
log using ./analysis/output/l04_survpred.log, replace
version 12.1
********************************************************
use ./data/d01_cacoh_stset_barlow.dta, clear

// fit model, look at different number of degrees of freedom for baseline
stpm2 i.b6_q4 i.stage_imputed age_recruitment, scale(hazard) df(2)
stpm2 i.b6_q4 i.stage_imputed age_recruitment, scale(hazard) df(3)
stpm2 i.b6_q4 i.stage_imputed age_recruitment, scale(hazard) df(4)
stpm2 i.b6_q4 i.stage_imputed age_recruitment, scale(hazard) df(5)

// looks like 3 df is sufficient
stpm2 i.b6_q4 i.stage_imputed age_recruitment, scale(hazard) df(3)

// create new data for predictions
keep b6_q4
drop if _n>0
range _t 0 5 101
expand 4
bys _t: gen stage_imputed = _n
expand 4
bys _t stage_imputed: replace b6_q4 = _n
sort stage_imputed b6_q4 _t
gen _d = .
gen _t0 = .
gen age_recruitment = 60
predict surv, surv ci timevar(_t)

rename _t time
rename stage_imputed stage

list b6_q4 time stage surv* if time==2
list b6_q4 time stage surv* if time==5

keep time stage b6_q4 surv*
outsheet using ./analysis/output/o04_survpred_b6_stage.csv, c replace
save ./analysis/output/o04_survpred_b6_stage.dta, replace

***************************************************
log close


