#dependencies - Bash, R, awk, samtools, Boost, spp, caTools, snow, snowfall, bitops, Rsamtools
sudo apt-get -y install apt-transport-https software-properties-common build-essential
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E298A3A825C0D65DFD57CBB651716619E084DAB9
sudo add-apt-repository 'deb https://cloud.r-project.org/bin/linux/ubuntu bionic-cran35/'
sudo apt-get update
sudo apt-get -y install r-base r-base-dev