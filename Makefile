# date-time for auto updating program files
dt := $(shell date +"%Y-%m-%d %T")


rutils	 = $(wildcard ./analysis/r-utils/*)
programs = $(wildcard ./analysis/*) 
output 	 = $(wildcard ./analysis/output/*)
data	 = $(wildcard ./data/source/*) $(wildcard ./data/derived/*)
derived  = $(wildcard ./data/derived/*)
text	 = $(wildcard ./text/*)

# run this program first (after clean and initialisation
runfirst := $(wildcard analysis/p00*)
runfirstcmd = stata-se -b

# default updates entire analysis
last_run : $(text) $(programs) $(output) $(data) $(rutils) 
	-rm *.log
	-rm *.Rout
	-rm Rplots.pdf
	echo $(dt) > last_run

.PHONY : first
first :
	$(runfirstcmd) $(runfirst)


# program files depend on datasets, and occasionally local r-tools
analysis/p00_getdata.do : ./data/Kidney_VitaminB_forshipmenttoBevital_13Jan2014.csv \
	           	  ./data/ResultsB6andVitD_bevital.csv \
			  ./data/k2survivaldata_23apr2014.csv 	
	touch $@
	stata-se -b $@
	
analysis/p01_stset.do : ./data/d00_analysis.dta
	touch $@
	stata-se -b $@
	
analysis/p02_eda.do : ./data/d01_cacoh_stset_barlow.dta
	touch $@
	stata-se -b $@

analysis/p03_hr_table.do : ./data/d01_cacoh_stset_barlow.dta \
			   ./data/d01_cacoh_stset_barlow_specific.dta
	touch $@
	stata-se -b $@

analysis/p05_survpred.do : ./data/d01_cacoh_stset_barlow.dta 
	touch $@
	stata-se -b $@

analysis/p06_plot_survival.r : ./analysis/output/o05_survpred_d3_stage.csv
	touch $@
	R CMD BATCH --no-save --no-restore $@

analysis/p07_relapse.do : ./data/d01_relapse_free_stset.dta \
  			  ./data/d01_relapse_compet_stset.dta	
	touch $@
	stata-se -b $@

analysis/p08_table_descriptive.r : ./data/d00_analysis.dta
	touch $@
	R CMD BATCH --no-save --no-restore $@

analysis/p09_interactions.r : ./data/d01_cacoh_stset_barlow.dta \
  			      ./analysis/r-utils/forest_interactions.r \
  			      ./analysis/r-utils/interacted.r 
	touch $@
	R CMD BATCH --no-save --no-restore $@

analysis/p10_hr_grade_adj.do : ./data/d01_cacoh_stset_barlow.dta \
	      		       ./data/d01_cacoh_stset_barlow_specific.dta
	touch $@
	stata-se -b $@

analysis/p11_in_vs_out.r : 	./data/full_cohort_25mar2015.sas7bdat \
				./data/k2survivaldata_23apr2014.dta
	touch $@
	R CMD BATCH --no-save --no-restore $@
	
	 
# some data files are created by program files 
data/d00* : ./analysis/p00*
	stata-se -b $<

data/d01* : ./analysis/p01*
	stata-se -b $<

data/d02* : ./analysis/p02*
	stata-se -b $<

data/d03* : ./analysis/p03*
	stata-se -b $<

data/d04* : ./analysis/p04*
	stata-se -b $<

data/d05* : ./analysis/p05*
	R CMD BATCH --no-save --no-restore $<

data/d06* : ./analysis/p06*
	stata-se -b $<

data/d07* : ./analysis/p07*
	R CMD BATCH --no-save --no-restore $<

data/d08* : ./analysis/p08*
	R CMD BATCH --no-save --no-restore $<

data/d09* : ./analysis/p09*
	stata-se -b $<

data/d10* : ./analysis/p10*
	stata-se -b $<


# output files depend on their respective program files
analysis/output/?00_* : ./analysis/p00_getdata.do
	stata-se -b $<

analysis/output/?01_* : ./analysis/p01*
	stata-se -b $<

analysis/output/?02_* : ./analysis/p02*
	stata-se -b $<

analysis/output/?03_* : ./analysis/p03*
	stata-se -b $<

analysis/output/?04_* : ./analysis/p04*
	R CMD BATCH --no-save --no-restore $<

analysis/output/?05* : ./analysis/p05*
	stata-se -b $<

analysis/output/?06_* : ./analysis/p06*
	R CMD BATCH --no-save --no-restore $<

analysis/output/?07* : ./analysis/p07*
	stata-se -b $<

analysis/output/?08* : ./analysis/p08*
	R CMD BATCH --no-save --no-restore $<

analysis/output/?09* : ./analysis/p09*
	R CMD BATCH --no-save --no-restore $<

analysis/output/?10* : ./analysis/p10*
	stata-se -b $<

analysis/output/?11* : ./analysis/p11*
	R CMD BATCH --no-save --no-restore $<



# Report and manuscript depend on output
./text/tables_and_figures.tex : $(output) 
	touch $@
	cd text && latexmk -pdf tables_and_figures.tex
	cd text && latexmk -c tables_and_figures.tex

./text/vitd_rcc_surv.tex: $(output)
	touch $@
	cd text && latexmk -pdf vitd_rcc_surv.tex
	cd text && latexmk -c vitd_rcc_surv.tex

./text/supp_table1.tex : $(output) 
	touch $@
	cd text && latexmk -pdf supp_table1.tex
	cd text && latexmk -c  supp_table1.tex

text/copy_figures.sh : $(output)
	touch $@
	./text/copy_figures.sh


# pdf files in text depend on their tex file, and possibly a bib database
./text/tables_and_figures.pdf : ./text/tables_and_figures.tex
	cd text && latexmk -pdf tables_and_figures.tex
	cd text && latexmk -c tables_and_figures.tex

./text/supp_table1.pdf : ./text/supp_table1.tex
	cd text && latexmk -pdf supp_table1.tex
	cd text && latexmk -c supp_table1.tex

./text/vitd_rcc_surv.pdf : 	./text/vitd_rcc_surv.tex \
	       			./text/bibtex/*.bib
	cd text && latexmk -pdf vitd_rcc_surv.tex
	cd text && latexmk -c vitd_rcc_surv.tex

./text/vitd_rcc_surv.rtf : ./text/vitd_rcc_surv.tex \
  			  ./text/bibtex/*.bib
	cd text && pdflatex 	vitd_rcc_surv.tex
	cd text && bibtex    	vitd_rcc_surv.aux
	cd text && pdflatex 	vitd_rcc_surv.tex
	cd text && pdflatex 	vitd_rcc_surv.tex
	cd text && pdflatex 	vitd_rcc_surv.tex
	cd text && latex2rtf 	vitd_rcc_surv.tex
	cd text && latexmk -pdf vitd_rcc_surv.tex
	cd text && latexmk -c 	vitd_rcc_surv.tex

