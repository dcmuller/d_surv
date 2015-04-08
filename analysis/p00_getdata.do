*! p00_getdata.do
*! 20140408 dcmuller
* get raw data from various files

set more off
clear
cap log close
log using ./analysis/output/l00_getdata.log, replace
version 12.1

*********************************************
// sample shipment and storage details

insheet using ./data/Kidney_VitaminB_forshipmenttoBevital_13Jan2014.csv, comma
rename subject_id id

** For some people two aliquots of 200 microlitres were sent rather than
** one of 400 microlitres. The storage for each of the two samples was
** identical, and they were shipped adjacent to one another, so we can just
** keep the first observation.
bys id (sample_aliquot) : keep if _n==1
tempfile storage
save `storage'

clear

*********************************************
// data from bevital

insheet using ./data/ResultsB6andVitD_bevital.csv, comma

tempfile bevital
save `bevital'

clear

*********************************************
// main case-cohort dataset

insheet using ./data/k2survivaldata_23apr2014.csv, c names


** center is available as a string variable in the storage dataset
** drop this numeric version
drop center

rename country_recruitment country

** convert date variables
gen long interview_dte = date(date_interview, "MDY")
format interview_dte %td
list interview_dte date_interview in 1/5

gen long recr_dte = date(date_recruitment, "MDY")
format recr_dte %td
list recr_dte date_recruitment in 1/5

gen long surg_dte = date(date_surgery, "MDY")
format surg_dte %td
list surg_dte date_surgery in 1/5

gen long lastfup_dte = date(date_lastinfo_vitalstatus, "MDY")
format lastfup_dte %td
list lastfup_dte date_lastinfo_vitalstatus in 1/5

** replapse date appears to be a SAS numeric daily date (same as Stata)
** (need to check with Ghislaine)
rename relapse_date relapse_dte 
format relapse_dte %td
preserve
sort relapse_dte
list relapse_dte in 1/5
restore

save data/k2survivaldata_23apr2014.dta, replace
clear


*********************************************
// merge 
use `bevital'
merge 1:1 id using `storage'
assert _merge==3
drop _merge
merge 1:1 id using data/k2survivaldata_23apr2014.dta
assert _merge==3
drop _merge

**********************************************
// manipulate

** set 9 to missing where necessary
recode stage 9=.
recode grade 9=.

// label histological type
gen histo_grp = histotype
recode histo_grp (4/8 = 4)  
lab define l_histo_grp  1 "Conventional RCC" ///
                        2 "Papillary RCC" ///
                        3 "Chromophobe RCC" ///
                        4 "Other" ///
                        9 "Unknown"
lab val histo_grp l_histo_grp

gen histo_grp3 = histotype
recode histo_grp3 (3/9 = 3)
lab define l_histo_grp3 1 "Conventional RCC" ///
                        2 "Papillary RCC" ///
                        3 "Other/Unknown"
lab val histo_grp3 l_histo_grp3

gen histo_grp2 = histotype
recode histo_grp2 (2/9 = 2)
lab define l_histo_grp2 1 "Conventional" ///
                        2 "Other/Unknown"
lab val histo_grp2 l_histo_grp2


** vitamins
lab var plp_d "vitamin B6 [nmol/L]"
lab var vd2_h "vitamin D2 [nmol/L]"
lab var vd3_h "vitamin D3 [nmol/L]"

gen b6_log2 = log(plp_d)/log(2)
gen d2_log2 = log(vd2_h)/log(2)
gen d3_log2 = log(vd3_h)/log(2)

su plp_d if subcohort==1, d
local qmin = round(r(min), 0.01)
local q25 = round(r(p25), 0.01)
local q50 = round(r(p50), 0.01)
local q75 = round(r(p75), 0.01)
local qmax = round(r(max), 0.01)
gen b6_q4=.
recode b6_q4 .=1 if plp_d < `q25'
recode b6_q4 .=2 if plp_d < `q50'
recode b6_q4 .=3 if plp_d < `q75'
recode b6_q4 .=4 if plp_d < . 
lab def l_b6_q4 1 "1 [`qmin',`q25')" ///
                2 "2 [`q25',`q50')" ///
                3 "3 [`q50',`q75')" ///
                4 "4 [`q75',`qmax']"
lab val b6_q4 l_b6_q4


** vitamin d adjusted for season
gen recr_day = doy(recr_dte)
gen double recr_day_unit = recr_day/365
forval i = 1(1)4 {
        gen double sin`i'_recr_day = sin(`i' * 2 * _pi * recr_day_unit)
        gen double cos`i'_recr_day = cos(`i' * 2 * _pi * recr_day_unit)
        lab var sin`i'_recr_day "seasonality"
        lab var cos`i'_recr_day "seasonality"
}
reg d3_log2 sin1_recr_day cos1_recr_day if subcohort==1
predict xb1
reg d3_log2 sin1_recr_day cos1_recr_day ///
            sin2_recr_day cos2_recr_day if subcohort==1
predict xb2
reg d3_log2 sin1_recr_day cos1_recr_day ///
            sin2_recr_day cos2_recr_day ///
            sin3_recr_day cos3_recr_day if subcohort==1
predict xb3
reg d3_log2 sin1_recr_day cos1_recr_day ///
            sin2_recr_day cos2_recr_day ///
            sin3_recr_day cos3_recr_day ///
            sin4_recr_day cos4_recr_day if subcohort==1
predict xb4
tw (scatter d3_log2 recr_day, msymbol(oh)) (line xb? recr_day, sort)

** looks like one pair is sufficient, generate "adjusted" concentration by
** subtracting the model prediction (seasonal mean)
gen d3_log2_adj = d3_log2 - xb1

** cut into fourths
su d3_log2_adj if subcohort==1, d
local qmin = round(r(min), 0.01)
local q25 = round(r(p25), 0.01)
local q50 = round(r(p50), 0.01)
local q75 = round(r(p75), 0.01)
local qmax = round(r(max), 0.01)
gen d3_q4=.
recode d3_q4 .=1 if d3_log2_adj < `q25'
recode d3_q4 .=2 if d3_log2_adj < `q50'
recode d3_q4 .=3 if d3_log2_adj < `q75'
recode d3_q4 .=4 if d3_log2_adj < . 

**************************************************
// Save

save ./data/d00_analysis.dta, replace
log close
exit
