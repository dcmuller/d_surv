#! p05_plot_survival.r
#! v0.01 20140509 dcmuller

################################################
library(ggplot2)
library(gtable)
library(gridExtra)
library(reshape2)
library(Cairo)
library(foreign)
library(extrafont)


################################################
## get data
pred_s <- read.dta("./analysis/output/o04_survpred_b6_stage.dta")
pred_s$stage <- factor(pred_s$stage, labels=c("I", "II", "III", "IV"))
#pred_s$`B6 category` <- factor(pred_s$b6_q4, labels=c("lowest", "2", "3", "highest"))
pred_s$`B6 category \n (nmol/L)` <- pred_s$b6_q4 

p <- ggplot(data=pred_s, aes(y=surv, x=time)) +
  geom_line(aes(colour=`B6 category \n (nmol/L)`, group=`B6 category \n (nmol/L)`), size=0.9) +
  facet_wrap( ~ stage) +
  scale_colour_brewer(palette="Set1") +
  scale_x_continuous(name="Time since diagnosis (y)") + 
  scale_y_continuous(name="Survival probability") + 
  theme_bw(base_size=16) +
  theme(legend.title=element_text(size=12),
        legend.text=element_text(size=10),
        legend.key.height=unit(10, "pt"),
        legend.key=element_blank(),
        legend.background=element_blank(),
        axis.title.x=element_text(vjust=-.5),
        axis.title.y=element_text(vjust=0.2))

CairoFonts(regular    = "Palatino:style=Regular", 
           bold       = "Palatino:style=Bold", 
           italic     = "Palatino:style=Italic",
           bolditalic = "Palatino:style=Bold Italic,BoldItalic",
           symbol     = "Symbol")
CairoPDF(file = "./analysis/output/g05_surv_b6_stage.pdf",
         width = 7.5, 
         height = 5.5) 
p
dev.off()
