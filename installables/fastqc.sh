#Dependencies: Essentials
curl -L http://www.bioinformatics.babraham.ac.uk/projects/fastqc/fastqc_v0.11.9.zip -o fastqc.zip
unzip fastqc.zip
rm -r fastqc.zip
cd FastQC
sudo chmod 755 fastqc
sudo ln -sf $(pwd)/fastqc /usr/local/bin/