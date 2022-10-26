#!/bin/bash

###########################################
# DIRECT RNA SEQ ANALYSIS PIPELINE ACK V1 #
###########################################
# e.g., WDIR=/mnt/c/Users/kar131/OneDrive - CSIRO/CERC_postdoctoral_fellow_Research/SUMOPAC_project
# e.g., smapledir=/datasets/work/aahl-minion/work/2022/2022-10-24_SUMOPAC_PArty_pool/20221024_0029_MN32206_FAS69300_c19605d4

sampledir=$1
WDIR=$2
CPUS=$3

if [ -z $1 ]; then
  echo " Please provide all varibales required "
  echo " runmeta.sh <sample.dir> <workdir> <threds>"
fi

if [ -z $2 ]; then
  echo "Using home directory as the <workdir>"
  WDIR=~
fi

cd $WDIR
ln -s $sampledir mydir

if [ ! -d "mydir/fastq_pass"]; then
  echo "Check your sample directory.\
  There is something wrong with it"
  exit 1
else
  echo "sample directory contains valid results from\
  minion run"
  sdir=mydir/fastq_pass
fi

#Concatenate all fastq files
cat $sdir/*.fastq > all.fastq

if [ -s "all.fastq" ]; then #if the file is not empty
  echo "Some data present to work with"
else
  exit 2 #if the file is empty
fi

#module load sekit #Run seqkit tool
seqkit sample -p 0.1 all.fastq > test.fastq
seqkit seq --rna2dna test.fastq > rna2dna_test.fastq
sed -n '1~4s/^@/>/p;2~4p' rna2dna_test.fastq > rna2dna_test.fasta
rm test.fastq rna2dna_test.fastq


#Now run minimap2

if ! command -v minimap2 &> /dev/null
then
    echo "minimap2 could not be found"
    exit 1
fi











