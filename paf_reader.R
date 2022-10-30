#!/usr/bin/env Rscript
args = commandArgs(trailingOnly=TRUE)
paf <- args[1]
wdir <- args[2]
outfile <- args[3]

Sys.setenv(R_LIBS_USER="/mnt/c/Users/kar131/lib")
Sys.getenv("R_LIBS_USER")
dir.exists(Sys.getenv("R_LIBS_USER"))
.libPaths(Sys.getenv("R_LIBS_USER"))

packages <- c("pafr", "ggplot2")
install.packages(setdiff(packages, rownames(installed.packages())), lib = "/mnt/c/Users/kar131/lib")

library(pafr)
require(ggplot2)
#library(ggpubr)

setwd(wdir)

ali <- read_paf(paf)

#pdf("dotplot_dv_vs_length.pdf", width = 6, height = 6)
#dv <- ggplot(ali, aes(alen, dv)) + 
#  geom_point(alpha=0.6, colour="steelblue", size=2) + 
#  scale_x_continuous("Alignment length (kb)", label =  function(x) x/ 1e3) +
#  scale_y_continuous("Per base divergence") + 
#  theme_pubr()
#print(dv)
#dev.off()

by_q <- aggregate(dv ~ qname, data=ali, FUN=mean)
knitr::kable(by_q)

by_t <- aggregate(dv ~ tname, data=ali, FUN=mean)
knitr::kable(by_t)

prim_alignment <- filter_secondary_alignments(ali)
df <- as.data.frame(prim_alignment)
write.csv(df, outfile, quote = F, row.names = F)

#nrow(ali) - nrow(prim_alignment)

#pdf("dotplot_primary.pdf", width = 6, height = 6)
#p <- dotplot(prim_alignment, label_seqs=TRUE, order_by="qstart") + theme_bw()
#print(p)
#dev.off()
q()
