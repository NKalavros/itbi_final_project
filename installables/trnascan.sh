curl -L http://trna.ucsc.edu/software/trnascan-se-2.0.5.tar.gz -o trnascan-se.tar.gz
tar -zxvf trnascan-se.tar.gz
rm - r trnascan-se.tar.gz
cd tRNAscan-SE-2.0
./configure
make -j 20
sudo make install
cd ..