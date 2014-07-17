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
stpm2 i.d3_q4 i.stage_imputed age_recruitment, scale(hazard) df(2)
stpm2 i.d3_q4 i.stage_imputed age_recruitment, scale(hazard) df(3)
stpm2 i.d3_q4 i.stage_imputed age_recruitment, scale(hazard) df(4)
stpm2 i.d3_q4 i.stage_imputed age_recruitment, scale(hazard) df(5)

// looks like 3 df is sufficient

// interaction with stage
gen stage3 = stage_imputed-1
replace stage3 = stage_imputed if stage_imputed==1
stpm2 i.d3_q4##i.stage3 age_recruitment, scale(hazard) df(3)

// create new data for predictions
keep d3_q4
drop if _n>0
range _t 0 5 101
expand 3
bys _t: gen stage3 = _n
expand 4
bys _t stage3: replace d3_q4 = _n
sort stage3 d3_q4 _t
gen _d = .
gen _t0 = .
gen age_recruitment = 60
predict surv, surv ci timevar(_t)

rename _t time
rename stage3 stage

list d3_q4 time stage surv* if time==2
list d3_q4 time stage surv* if time==5

keep time stage d3_q4 surv*
outsheet using ./analysis/output/o04_survpred_d3_stage.csv, c replace
save ./analysis/output/o04_survpred_d3_stage.dta, replace

***************************************************
log close


