require(ggplot2)
require(gridExtra)
require(reshape2)
require(stringr)
# results <- data.frame(index = seq(12,1,-1),
#                       var = c("Overall",
#                               "Sex", "",
#                               "Country", "", "", "",
#                               "Hypertension", "",
#                               "Smoking status", "", ""
#                               ),
#                       val = c("",
#                               "Male", "Female",
#                               "Australia", "UK", "Greece", "Italy",
#                               "No", "Yes",
#                               "Never", "Former", "Current"
#                               ),
#                       est = c(2, 1, 4, 2, 1, 2, 4, .5, 16, 1.0, NA, NA),
#                       lci = c(1, .5, 2.00, 1.00, .5, 1, 2, .25, 4, NA, NA, NA),
#                       uci = c(4, 2, 8, 4, 2, 4, 8, 1, 16*4, NA, NA, NA)
#                       )

# function to format and combine variables for the table plot
fmt_table <- function(data, cols = c("est", "lci", "uci"), mindecimals=2) {
  results <- data
  ecl_cols <- match(cols, colnames(results))
  results$orci <- paste(str_trim(format(round(results[, ecl_cols[1]], mindecimals),
                                        nsmall = mindecimals
                                        )
                                 ),
                        " ",
                        "[",
                        paste(str_trim(format(round(results[, ecl_cols[2]], mindecimals),
                                              nsmall = mindecimals
                                              )
                                       ),
                              str_trim(format(round(results[, ecl_cols[3]], mindecimals), 
                                              nsmall = mindecimals
                                              ),
                                       ),
                              sep=", "
                              ),
                        "]",
                        sep = ""
                        )
  results$orci[results[ecl_cols[1]] == 1 &
               is.na(results[ecl_cols[2]]) &
               is.na(results[ecl_cols[3]])
               ] <- "reference"
  results$orci[results$orci=="NA [NA, NA]"] <- ""
  # we no longer need the individual values in this frame
  results <- results[, -ecl_cols]
  return(results)
}

# returns a minimal ggplot of scattered points and ci spikes
main_plot <- function(data, 
                      cols = c("index", "est", "lci", "uci"), 
                      xname, 
                      pointsize = 3,
                      xbreaks,
                      xlim
                      ) {
  results <- data
  keepcols <- match(cols, colnames(results))
  #results <- results[keepcols]
  main_plot <- ggplot(data = results,
                      aes_string(x = cols[2], y = cols[1])
                      )
  main_plot <- main_plot +
    geom_point(size=3) +
    geom_vline(xintercept = 1) +
    geom_errorbarh(aes_string(xmin = cols[3], xmax = cols[4], height=0)) +
    scale_x_log10(name = xname, breaks = xbreaks, limits = xlim) +
    scale_y_discrete(name = "") +
    theme_bw() +
    ggtitle("Supplementary Figure 1") + 
    theme(axis.text.y = element_blank(),
          axis.ticks.y = element_blank(),
          axis.title.y = element_blank(),
          plot.title = element_text(size=12, hjust = 1, vjust=1),
          panel.grid.minor.y=element_blank(), 
          panel.grid.major.y=element_blank(), 
          panel.grid.minor.x=element_blank(), 
          panel.grid.major.x=element_blank(), 
          plot.margin = unit(c(0.5,0,2,0), "lines"),
          axis.text.x = element_text(size=14),
          axis.title.x = element_text(size=16, vjust=-2)
          )
  return(main_plot)
}


# function to plot the basic table
table_plot <- function(long_data) {
  plot <- ggplot(data = long_data,
                 aes(x = variable, 
                     y = index,
                     label = value
                     )
                 )
                 
  plot <- plot +
    geom_text(size = 4, hjust = 0, vjust = .5) +
    labs(x="", y="") +
    scale_y_discrete(name = "", labels = " ") +
    scale_x_discrete(name = "", labels = " ") +
    theme_bw() +
    ggtitle(" ") + 
    theme(axis.text = element_text(colour = "white", size=12),
          axis.title.x = element_text(colour = "white", size=14),
          plot.title = element_text(colour="white", size=12, hjust = 1, vjust=0),
          axis.ticks = element_blank(),
          panel.grid.minor = element_blank(),
          panel.grid.major = element_blank(),
          panel.border = element_blank(),
          plot.margin = unit(c(0.5,0,2,0), "lines")
          )
}

# function to (optionally) add headings to the table
  #if () # check that the 3 variables are correct
add_headings <- function(tab_plot, results, headings) {
  vnames <- names(results[, !(names(results) %in% "index")])
  newindex <- max(results$index) + 1
  head_frame <- data.frame(index = rep(newindex, length(vnames)),
                           variable = vnames,
                           value = headings
                           )
  tab_plot<- tab_plot + geom_text(data = head_frame,
                                       aes(x = variable, 
                                           y = index, 
                                           label = value
                                           ),
                                        size = 4, hjust = 0, vjust = .5,
                                        fontface = "bold"
                                        )
  tab_plot <- tab_plot + 
    geom_hline(yintercept = c(newindex + .5, newindex - .5))
  return(tab_plot)
}

gg_eclplot <- function(results, 
                       x_title = "estimates and confidence intervals", 
                       pointsize = 4, 
                       est_colnames = c("est", "lci", "uci"), 
                       mindecimals = 2, 
                       headers = FALSE, 
                       headings, 
                       table_width = 0.5,
                       x_breaks,
                       x_lim) {
  mplot <- main_plot(data=results,
                     cols=c("index", est_colnames), 
                     xname=x_title,
                     xbreaks=x_breaks,
                     xlim=x_lim,
                     pointsize=pointsize
  )
  formatted_res <- fmt_table(data = results, 
                             cols = est_colnames,
                             mindecimals = mindecimals
  )
  formatted_res_long <- melt(data = formatted_res, 
                             id.vars = "index", 
                             value.name="value", 
                             variable.name="variable")
  
  tplot <- table_plot(formatted_res_long)
  
  if (headers == TRUE) {
    tplot <- add_headings(tplot, results=formatted_res, headings=headings)
  }
  ifelse((headers== TRUE),
         ymax <- max(results$index) + 1.5,
         ymax <- max(results$index) + .5
  )
  ymin = min(results$index) - 0.5
  xmax =  ncol(formatted_res) + 0.25
  xmin = 1
  tplot <- tplot + coord_cartesian(xlim = c(xmin, xmax),
                                   ylim = c(ymin, ymax)
  )
  mplot <- mplot + coord_cartesian(ylim = c(ymin, ymax)) 
  combined <- grid.arrange(tplot, mplot, ncol = 2, widths=c(table_width, 1-table_width))
  return(combined)
}
