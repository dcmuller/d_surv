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

analysis/p04_survpred.do : ./data/d01_cacoh_stset_barlow.dta 
	touch $@
	stata-se -b $@

analysis/p05_plot_survival.r : ./analysis/output/o04_survpred_d3_stage.csv
	touch $@
	R CMD BATCH --no-save --no-restore $@

analysis/p06_relapse.do : ./data/d01_relapse_free_stset.dta \
  			  ./data/d01_relapse_compet_stset.dta	
	touch $@
	stata-se -b $@

analysis/p07_table_descriptive.r : ./data/d00_analysis.dta
	touch $@
	R CMD BATCH --no-save --no-restore $@

analysis/p08_interactions.r : ./data/d01_cacoh_stset_barlow.dta \
  			      ./analysis/r-utils/forest_interactions.r \
  			      ./analysis/r-utils/interacted.r 
	touch $@
	R CMD BATCH --no-save --no-restore $@

analysis/p09_bmi.do : ./data/d01_cacoh_stset_barlow.dta 
	touch $@
	stata-se -b $@

analysis/p10_hr_grade_adj.do : ./data/d01_cacoh_stset_barlow.dta \
	      		       ./data/d01_cacoh_stset_barlow_specific.dta
	touch $@
	stata-se -b $@


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
	stata-se -b $<

analysis/output/?05* : ./analysis/p05*
	R CMD BATCH --no-save --no-restore $<

analysis/output/?06_* : ./analysis/p06*
	stata-se -b $<

analysis/output/?07* : ./analysis/p07*
	R CMD BATCH --no-save --no-restore $<

analysis/output/?08* : ./analysis/p08*
	R CMD BATCH --no-save --no-restore $<

analysis/output/?09* : ./analysis/p09*
	stata-se -b $<

analysis/output/?10* : ./analysis/p10*
	stata-se -b $<


# Report and manuscript depend on output
./text/tables_and_figures.tex : $(output) 
	touch $@
	cd text && latexmk -pdf tables_and_figures.tex
	cd text && latexmk -c tables_and_figures.tex

#./text/rccsurv_vitd.tex: $(output)
#	touch $@
#	cd text && latexmk -pdf rccsurv_vitb.tex
#	cd text && latexmk -c rccsurv_vitb.tex

# pdf files in text depend on their tex file, and possibly a bib database
./text/tables_and_figures.pdf : ./text/tables_and_figures.tex
	cd text && latexmk -pdf tables_and_figures.tex
	cd text && latexmk -c tables_and_figures.tex

#./text/rccsurv_vitd.pdf : 	./text/rccsurv_vitb.tex \
#       				./text/bibtex/*.bib
#	cd text && latexmk -pdf rccsurv_vitb.tex
#	cd text && latexmk -c rccsurv_vitb.tex
#
#./text/rccsurv_vitd.rtf : ./text/rccsurv_vitb.tex \
#  			  ./text/bibtex/*.bib
#	cd text && pdflatex 	rccsurv_vitb.tex
#	cd text && bibtex    	rccsurv_vitb.aux
#	cd text && pdflatex 	rccsurv_vitb.tex
#	cd text && pdflatex 	rccsurv_vitb.tex
#	cd text && pdflatex 	rccsurv_vitb.tex
#	cd text && latex2rtf 	rccsurv_vitb.tex
#	cd text && latexmk -pdf rccsurv_vitb.tex
#	cd text && latexmk -c 	rccsurv_vitb.tex

