#Usual R package dependencies
sudo apt-get -y install libapparmor1 libcurl4-gnutls-dev libxml2-dev libssl-dev gdebi-core
sudo apt-get -y install libcairo2-dev libxt-dev git-core libboost-dev
git clone https://github.com/kundajelab/phantompeakqualtools
cd phantompeakqualtools
wget https://github.com/hms-dbmi/spp/archive/1.15.2.tar.gz
#Gonna write the R script here and place it in a file. When this becomes a repository, update this shit
echo "install.packages('snow')
install.packages('snowfall')
install.packages('bitops')
install.packages('caTools')
install.packages('Rcpp')
install.packages('BiocManager')
BiocManager::install('Rsamtools')
install.packages('./1.15.2.tar.gz')" >> install_dependencies.R
sudo Rscript install_dependencies.R #Installation path not writable :(
echo "export runspp=($(pwd)/run_spp.R)" >> ~/.bashrc
source ~/.bashrc