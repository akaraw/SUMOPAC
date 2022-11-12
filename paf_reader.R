#!/usr/bin/env Rscript
args = commandArgs(trailingOnly=TRUE)
paf <- args[1]
wdir <- args[2]
outfile <- args[3]
taxmap <- args[4]
N <- args[5]
N <- as.numeric(N)

Sys.setenv(R_LIBS_USER="/mnt/c/Users/kar131/lib") #Your custom library location
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

prim_alignment <- filter_secondary_alignments(ali)
df <- as.data.frame(prim_alignment)
df <- df[order(df$s1, decreasing = T),]
head(df)
substrRight <- function(x, n){
  substr(x, nchar(x)-n+1, nchar(x))
}

df$tname <- substrRight(df$tname, N)
tx <- read.table(taxmap, sep = "\t")
colnames(tx) <- c("tname", "spp")
MM <- merge(df, tx, by = "tname", all.x = T, all.y = F)
MM <- MM[order(MM$s1, decreasing = T),]
head(MM, 20)

write.csv(MM, outfile, quote = F, row.names = F)

q()
