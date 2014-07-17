*! p06_relapse.do
*! 20140513 dcmuller
* create table of HR and CI from Cox models for relapse
* free survival, and relapse versus death from competing
* risks models

set more off
clear all
capture log close
log using ./analysis/output/l06_relapse.log, replace
version 12.1
********************************************************
local minadj "i.stage_imputed age_recruitment i.sex"
local adj "`minadj' bmi_current i.smoke_status i.alcohol_status"

// overall
use ./data/d01_relapse_free_stset.dta, clear

mat counts = J(4, 1, .)
forval i=1/4 {
  count if _d==1 & d3_q4==`i'
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
use ./data/d01_relapse_compet_stset.dta, clear

mat counts = J(8, 1, .)
local iter = 1
forval j=1/2 {
  forval i=1/4 {
    count if _d==1 & d3_q4==`i' & fail_strata==`j'
    mat counts[`iter', 1] = r(N)
    local ++iter
  }
}

stcox i.d3_q4##fail_strata `minadj', strata(fail_strata country)
testparm i(2/4).d3_q4#2.fail_strata
local p_interaction = r(p)
nlcom (_b[1.d3_q4]) (_b[2.d3_q4]) (_b[3.d3_q4]) (_b[4.d3_q4]) ///
      (_b[1.d3_q4] + _b[1b.d3_q4#2.fail_strata]) ///
      (_b[2.d3_q4] + _b[2.d3_q4#2.fail_strata]) ///
      (_b[3.d3_q4] + _b[3.d3_q4#2.fail_strata]) ///
      (_b[4.d3_q4] + _b[4.d3_q4#2.fail_strata]) 
mata
b = st_matrix("r(b)")
V = st_matrix("r(V)")
se = sqrt(diagonal(diag(V)))
blu = exp((b', b' - 1.96*se, b' + 1.96*se))
st_matrix("blu", blu)
end
mat list blu
mat res_cr = (counts, blu,  (`p_interaction',.,.,.,.,.,.,.)')

stcox i.d3_q4##fail_strata `adj', strata(fail_strata country)
testparm i(2/4).d3_q4#2.fail_strata
local p_interaction = r(p)
nlcom (_b[1.d3_q4]) (_b[2.d3_q4]) (_b[3.d3_q4]) (_b[4.d3_q4]) ///
      (_b[1.d3_q4] + _b[1b.d3_q4#2.fail_strata]) ///
      (_b[2.d3_q4] + _b[2.d3_q4#2.fail_strata]) ///
      (_b[3.d3_q4] + _b[3.d3_q4#2.fail_strata]) ///
      (_b[4.d3_q4] + _b[4.d3_q4#2.fail_strata]) 
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
replace cause = "Relapse or Death" in 1
replace cause = "\\ Relapse" in 5
replace cause = "\\ Death" in 9
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
keep cause group d e? ci? p?
keep if _n <=12
outsheet using ./analysis/output/o06_hr_table_relapse.csv, c replace
listtex using ./analysis/output/o06_hr_table_relapse.tex, replace rstyle(tabular)
 

