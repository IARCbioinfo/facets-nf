#!/usr/bin/env Rscript

library(facets)
library(data.table)
options(datatable.fread.input.cmd.message=FALSE)
source(system.file("extRfns", "readSnpMatrixDT.R", package="facets"))

datafile = commandArgs(TRUE)[1] # "S01493.cvs.gz"
genome = commandArgs(TRUE)[2] # "hg19"
cur_params = as.numeric(c(commandArgs(TRUE)[3:6])) # c(1000,25,300,150)
ndepth_param = as.numeric(commandArgs(TRUE)[7]) # 20
if (!is.na(commandArgs(TRUE)[8]) && commandArgs(TRUE)[8]=="PDF") {
	plot_pdf = TRUE
} else {
	plot_pdf = FALSE
}
	


sample_name = gsub(".cvs.gz","",datafile)
rcmat = readSnpMatrixDT(datafile)


plot_facets = function (oo_facets, fit_facets , text_title, plot_name, pdf = F) {
  if (pdf) {
  	pdf(paste(plot_name,"_CNV.pdf",sep=""), width = 12, height = 11)
  } else {
  	png(paste(plot_name,"_CNV.png",sep=""),width=30,height=27.5,units="cm",res=300)
  }
  plotSample(x = oo_facets, emfit = fit_facets, sname = text_title)
  dev.off()
  pdf(paste(plot_name,"_CNV_spider.pdf",sep=""),width = 6,height = 6)
  logRlogORspider(oo_facets$out, oo_facets$dipLogR)
  dev.off()
}

xx = preProcSample(rcmat, gbuild = genome, ndepth = ndepth_param, snp.nbhd = cur_params[1], cval = cur_params[2])
oo_large = procSample(xx, cval = cur_params[3])
fit_large = emcncf(oo_large)
oo_fine = procSample(xx, cval = cur_params[4], dipLogR = oo_large$dipLogR)
fit_fine = emcncf(oo_fine)
  
text_title=paste(sample_name,": Purity=",round(fit_fine$purity,3)*100,"%; Ploidy=",round(fit_fine$ploidy,2),sep="")
  
plot_facets(oo_fine, fit_fine, text_title, sample_name,plot_pdf)

cat("", "purity", "ploidy", "dipLogR", "loglik", "\n", file=paste(sample_name,"_stats.txt",sep=""),sep="\t")
cat(sample_name, fit_fine$purity, fit_fine$ploidy, fit_fine$dipLogR, fit_fine$loglik, file=paste(sample_name,"_stats.txt",sep=""),sep="\t",append = T)
  
fit_fine$cncf['cnlr.median-dipLogR'] = fit_fine$cncf$cnlr.median - fit_fine$dipLogR
write.table(fit_fine$cncf, file=paste(sample_name,"_CNV.txt",sep=""), quote = F, sep = "\t", row.names = F)
