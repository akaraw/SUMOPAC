#!/bin/bash
cdir=$(pwd)
export PATH=$cdir:$PATH
echo -e "\
###########################################
# DIRECT RNA SEQ ANALYSIS PIPELINE ACK V1 #
###########################################
"
if [ "$1" == "-h" ]; then
    echo "Usage: run_analysis.sh <sample dir> <work dir> <Basedir> <threads> <RNA to DNA Y/N>"
    exit 0
fi

#First we need to setup the executables we installed in step 2 to be avaible in the pathway
#If they are already not: export PATH=/path/to/executables:$PATH
#This script will not run if the executables are not in the current path (contact Anjana for help; anjana.karawita@csiro.au)

# e.g., WDIR=/mnt/c/Users/kar131/OneDrive - CSIRO/CERC_postdoctoral_fellow_Research/SUMOPAC_project
# e.g., smapledir=/datasets/work/aahl-minion/work/2022/2022-10-24_SUMOPAC_PArty_pool/20221024_0029_MN32206_FAS69300_c19605d4
sampledir=$1
WDIR=$2
basedir=$3 #This is same as step2
CPUS=$4
rna2dna=$5

export PATH=$basedir/bin:$PATH
export PATH=$basedir/minimap2:$PATH

if ! command -v minimap2 &> /dev/null
then
    echo "minimap2 could not be found..\
    exiting"
    exit 1 2> /dev/null
else
    echo "minimap2 found - proceeding to next step ..."
fi

if ! command -v kraken2 &> /dev/null
then
    echo "kraken2 could not be found\
          Please export to the current path"
    exit 1
else
    echo "kraken2 found - proceediong to next step"
fi

mkdir -p $WDIR
echo "Results will be written to $WDIR"

VECTAX=$basedir/vectaxmap.tab
BACTAX=$basedir/bacctaxmap.tab
VIRTAX=$basedir/virtaxmap.tab

if [ -z $1 ]; then
  echo " Please provide all varibales required "
  echo " run_analysis.sh -h for more info"
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

cd $WDIR
ln -s $sampledir mydir

if ! [ -s "$WDIR/all.fastq" ]; then
        if ! [ -s "mydir/fastq_pass" ]; then
                echo "Check your sample directory.\
                There is something wrong with it"
                exit 1 2> /dev/null
        else
                echo "sample directory contains valid results from\
                minion run"
                sdir=mydir/fastq_pass
                cat $sdir/*.fastq > $WDIR/all.fastq
                FQ=$WDIR/all.fastq
        fi
else
        echo "Omitting fastq concatenation"
        FQ=$WDIR/all.fastq
fi

#Concatenate all fastq files

if [ -s "$FQ" ]; then #if the file is not empty
  echo "Some data present to work with"
else
  echo "This is an empty fastq"
  exit 2 2> /dev/null #if the file is empty
fi

if [ $5 == "Y" ]; then
    echo "Converting RNA seq to DNA seq" 
    FQD=$WDIR/all_DNA.fq
    seqkit seq --rna2dna $FQ > $FQD
    FQ=$FQD
fi
##################################################################
#module load sekit #Run seqkit tool
#seqkit sample -p 0.1 all.fastq > test.fastq
#seqkit seq --rna2dna all.fastq > rna2dna_all.fastq
#sed -n '1~4s/^@/>/p;2~4p' rna2dna_all.fastq > rna2dna_all.fasta
#rm rna2dna_all.fastq

#minimap2 run - viruses
PAF=$WDIR/out_vir.paf
LIB=$basedir/kraken2vir/library/viral/library.fna
OUTFILE=$WDIR/minimap2_virus.csv
#Now run minimap2
if ! [ -s $PAF ];then
        minimap2 -t $CPUS -x map-ont  $MINIVEC $FQ > $PAF #Change the -k option if needed
else
        if ! [ -s $OUTFILE ];then
                $cdir/paf_reader.R $PAF $WDIR $OUTFILE $VECTAX 11
        fi
fi

#minimap2 run - bacteria
PAF=$WDIR/out_bac.paf
LIB=$basedir/bac.mmi #This is created in step 2
OUTFILE=$WDIR/minimap2_bacteria.csv
#Now run minimap2

if ! [ -s $PAF ];then
        minimap2 -t $CPUS -x map-ont  $MINIVEC $FQ > $PAF #Change the -k option if needed
else
        if ! [ -s $OUTFILE ];then
                $cdir/paf_reader.R $PAF $WDIR $OUTFILE $VECTAX 13
        fi
fi

#minimap2 run - vector
PAF=$WDIR/out_vec.paf
MINIVEC=$basedir/minimap2_vec.all.fa
OUTFILE=$WDIR/minimap2_vec.csv
#Now run minimap2

if ! [ -s $PAF ];then
        minimap2 -t $CPUS -x map-ont  $MINIVEC $FQ > $PAF #Change the -k option if needed
else
        if ! [ -s $OUTFILE ]; then
                $cdir/paf_reader.R $PAF $WDIR $OUTFILE $VECTAX 30
        fi
fi

echo "--- Now running Kraken2 ---"
DBBAC=$basedir/kraken2bac
DBVIR=$basedir/kraken2vir
DBVEC=$basedir/kraken2vec


if [ -s "$DBBAC" ]; then
    kraken2 --threads 12 --quick --output $WDIR/kraken2bac.txt --use-names --db $DBBAC $FQ
else
    echo "Can not locate $DBBAC for kraken2"
    exit 1
fi

if [ -s "$DBVIR" ]; then
    kraken2 --threads 12 --quick --output $WDIR/kraken2vir.txt --use-names --db $DBVIR $FQ
else
    echo -e "$DBVIR does not exist"
    exit 1
fi

if [ -s "$DBVEC" ]; then
    kraken2 --threads 12 --quick --output $WDIR/kraken2vec.txt --use-names --db $DBVEC $FQ
else
    echo -e "Can not locate $DBVEC for kraken2"
    exit 1
fi

echo -e "Pipeline is now completed - \nCherio!!!"
