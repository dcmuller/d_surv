*! p01_stset.do
*! 20140409 dcmuller
* set as survival data and calculate sampling weights

set more off
clear all
capture log close
log using ./analysis/output/l01_stset.log, replace
version 12.1
************************************************
use ./data/d00_analysis.dta

************************************************
preserve
keep if subcohort==1
stset lastfup_dte, origin(recr_dte) fail(vitalstatus==1) scale(365.24)
save ./data/d01_subcoh_stset.dta, replace
restore

// relapse free survival (just the subcohort)
// -- treat failure as relapse or death, whichever occurs first
// -- subcohort only (there will be relapseses outside the subcohort
//    that we did not ascertain
// -- exclude stage 4 (metastatic, so can't "relapse")
preserve
keep if subcohort==1
keep if stage_imputed != 4
gen relapsed = relapse==1
count if relapsed
count if relapsed & missing(relapse_dte)
** two people relapsed but missing relapse date, exlcude them
list id if relapsed & missing(relapse_dte)
drop if relapsed & missing(relapse_dte)
list id relapse_dte lastfup_dte if relapse_dte>=lastfup_dte & relapse_dte<.
** one person has relapse date after end of follow up for death. 
** censor at endfup
replace relapsed=0 if relapse_dte>lastfup_dte & relapse_dte<.

gen failed = (vitalstatus==1 | relapsed==1)
gen endfup_relapse = min(lastfup_dte, relapse_dte)
stset endfup_relapse, origin(recr_dte) fail(failed==1) scale(365.24)
save ./data/d01_relapse_free_stset.dta, replace

drop _d _st _t _t0 

// relapse versus death as competing risk
gen fail_type = failed
recode fail_type 1=2 if relapsed != 1 // deaths (i.e., not relapsed) coded as 2
tab fail_type
expand 2, gen(fail_strata)
replace fail_strata = fail_strata + 1
lab def fail_strata_l 1 "relapse" 2 "death"
lab val fail_strata fail_strata_l 
gen case_status = (fail_strata==fail_type) & failed==1
stset endfup_relapse, origin(recr_dte) fail(case_status)

save ./data/d01_relapse_compet_stset.dta, replace
restore

************************************************
// calculate weights for the denominator of the likelihood (Barlow method)
// - reciprocal of sampling fraction for subcohort non-cases
// - reciprocal of sampling fraction for subcohort cases prior to failure
// - 0 for non subcohort cases prior to failure
// - 1 for cases (in or out of subcohort) at time of failure.
//
// "Full cohort" of 1188 eligible (see documentation of selection procedure)
// stratify by stage 4 (n=164) versus stage < 4 (n=1024)
// in subcohort: stage 4 (n=164), not stage 4 (n=416)
// ** N.B., these counts (and thus the weights) have changed slightly from
// ** the preliminary analysis, as we are now using imputed stage and there
// ** are a few more stage 4 cases
gen double wgt_stratified = .
replace wgt_stratified = 1 if stage_imputed==4
replace wgt_stratified = 1024/416 if subcohort==1 & stage_imputed!=4
replace wgt_stratified = 0 if vitalstatus==1 & subcohort==0 & stage_imputed!=4

// not stratified by stage
gen double wgt_simple = .
replace wgt_simple = 0 if vitalstatus==1 & subcohort==0
replace wgt_simple = 1188/500 if subcohort==1

// stset without weights
stset lastfup_dte, ///
  origin(recr_dte) ///
  id(id) ///
  fail(vitalstatus==1) ///
  scale(365.24)

// rename stset vars and split time for failures
rename _d failed
rename _t0 ent
rename _t ext
drop _st
expand 2 if failed==1
sort id
by id: gen tsplit=_n
bys id: replace tsplit=0 if _N==1
bys id : replace ext=ext-0.01 if tsplit==1
recode failed 1=0 if tsplit==1
bys id (tsplit): replace ent=ext[_n-1] if tsplit==2
replace wgt_stratified = 1 if tsplit ==2 & failed==1
tab vitalstatus subcohort 
replace wgt_simple  = 1 if tsplit ==2 & failed==1

// check that the stset gives the same characteristics with time-split data
stset ext, id(id) enter(ent) fail(failed==1)
** looks good!

// stset without id variable so that we can use weights that are not
// constant within person
drop _st _d _t _t0
stset ext [pw=wgt_stratified], enter(ent) fail(failed==1)

save ./data/d01_cacoh_stset_barlow.dta, replace


// Cause-specific mortality, competing risks. A little tricky
// due to the time split data
gen kidn_death=vitalstatus 
recode kidn_death 1=2 if cause_death !=1
tab kidn_death, m
expand 2, gen(death_strata)
replace death_strata = death_strata + 1
lab def death_strata_l 1 "kidney" 2 "other"
lab val death_strata death_strata_l 
gen case_status = (death_strata==kidn_death) & failed==1
drop _st _d _t _t0
stset ext [pw=wgt_stratified], enter(ent) fail(case_status)

save ./data/d01_cacoh_stset_barlow_specific.dta, replace



**************************************
log close
exit
