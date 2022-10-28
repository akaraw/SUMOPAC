#!/bin/bash

###########################################
# DIRECT RNA SEQ ANALYSIS PIPELINE ACK V1 #
###########################################
#First we need to setup the executables we installed in step 2 to be avaible in the pathway
#If they are already not: export PATH=/path/to/executables:$PATH
#This script will not run if the executables are not in the current path (contact Anjana for help; anjana.karawita@csiro.au)

# e.g., WDIR=/mnt/c/Users/kar131/OneDrive - CSIRO/CERC_postdoctoral_fellow_Research/SUMOPAC_project
# e.g., smapledir=/datasets/work/aahl-minion/work/2022/2022-10-24_SUMOPAC_PArty_pool/20221024_0029_MN32206_FAS69300_c19605d4

if ! command -v minimap2 &> /dev/null
then
    echo "minimap2 could not be found..\
    exiting"
    exit 1 2> /dev/null
fi

if ! command -v kraken2 &> /dev/null
then
    echo "kraken2 could not be found\
          Please export to the current path"
    exit 1
fi

sampledir=$1
WDIR=$2 
basedir=$3
CPUS=$4
DBNAME=$6
MMI=$7

if [ -z $1 ]; then
  echo " Please provide all varibales required "
  echo " runmeta.sh <sample.dir> <workdir> <threds>"
  exit 1 2> /dev/null
fi


if [ -z $2 ]; then
  echo "Using home directory as the <workdir>"
  WDIR=~
fi

if [ -z $4 ]; then
  echo "Setting threads to 1"
  CPUS=1
fi

if [ -z $7 ]; then
  echo "Using custom minimap2 index assuming it is in the current $WDIR"
  DBNAME=all_vir_wol_moz.mmi
fi

cd $WDIR
ln -s $sampledir mydir

if [ ! -d "mydir/fastq_pass"]; then
  echo "Check your sample directory.\
  There is something wrong with it"
  exit 1 2> /dev/null
else
    echo "sample directory contains valid results from\
    minion run"
    sdir=mydir/fastq_pass
fi

#Concatenate all fastq files
if [ -s "all.fastq" ]; then
    echo "Omitting fastq concatenation"
else
    cat $sdir/*.fastq > all.fastq
fi

if [ -s "all.fastq" ]; then #if the file is not empty
  echo "Some data present to work with"
else
  exit 2 2> /dev/null #if the file is empty
fi

##################################################################
#module load sekit #Run seqkit tool
#seqkit sample -p 0.1 all.fastq > test.fastq
seqkit seq --rna2dna all.fastq > rna2dna_all.fastq
sed -n '1~4s/^@/>/p;2~4p' rna2dna_all.fastq > rna2dna_all.fasta
#rm rna2dna_all.fastq

PAF=out.paf
#Now run minimap2
minimap2 -t $CPUS -uf -ax  all.fasta > $PAF

if [ -s "$PAF" ]; then
    ./paf_reader.R $PAF $WDIR
else
    echo "$PAF is empty.. exiting minimap2 analysis"
fi
