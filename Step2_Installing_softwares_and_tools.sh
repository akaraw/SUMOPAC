#!/bin/bash
#**Step 2**

#################################################################################################################
#This step describes the method for installing necessary programs to run the analysis on MinIon seqeuencing data. 
#Please cite each software appropriately                                                                          
#installing the bioinformatics tools                                                                              
#################################################################################################################

sudo apt update
sudo apt install make
sudo apt install build-essential
sudo apt-get install libz-dev
basedir=/path/to/your/home/local

#Go to the <basedir>:
echo "#This is where you would install the bioinformatics tools: (Need approximately 1tb of space)"
cd $basedir #This is where you would install the bioinformatics tools: (Need approximately 1tb of space)

###############################################################################################################
#Starting with R-base #R is a statistical language needed for analysis of the results and visualization
#Instructions to install R-base is documented here: https://cran.r-project.org/bin/linux/ubuntu/fullREADME.html
###############################################################################################################

#update indices
sudo apt update -qq
sudo apt install --no-install-recommends software-properties-common dirmngr
wget -qO- https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc | sudo tee -a /etc/apt/trusted.gpg.d/cran_ubuntu_key.asc

#add the R 4.0 repo from CRAN -- adjust 'focal' to 'groovy' or 'bionic' as needed
sudo add-apt-repository "deb https://cloud.r-project.org/bin/linux/ubuntu $(lsb_release -cs)-cran40/"
sudo apt install --no-install-recommends r-base

if ! command -v Rscript &> /dev/null
then
    echo "R could not be found. Please install R"
    exit 1
else
    echo "R found - proceediong to the next step"    
fi
  
if ! command -v git &> /dev/null
then
    echo "git could not be found. Please install git"
    exit 1
else
    echo "git found - proceediong to the next step"    
fi

if ! command -v make &> /dev/null
then
    echo "make could not be found. Please install"
    exit 1
else
    echo "make found - proceediong to the next step"    
fi

###########################################
#Installing minimap2 - a long read aligner
#Instructions are on the github page:
###########################################

git clone https://github.com/lh3/minimap2
cd minimap2 && make
echo "export PATH=$basedir/minimap2:$PATH" >> ~/.bashrc #wiritning the pathway export to bashrc to mount it automatically

###################
#Installing kraken2
###################

git clone https://github.com/DerrickWood/kraken2.git 
cd kraken2
KRAKEN2_DIR=$basedir/bin
./install_kraken2.sh $KRAKEN2_DIR

#################################
#Installing centrifuge - optional
#################################

#git clone https://github.com/infphilo/centrifuge
#cd centrifuge
#make
#sudo make install prefix=$basedir


#####################################################################################################################
#Finally you need to mount all the executable paths into ./bashrc so that next time when start the Ubuntu terminal, \
#it will automatically export the paths to the executables 
#####################################################################################################################

echo "export PATH=$basedir/bin:$PATH" >> ~/.bashrc
#Then restart the terminal
#Now you can test your installation
#The below will show you the path to executables if they are exported

if ! command -v minimap2 &> /dev/null
then
    echo "minimap2 could not be found. Please install"
    exit 1
else
    echo "minimap2 found - checking kraken2"    
fi

if ! command -v kraken2 &> /dev/null
then
    echo "kraken2 could not be found. Please install"
    exit 1
else
    echo "minimap2 found - now installing NCBI Blast"    
fi


#######################################################################
#Install NCBI Blast tools for Kraken2 repeat masking steps - dustmasker
#######################################################################
wget https://ftp.ncbi.nlm.nih.gov/blast/executables/LATEST/ncbi-blast-2.13.0+-x64-linux.tar.gz
tar zxvpf ncbi-blast-2.*+-x64-linux.tar.gz
echo "export PATH=$basedir/ncbi-blast-2.13.0+-x64-linux/bin:$PATH" >> ~/.bashrc

if ! command -v dustmasker > /dev/null; then
  echo "dustmasker is not in the path. Please check the installation"
  exit 1
else
  echo "dustmasker is installed"
  echo " Creating KRAKEN databses"
fi

##################################
#Installing KRAKEN2 db for bacteria
##################################

DBBAC=$basedir/kraken2bac
kraken2-build --threads 6 --download-taxonomy --db $DBBAC
kraken2-build --threads 6 --download-library bacteria --db $DBBAC
kraken2-build --threads 6 --threads 6 --build --db $DBBAC
#if above command give you an error, please read here https://github.com/DerrickWood/kraken2/issues/508

#Since the bacterial library is quite large, it is better to create anindex of the lib for the minimap2 run as follows
LIB=$DBBAC/library/bacteria/library.fna
TAXMAP=$basedir/tax_bac.map
grep ">"  $LIB | sed 's/>.*|//g' | cut -d" " -f1,2,3,4 | sed -r 's/\s+/\t/' > $TAXMAP
$INDEX=$basedir/bac.mmi
minimap2 -k 13 -t 12 -d $INDEX $LIB

##################################
#Installing KRAKEN2 db for viruses
##################################

DBVIR=$basedir/kraken2vir
kraken2-build --threads 6 --download-taxonomy --db $DBVIR
kraken2-build --threads 6 --download-library viral --db $DBVIR
kraken2-build --threads 6 --threads 6 --build --db $DBVIR

LIB=$DBVIR/library/viral/library.fna
TAXMAP=$basedir/tax_vir.map
grep ">"  $LIB | sed 's/>.*|//g' | cut -d" " -f1,2,3,4 | sed -r 's/\s+/\t/' > $TAXMAP

#######################################################################################################################
#Now lets dwonload some more genomes for vectors (mozies) as per the instrcution below:
#First install the ncbi_datasets tools: 
#Follow the instruction here for linux installation https://www.ncbi.nlm.nih.gov/datasets/docs/v2/download-and-install/
#Once it is installed:
#######################################################################################################################
DBVEC=$basedir/kraken2vec
kraken2-build --threads 6 --download-taxonomy --db $DBVEC

#Using NCBI datasets tools
if ! command -v datasets > /dev/null
then
  echo "Datasets command not found - installing to $basedir/bin"
  wget https://ftp.ncbi.nlm.nih.gov/pub/datasets/command-line/v2/linux-amd64/datasets -O $basedir/bin/datasets
else
  echo "datasets command found - downloading data ..."
fi

which datasets #will give you the path to executables

#IF you see the path, it is working
#now lets download some data

genus=anopheles
echo "Downloadng $genus.... We will let you know when this is done."
datasets download genome taxon anopheles --dehydrated --filename anopheles.zip #--assembly-level complete #Once this is completed
unzip anopheles.zip -d anopheles
datasets rehydrate --directory anopheles #This will run for a while (30 to 100 mnutes depending on the connection speed)
for i in $genus/ncbi_dataset/data/*/*.fna; do kraken2-build --add-to-library $i --db $DBNAME; done
echo "$genus added to the database"
#For minimap2
cat $genus/ncbi_dataset/data/*/*.fna > $basedir/$genus.vec.fa
grep ">" $basedir/$genus.vec.fa | sed 's/>//g' | cut -d" " -f1,2,3,4 | sed -r 's/\s+/\t/' > $genus.vectaxmap.tab


#<Aedes spp>
genus=aedes
echo "Downloadng $genus.... We will let you know when this is done."
datasets download genome taxon $genus --dehydrated --filename $genus.zip --assembly-level complete
unzip $genus.zip -d $genus
datasets rehydrate --directory $genus
for i in $genus/ncbi_dataset/data/*/*.fna; do kraken2-build --threads 6 --add-to-library $i --db $DBNAME; done
echo "$genus added to the database"
cat $genus/ncbi_dataset/data/*/*.fna > $basedir/$genus.vec.fa
grep ">" $basedir/$genus.vec.fa | sed 's/>//g' | cut -d" " -f1,2,3,4 | sed -r 's/\s+/\t/' > $basedir/$genus.vectaxmap.tab

#<Culex spp>
genus=culex
echo "Downloadng $genus.... We will let you know when this is done."
datasets download genome taxon $genus --dehydrated --filename $genus.zip 
unzip $genus.zip -d $genus
datasets rehydrate --directory $genus
for i in $genus/ncbi_dataset/data/*/*.fna; do kraken2-build --threads 6 --add-to-library $i --db $DBNAME; done
echo "$genus added to the database"
cat $genus/ncbi_dataset/data/*/*.fna > $basedir/$genus.vec.fa
grep ">" $basedir/$genus.vec.fa | sed 's/>//g' | cut -d" " -f1,2,3,4 | sed -r 's/\s+/\t/' > $basedir/$genus.vectaxmap.tab

cat $basedir/*.vec.fa > $basedir/minimap2_vec.all.fa
MINIVEC=$basedir/minimap2_vec.all.fa
rm $basedir/*.vec.fa
cat $basedir/*.vectaxmap.tab > $basedir/vectaxmap.tab
rm cat $basedir/*.vectaxmap.tab

#<Wolbachia spp>
#genus=wolbachia
#datasets download genome taxon $genus --dehydrated --filename $genus.zip 
#unzip $genus.zip -d $genus
#datasets rehydrate --directory $genus
#for i in $genus/ncbi_dataset/data/*/*.fna; do kraken2-build --threads 6 --add-to-library $i --db $DBNAME; done

kraken2-build --threads 6 --build --db $DBNAME

#Additional references
#https://cran.r-project.org/web/packages/fs/vignettes/function-comparisons.html

echo "Now the pipeline is set up on your computer"
echo "Run analysis using <run_analysis.sh> script"
