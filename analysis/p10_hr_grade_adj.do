*! p10_hr_grade_adj.do
* create table of HR and CI from Cox models

set more off
clear all
capture log close
log using ./analysis/output/l10_hr_grade_adj.log, replace
version 12.1
********************************************************
local minadj "i.stage_imputed age_recruitment i.sex"
local adj "`minadj' i.grade bmi_current i.smoke_status i.alcohol_status"


// overall
use ./data/d01_cacoh_stset_barlow.dta, clear
gen insample=!missing(stage_imputed, age_recruitment, sex, grade, bmi_current, smoke_qty_day, smoke_status, alc_day, alcohol_status)

mat counts = J(4, 1, .)
forval i=1/4 {
  count if _d==1 & d3_q4==`i' & insample
  mat counts[`i', 1] = r(N)
}

stcox i.d3_q4 `minadj', strata(country)
mat t = r(table)
mat t = t[1..6, 1..4]'
mat t = t[1..4, 1] , t[1..4, 5..6]
estat phtest, d
stcox d3_log2_adj `minadj', strata(country)
test d3_log2_adj
mat t = (t, (r(p),.,.,.)')

mat res = (counts, t)

stcox i.d3_q4 `adj', strata(country)
mat t = r(table)
mat t = t[1..6, 1..4]'
mat t = t[1..4, 1] , t[1..4, 5..6]
estat phtest, d
stcox d3_log2_adj `adj', strata(country)
test d3_log2_adj
mat t = (t, (r(p),.,.,.)')

mat res = (res , t)


// cause specific 
use ./data/d01_cacoh_stset_barlow_specific.dta, clear
gen insample=!missing(stage_imputed, age_recruitment, sex, grade, bmi_current, smoke_qty_day, smoke_status, alc_day, alcohol_status)

mat counts = J(8, 1, .)
local iter = 1
forval j=1/2 {
  forval i=1/4 {
    count if _d==1 & d3_q4==`i' & death_strata==`j' & insample
    mat counts[`iter', 1] = r(N)
    local ++iter
  }
}

stcox i.d3_q4##death_strata `minadj', strata(death_strata country)
testparm i(2/4).d3_q4#2.death_strata
local p_interaction = r(p)
nlcom (_b[1.d3_q4]) (_b[2.d3_q4]) (_b[3.d3_q4]) (_b[4.d3_q4]) ///
      (_b[1.d3_q4] + _b[1b.d3_q4#2.death_strata]) ///
      (_b[2.d3_q4] + _b[2.d3_q4#2.death_strata]) ///
      (_b[3.d3_q4] + _b[3.d3_q4#2.death_strata]) ///
      (_b[4.d3_q4] + _b[4.d3_q4#2.death_strata]) 
mata
b = st_matrix("r(b)")
V = st_matrix("r(V)")
se = sqrt(diagonal(diag(V)))
blu = exp((b', b' - 1.96*se, b' + 1.96*se))
st_matrix("blu", blu)
end
mat list blu
mat res_cr = (counts, blu,  (`p_interaction',.,.,.,.,.,.,.)')

stcox i.d3_q4##death_strata `adj', strata(death_strata country)
testparm i(2/4).d3_q4#2.death_strata
local p_interaction = r(p)
nlcom (_b[1.d3_q4]) (_b[2.d3_q4]) (_b[3.d3_q4]) (_b[4.d3_q4]) ///
      (_b[1.d3_q4] + _b[1b.d3_q4#2.death_strata]) ///
      (_b[2.d3_q4] + _b[2.d3_q4#2.death_strata]) ///
      (_b[3.d3_q4] + _b[3.d3_q4#2.death_strata]) ///
      (_b[4.d3_q4] + _b[4.d3_q4#2.death_strata]) 
mata
b = st_matrix("r(b)")
V = st_matrix("r(V)")
se = sqrt(diagonal(diag(V)))
blu = exp((b', b' - 1.96*se, b' + 1.96*se))
st_matrix("blu", blu)
end
mat list blu
mat res_cr = (res_cr, blu,  (`p_interaction',.,.,.,.,.,.,.)')

mat tab = (res \ res_cr)

// format and output table
keep d3_q4
gen cause = ""
replace cause = "all cause" in 1
replace cause = "\\ RCC" in 5
replace cause = "\\ non-RCC" in 9
gen group=cond(mod(_n,4)==0, 4, mod(_n,4)) 

// Paul prefers quartile numbers rather than ranges of values for labels
// comment out labelling
*lab val group l_d3_q4

svmat tab

gen d = string(tab1) 
gen e1 = string(tab2, "%4.2f") 
gen ci1 = "[" + string(tab3, "%4.2f") + ", " + string(tab4, "%4.2f") + "]"
gen p1 = string(tab5, "%9.2g")
gen e2 = string(tab6, "%4.2f") 
gen ci2 = "[" + string(tab7, "%4.2f") + ", " + string(tab8, "%4.2f") + "]"
gen p2 = string(tab9, "%9.2g")

foreach v of varlist e? {
    replace `v' = "1.00" if group == 1
}
foreach v of varlist ci? {
    replace `v' = "" if group == 1
}
foreach v of varlist p? {
    replace `v' = "" if `v' == "."
    replace `v' = `v' + "$^*$" if _n==1
    replace `v' = `v' + "$^\S$" if _n==5
}
keep cause group d e2 ci2 p2
keep if _n<=12
outsheet using ./analysis/output/o10_hr_grade_adj.csv, c replace
listtex using ./analysis/output/o10_hr_grade_adj.tex, replace rstyle(tabular)
 
