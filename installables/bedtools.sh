wget https://github.com/arq5x/bedtools2/releases/download/v2.29.1/bedtools-2.29.1.tar.gz
tar -zxvf bedtools-2.29.1.tar.gz
rm -r bedtools-2.29.1.tar.gz
cd bedtools2
make -j 10
sudo make install
cd ..