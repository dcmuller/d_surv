#! p04_hr_splines.r

################################################
## required packages
req <- c("mvtnorm", "ggplot2", "reshape2", 
         "foreign", "Hmisc", "scales", 
         "Cairo", "lubridate", "gridExtra", "gtable", "plyr", "lmtest",
         "survival", "data.table")
lapply(req, library, character.only = TRUE)

# setting for simulating from the normal approximation to the
# sampling distribution of the parameters
set.seed(753892375)
nsamples <- 1000
analysis <- read.dta("data/d01_cacoh_stset_barlow.dta", convert.underscore=TRUE)
analysis_stata <- analysis
varlabs <- data.frame(varname = attributes(analysis_stata)$names, 
                      varlab = attributes(analysis_stata)$var.labels)
varlabs <- data.table(varlabs)
analysis <- data.table(analysis)
analysis$stage.imputed <- factor(analysis$stage.imputed)
analysis$sex<- factor(analysis$sex)

## restrict data 
analysis <- analysis[.st==1]

## calculate knot positions
knts3 <- quantile(analysis$vd3.h, 
                  probs = c(0.3, 0.5, 0.7),
                  na.rm = TRUE)
knts2 <- quantile(analysis$vd3.h, 
                  probs = c(0.33, 0.67),
                  na.rm = TRUE)
knts1 <- quantile(analysis$vd3.h, 
                  probs = c(0.5),
                  na.rm = TRUE)

bknts <- quantile(analysis$vd3.h,
                  probs = c(0.1, 0.9),
                  na.rm = TRUE)

## select the number of knots to use here
knts <- knts2


###############################################
## Survival Models

## variables to adjust for
#minlist <- c("age.recruitment", "sex", "sin1.recr.day", "cos1.recr.day") 
minlist <- c("age.recruitment", "sex", "stage.imputed", "sin1.recr.day", "cos1.recr.day") 
fullformula <- paste(minlist, collapse = " + ")
fullformula <- paste(fullformula, "+ strata(country)")

## set up strings to be parsed in to formula
lhsstr <- "Surv(time=.t0, time2=.t, event=.d) ~ "
xstr <- "ns(vd3.h, knots=knts, Boundary.knots=bknts)"


coxnull <- coxph(as.formula(paste(lhsstr, xstr)),
                 weights=wgt.stratified, robust=TRUE, data = analysis)
coxfull <- coxph(as.formula(paste(lhsstr, xstr, "+", fullformula)),
                 weights=wgt.stratified, robust=TRUE, data = analysis,
                 model = TRUE)
coxref <- coxph(as.formula(paste(lhsstr, fullformula)),
                 weights=wgt.stratified, robust=TRUE, data = analysis,
                 model = TRUE)

## generate matrix for prediction
vitd <- seq(5,100,by=1)
ns_vitd <- as.matrix(ns(vitd, knots = knts, Boundary.knots=bknts))

## model coefficients and variance covariance matrix
b <- coef(coxfull)[1:ncol(ns_vitd)]
V <- vcov(coxfull)[1:ncol(ns_vitd), 1:ncol(ns_vitd)]

## use vit.d = 50 as the reference
subtract_ref <- function(x) (x - x[vitd==50])
ns_vitd50 <- t(aaply(ns_vitd, 2, subtract_ref))

## prediction at ML estimates
pred_ml <- ns_vitd50 %*% b
se_ml <- sqrt(diag(ns_vitd50 %*% V %*% t(ns_vitd50)))
hr_ml <- exp(pred_ml)
hr_ml_lci <- exp(pred_ml - 1.96*se_ml)
hr_ml_uci <- exp(pred_ml + 1.96*se_ml)

hr_ml <- data.frame(vitd = vitd, 
                    hr_ml = hr_ml, 
                    lci = hr_ml_lci, 
                    uci = hr_ml_uci,
                    variable = "X1")

## simulate parameters from multivariate normal model
b_sim <- rmvnorm(nsamples, b, V)

## keep within the 95% highest posterior density region
post_dens <- dmvnorm(b_sim, mean = b, sigma = V)
cri <- quantile(post_dens, probs = c(0.025, 0.975), na.rm = TRUE)
b_sim <- b_sim[post_dens > cri[1] & post_dens < cri[2], ]


## prediction from simulated distribution of parameters
pred_sim <- ns_vitd50 %*% t(b_sim)
hr_sim <- exp(pred_sim)
hr_sim <- data.frame(vitd, hr_sim)
long_hr_sim <- melt(hr_sim, id.vars="vitd")
long_hr_sim

## drop those outside the point-wise ci's
t <- merge(long_hr_sim,hr_ml[, c("vitd", "lci", "uci")],all=TRUE)
t[t$value<t$lci | t$value>t$uci, "value"] <- NA
long_hr_sim <- t

## data frame to plot a "rug" to indicate density of vit D
rug_frame <- data.frame(variable="X1", value=NA, vitd=analysis$vd3.h)

## draw plot
p <- ggplot(data = long_hr_sim[!is.na(long_hr_sim$value), ],
            aes(x = vitd, y = value, group = variable))
p <- p + theme_bw(base_size=16)
p <- p + geom_line(alpha = I(1/sqrt(nsamples*15)))
p <- p + geom_line(data = hr_ml[!is.na(hr_ml$hr_ml), ], 
                   aes(x = vitd, y = hr_ml),
                   size = .8)
p <- p + geom_line(data = hr_ml,
                   aes(x = vitd, y = lci),
                   size = 0.3,
                   linetype = "dashed")
p <- p + geom_line(data = hr_ml,
                   aes(x = vitd, y = uci),
                   size = 0.3,
                   linetype = "dashed")
p <- p + geom_rug(data = rug_frame, 
                  x = vitd, 
                  colour = rgb(.3, .3, .3, .2), 
                  sides = "b")
p <- p + scale_y_log10("\n \n Hazard Ratio",
                       breaks=c(.25, .5, 1, 2, 4),
                       limits = c(.25, 4))
p <- p + scale_x_continuous(expression(paste("25(OH)D" [3], ", nmol/L")),
                            limits = c(4, 100))
p <- p + ggtitle("Figure 1")
p <- p + theme(legend.position="none",
               plot.title = element_text(hjust = 1),
               text=element_text(size=16),
               axis.text=element_text(size=14),
               axis.title.x=element_text(vjust=-.5),
               axis.title.y=element_text(vjust=0.3),
               #panel.grid.major = element_blank(),
               panel.grid.minor = element_blank())

CairoFonts(regular    = "Palatino:style=Regular", 
           bold       = "Palatino:style=Bold", 
           italic     = "Palatino:style=Italic",
           bolditalic = "Palatino:style=Bold Italic,BoldItalic",
           symbol     = "Symbol")
CairoPDF(file = "./analysis/output/g04_hr.pdf",
         width = 7, 
         height = 5)
print(p)
dev.off()
CairoTIFF(file = "./analysis/output/g04_hr.tiff", res = 300, 
          width = 5*300, 
          height = 4*300)
print(p)
dev.off()
#system("pdf2ps ./analysis/output/g12_hr.pdf ./analysis/output/g12_hr.ps")
#system("epstopdf ./analysis/output/g12_hr.ps")


####################################
## output numbers for text
hr <- hr_ml[hr_ml$vitd==25 | hr_ml$vitd==75, ]
print(hr)

