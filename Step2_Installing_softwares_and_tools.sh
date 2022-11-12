#!/bin/bash
#**Step 2**
#################################################################################################################
#This step describes the method for installing necessary programs to run the analysis on MinIon seqeuencing data.
#Please cite each software appropriately
#installing the bioinformatics tools
#################################################################################################################
basedir=$1
if [ -s $basedir ];then
        export PATH=$basedir/bin:$PATH
        cd $basedir
else
        mkdir -p $basedir/bin
        cd $basedir
fi

if ! command -v make &> /dev/null; then
    echo "make is not installed, now installing"
    sudo apt update
    sudo apt install make
    sudo apt install build-essential
    sudo apt-get install libz-dev
else
    echo "make is installed. Proceeding to next step"
fi

#Go to the <basedir>:
echo "This is where you wanted to install the bioinformatics tools and databases: $basedir (Need approximately 1tb of space)"
echo "If the $basedir does not exit, we will create it"

if ! command -v seqkit &> /dev/null; then
        wget https://github.com/shenwei356/seqkit/releases/download/v2.3.1/seqkit_linux_amd64.tar.gz
        tar -xvzf seqkit_linux_amd64.tar.gz $baseidr/bin
fi
###############################################################################################################
#Starting with R-base #R is a statistical language needed for analysis of the results and visualization
#Instructions to install R-base is documented here: https://cran.r-project.org/bin/linux/ubuntu/fullREADME.html
###############################################################################################################

if ! command -v Rscript &> /dev/null
then
    #update indices
    sudo apt update -qq
    sudo apt install --no-install-recommends software-properties-common dirmngr
    wget -qO- https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc | sudo tee -a /etc/apt/trusted.gpg.d/cran_ubuntu_key.asc

    #add the R 4.0 repo from CRAN -- adjust 'focal' to 'groovy' or 'bionic' as needed
    sudo add-apt-repository "deb https://cloud.r-project.org/bin/linux/ubuntu $(lsb_release -cs)-cran40/"
    sudo apt install --no-install-recommends r-base
fi

if ! command -v Rscript &> /dev/null
then
    echo "R could not be found. Please install R"
    exit 1
else
    echo "R found - proceeding to the next step"
fi

if ! command -v git &> /dev/null
then
    echo "git could not be found. Please install git"
    exit 1
else
    echo "git found - proceeding to the next step"
fi

if ! command -v make &> /dev/null
then
    echo "make could not be found. Please install"
    exit 1
else
    echo "make found - proceeding to the next step"
fi

###########################################
#Installing minimap2 - a long read aligner
#Instructions are on the github page:
###########################################
export PATH=$basedir/minimap2/:$PATH

if ! command -v minimap2 &> /dev/null
then
    git clone https://github.com/lh3/minimap2
    cd minimap2 && make
    echo "export PATH=$basedir/minimap2/minimap2:$PATH" >> ~/.bashrc #wiritning the pathway export to bashrc to mount it automatically
    export PATH=$basedir/minimap2/minimap2:$PATH
else
        echo "minimap2 is installed"
fi

###################
#Installing kraken2
###################
if ! command -v kraken2 &> /dev/null
then
    git clone https://github.com/DerrickWood/kraken2.git
    cd kraken2
    KRAKEN2_DIR=$basedir/bin
    ./install_kraken2.sh $KRAKEN2_DIR
    echo "export PATH=$basedir/bin:$PATH" >> ~/.bashrc
    export PATH=$basedir/bin:$PAT
fi


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
    echo "kraken2 found - now installing NCBI Blast"
fi

#######################################################################
#Install NCBI Blast tools for Kraken2 repeat masking steps - dustmasker
#######################################################################
if ! command -v dustmasker > /dev/null; then
        echo "dustmasker is not in the path. We will check if it is already installed in $basedir"
        if [ -d $basedir/ncbi-blast-2.13.0+/bin ]; then
                echo "Found it in the $basedir. Now setting in path"
                export PATH=$basedir/ncbi-blast-2.13.0+/bin/:$PATH
        else
                echo "Nope, it is not still downloaded in $basedir. Let's do it first and set the path"
                wget https://ftp.ncbi.nlm.nih.gov/blast/executables/LATEST/ncbi-blast-2.13.0+-x64-linux.tar.gz -O $basedir/ncbi-blast-2.13.0+-x64-linux.tar.gz
                tar zxvpf $basedir/ncbi-blast-2.*+-x64-linux.tar.gz --directory $basedir
                #echo "export PATH=$basedir/ncbi-blast-2.13.0+/bin:$PATH" >> ~/.bashrc
                export PATH=$basedir/ncbi-blast-2.13.0+/bin/:$PATH
        fi
else
        echo "dustmasker is installed"
        echo " Creating KRAKEN databses"
fi

if ! command -v dustmasker > /dev/null; then
  echo "dustmasker is still not in the path. Please check the installation\n We need to exit installation now\n Install this manually"
  exit 1
fi

##################################
#Installing KRAKEN2 db for bacteria
##################################
DBBAC=$basedir/kraken2bac
if ! [ -d $DBBAC ]; then

        #DBBAC=$basedir/kraken2bac
        kraken2-build --threads 6 --download-taxonomy --db $DBBAC
        kraken2-build --threads 6 --download-library bacteria --db $DBBAC
        kraken2-build --threads 6 --threads 6 --build --db $DBBAC
        #if above command give you an error, please read here https://github.com/DerrickWood/kraken2/issues/508
fi

#Since the bacterial library is quite large, it is better to create anindex of the lib for the minimap2 run as follows
LIB=$DBBAC/library/bacteria/library.fna
INDEX=$basedir/bac.mmi
TAXMAP=$basedir/bactaxmap.tab

if ! [ -s $INDEX ]; then
        echo "The $INDEX for minimap2 was not found. We will create it now"
        #IB=$DBBAC/library/bacteria/library.fna
        TAXMAP=$basedir/bactaxmap.tab
        grep ">"  $LIB | sed 's/>.*|//g' | cut -d" " -f1,2,3,4 | sed -r 's/\s+/\t/' > $TAXMAP
        #$INDEX=$basedir/bac.mmi
        minimap2 -k 13 -t 12 -d $INDEX $LIB
fi

##################################
#Installing KRAKEN2 db for viruses
##################################

DBVIR=$basedir/kraken2vir
if ! [ -d $DBVRI ];then
        kraken2-build --threads 6 --download-taxonomy --db $DBVIR
        kraken2-build --threads 6 --download-library viral --db $DBVIR
        kraken2-build --threads 6 --threads 6 --build --db $DBVIR
fi

LIB=$DBVIR/library/viral/library.fna

if ! [ -f $LIB ]; then
        TAXMAP=$basedir/virtaxmap.tab
        grep ">"  $LIB | sed 's/>.*|//g' | cut -d" " -f1,2,3,4 | sed -r 's/\s+/\t/' > $TAXMAP
fi

#######################################################################################################################
#Now lets dwonload some more genomes for vectors (mozies) as per the instrcution below:
#First install the ncbi_datasets tools:
#Follow the instruction here for linux installation https://www.ncbi.nlm.nih.gov/datasets/docs/v2/download-and-install/
#Once it is installed:
#######################################################################################################################
DBVEC=$basedir/kraken2vec
if ! [ -s $DBVEC/taxo.k2d ]; then
        kraken2-build --threads 6 --download-taxonomy --db $DBVEC
else
        echo "$DBVEC seems to be present. Skipping creating it"
fi

#Using NCBI datasets tools
if ! command -v datasets > /dev/null
then
  echo "Datasets command not found - installing to $basedir/bin"
  wget https://ftp.ncbi.nlm.nih.gov/pub/datasets/command-line/v2/linux-amd64/datasets -O $basedir/bin/datasets
else
  echo "datasets command found - downloading data ..."
fi

#which datasets #will give you the path to executables

#IF you see the path, it is working
#now lets download some data

genus=anopheles

if ! [ -s $genus/ncbi_dataset/data ];then
        echo "Downloadng $genus.... We will let you know when this is done."
        datasets download genome taxon anopheles --dehydrated --filename anopheles.zip #--assembly-level complete #Once this is completed
        unzip anopheles.zip -d anopheles
        datasets rehydrate --directory anopheles #This will run for a while (30 to 100 mnutes depending on the connection speed)
        for i in $genus/ncbi_dataset/data/*/*.fna; do kraken2-build --add-to-library $i --db $DBVEC; done
        echo "$genus added to the database"
else
        echo "$genus already downloaded. We assume it is already addedd to the $DBVEC"
fi

#For minimap2
if ! [ -s $basedir/$genus.vec.fa ]; then
        cat $genus/ncbi_dataset/data/*/*.fna > $basedir/$genus.vec.fa
fi

grep ">" $basedir/$genus.vec.fa | sed 's/>//g' | cut -d" " -f1,2,3,4 | sed -r 's/\s+/\t/' > $genus.vectaxmap.tab

#<Aedes spp>

genus=aedes

if ! [ -s $genus/ncbi_dataset/data ];then
        echo "Downloadng $genus.... We will let you know when this is done."
        datasets download genome taxon $genus --dehydrated --filename $genus.zip #There are not complete genomes for aedes
        unzip $genus.zip -d $genus
        datasets rehydrate --directory $genus
        for i in $genus/ncbi_dataset/data/*/*.fna
        do
                kraken2-build --threads 6 --add-to-library $i --db $DBVEC
        done
        echo "$genus added to the database"
else
        echo "$genus already downloaded. We assume it is already addedd to the $DBVEC"
fi

if ! [ -s $basedir/$genus.vec.fa ]; then
        cat $genus/ncbi_dataset/data/*/*.fna > $basedir/$genus.vec.fa
fi

grep ">" $basedir/$genus.vec.fa | sed 's/>//g' | cut -d" " -f1,2,3,4 | sed -r 's/\s+/\t/' > $basedir/$genus.vectaxmap.tab

#<Culex spp>
genus=culex
if ! [ -s $genus/ncbi_dataset/data ];then
        echo "Downloadng $genus.... We will let you know when this is done."
        datasets download genome taxon $genus --dehydrated --filename $genus.zip
        unzip $genus.zip -d $genus
        datasets rehydrate --directory $genus

        for i in $genus/ncbi_dataset/data/*/*.fna; do
                kraken2-build --threads 6 --add-to-library $i --db $DBVEC;
        done
        echo "$genus added to the database"

else
                echo "$genus already downloaded. We assume it is already addedd to the $DBVEC"
fi

if ! [ -s $basedir/$genus.vec.fa ]; then
        cat $genus/ncbi_dataset/data/*/*.fna > $basedir/$genus.vec.fa
fi
grep ">" $basedir/$genus.vec.fa | sed 's/>//g' | cut -d" " -f1,2,3,4 | sed -r 's/\s+/\t/' > $basedir/$genus.vectaxmap.tab

if ! [ -s $basedir/minimap2_vec.all.fa ]; then
        cat $basedir/*.vec.fa > $basedir/minimap2_vec.all.fa
fi

MINIVEC=$basedir/minimap2_vec.all.fa
rm $basedir/*.vec.fa
cat $basedir/*.vectaxmap.tab > $basedir/vectaxmap.tab
rm $basedir/*.vectaxmap.tab

#<Wolbachia spp>
#genus=wolbachia
#datasets download genome taxon $genus --dehydrated --filename $genus.zip
#unzip $genus.zip -d $genus
#datasets rehydrate --directory $genus
#for i in $genus/ncbi_dataset/data/*/*.fna; do kraken2-build --threads 6 --add-to-library $i --db $DBNAME; done

if ! [ -s $DBVEC/taxo.k2d ]; then
        kraken2-build --threads 6 --build --db $DBVEC
fi

#Additional references
#https://cran.r-project.org/web/packages/fs/vignettes/function-comparisons.html

echo "Now the pipeline is set up on your computer"
echo "Run analysis using <run_analysis.sh> script"
