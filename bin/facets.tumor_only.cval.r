#!/usr/bin/env Rscript

library(facets)
library(data.table)
options(datatable.fread.input.cmd.message=FALSE)
source(system.file("extRfns", "readSnpMatrixDT.R", package="facets"))

datafile = commandArgs(TRUE)[1]
genome = commandArgs(TRUE)[2]
cur_params = as.numeric(c(commandArgs(TRUE)[3:6]))
ndepth_param = as.numeric(commandArgs(TRUE)[7])
het_thresh_param = as.numeric(commandArgs(TRUE)[8])

if (!is.na(commandArgs(TRUE)[9]) && commandArgs(TRUE)[9] == "MCVAL") {
  m_cval = TRUE
} else {
  m_cval = FALSE
}

if (!is.na(commandArgs(TRUE)[10]) && commandArgs(TRUE)[10] == "PDF") {
  plot_pdf = TRUE
} else {
  plot_pdf = FALSE
}

set.seed(1234)

sample_name = gsub("csv.gz", "", datafile)
sample_name_no_dot = gsub(".csv.gz", "", datafile)
rcmat = readSnpMatrixDT(datafile)

plot_facets = function(oo_facets, fit_facets, text_title, plot_name, pref = "cval300", pdf = FALSE) {
  if (pdf) {
    pdf(paste(plot_name, pref, "_CNV.pdf", sep = ""), width = 12, height = 11)
  } else {
    png(paste(plot_name, pref, "_CNV.png", sep = ""), width = 30, height = 27.5, units = "cm", res = 300)
  }
  plotSample(x = oo_facets, emfit = fit_facets, sname = text_title)
  dev.off()
  pdf(paste(plot_name, pref, "_CNV_spider.pdf", sep = ""), width = 6, height = 6)
  logRlogORspider(oo_facets$out, oo_facets$dipLogR)
  dev.off()
}

xx = preProcSample(
  rcmat,
  gbuild = genome,
  ndepth = ndepth_param,
  snp.nbhd = cur_params[1],
  cval = cur_params[2],
  het.thresh = het_thresh_param,
  unmatched = TRUE
)

fit1 = procSample(xx, cval = cur_params[3], min.nhet = 15, dipLogR = NULL)
oo_fine = procSample(xx, cval = cur_params[4], min.nhet = 15, dipLogR = fit1$dipLogR)
fit_fine = emcncf(oo_fine)

text_title = paste(sample_name_no_dot, ": TumorOnly Purity=", round(fit_fine$purity, 3) * 100, "%; Ploidy=", round(fit_fine$ploidy, 2), sep = "")
pref = paste("def_cval", cur_params[4], sep = "")

plot_facets(oo_fine, fit_fine, text_title, sample_name, pref, plot_pdf)
cat("", "purity", "ploidy", "dipLogR", "loglik", "\n", file = paste(sample_name, pref, "_stats.txt", sep = ""), sep = "\t")
cat(sample_name_no_dot, fit_fine$purity, fit_fine$ploidy, fit_fine$dipLogR, fit_fine$loglik, file = paste(sample_name, pref, "_stats.txt", sep = ""), sep = "\t", append = TRUE)
fit_fine$cncf["cnlr.median-dipLogR"] = fit_fine$cncf$cnlr.median - fit_fine$dipLogR
write.table(fit_fine$cncf, file = paste(sample_name, pref, "_CNV.txt", sep = ""), quote = FALSE, sep = "\t", row.names = FALSE)

if (m_cval) {
  oo_fine = procSample(xx, cval = 500, min.nhet = 15, dipLogR = fit1$dipLogR)
  fit_fine = emcncf(oo_fine)
  text_title = paste(sample_name_no_dot, ": TumorOnly Purity=", round(fit_fine$purity, 3) * 100, "%; Ploidy=", round(fit_fine$ploidy, 2), sep = "")
  plot_facets(oo_fine, fit_fine, text_title, sample_name, "cval500", plot_pdf)
  cat("", "purity", "ploidy", "dipLogR", "loglik", "\n", file = paste(sample_name, "cval500", "_stats.txt", sep = ""), sep = "\t")
  cat(sample_name_no_dot, fit_fine$purity, fit_fine$ploidy, fit_fine$dipLogR, fit_fine$loglik, file = paste(sample_name, "cval500", "_stats.txt", sep = ""), sep = "\t", append = TRUE)
  fit_fine$cncf["cnlr.median-dipLogR"] = fit_fine$cncf$cnlr.median - fit_fine$dipLogR
  write.table(fit_fine$cncf, file = paste(sample_name, "cval500", "_CNV.txt", sep = ""), quote = FALSE, sep = "\t", row.names = FALSE)

  oo_fine = procSample(xx, cval = 1000, min.nhet = 15, dipLogR = fit1$dipLogR)
  fit_fine = emcncf(oo_fine)
  text_title = paste(sample_name_no_dot, ": TumorOnly Purity=", round(fit_fine$purity, 3) * 100, "%; Ploidy=", round(fit_fine$ploidy, 2), sep = "")
  plot_facets(oo_fine, fit_fine, text_title, sample_name, "cval1000", plot_pdf)
  cat("", "purity", "ploidy", "dipLogR", "loglik", "\n", file = paste(sample_name, "cval1000", "_stats.txt", sep = ""), sep = "\t")
  cat(sample_name_no_dot, fit_fine$purity, fit_fine$ploidy, fit_fine$dipLogR, fit_fine$loglik, file = paste(sample_name, "cval1000", "_stats.txt", sep = ""), sep = "\t", append = TRUE)
  fit_fine$cncf["cnlr.median-dipLogR"] = fit_fine$cncf$cnlr.median - fit_fine$dipLogR
  write.table(fit_fine$cncf, file = paste(sample_name, "cval1000", "_CNV.txt", sep = ""), quote = FALSE, sep = "\t", row.names = FALSE)

  oo_fine = procSample(xx, cval = 1500, min.nhet = 15, dipLogR = fit1$dipLogR)
  fit_fine = emcncf(oo_fine)
  text_title = paste(sample_name_no_dot, ": TumorOnly Purity=", round(fit_fine$purity, 3) * 100, "%; Ploidy=", round(fit_fine$ploidy, 2), sep = "")
  plot_facets(oo_fine, fit_fine, text_title, sample_name, "cval1500", plot_pdf)
  cat("", "purity", "ploidy", "dipLogR", "loglik", "\n", file = paste(sample_name, "cval1500", "_stats.txt", sep = ""), sep = "\t")
  cat(sample_name_no_dot, fit_fine$purity, fit_fine$ploidy, fit_fine$dipLogR, fit_fine$loglik, file = paste(sample_name, "cval1500", "_stats.txt", sep = ""), sep = "\t", append = TRUE)
  fit_fine$cncf["cnlr.median-dipLogR"] = fit_fine$cncf$cnlr.median - fit_fine$dipLogR
  write.table(fit_fine$cncf, file = paste(sample_name, "cval1500", "_CNV.txt", sep = ""), quote = FALSE, sep = "\t", row.names = FALSE)
}

writeLines(capture.output(sessionInfo()), paste(sample_name, "R_sessionInfo.txt", sep = ""))
