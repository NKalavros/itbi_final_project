#Dependencies
sudo apt-get -y install libncurses5-dev zlib1g-dev libbz2-dev liblzma-dev

curl -L https://github.com/samtools/samtools/releases/download/1.10/samtools-1.10.tar.bz2 -o samtools-1.10.tar.bz2 &&
tar -xjf samtools-1.10.tar.bz2 &&
rm -r samtools-1.10.tar.bz2 &&
cd samtools-1.10 &&
./configure &&
make -j 10 &&
sudo make install &&
echo "export PATH=$(pwd):$PATH" >> ~/.bashrc &&
echo "export BAM_ROOT=$(pwd)" >> ~/.bashrc &&
source ~/.bashrc &&
cp ./version.h ./version.hpp &&
sudo mkdir -p /usr/local/include/bam &&
sudo cp ./libbam.a /usr/local/lib/ &&
sudo cp ./*.h /usr/local/include/bam &&
sudo cp ./samtools /usr/local/bin/ &&
sudo cp ./version.hpp /usr/local/include/bam &&
cd htslib-1.10/htslib &&
sudo mkdir /usr/local/include/htslib &&
sudo cp ./*.h /usr/local/include/htslib &&
cd ~ &&
source ~/.bashrc &&
echo "Done"