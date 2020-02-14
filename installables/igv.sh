curl -L https://data.broadinstitute.org/igv/projects/downloads/2.8/IGV_Linux_2.8.0.zip -o igv_linux.zip
unzip igv_linux.zip
rm -r igv_linux.zip 
cd IGV_Linux_2.8.0
echo "export PATH=$(pwd):$PATH" >> ~/.bashrc