curl -L http://eddylab.org/infernal/infernal-1.1.3.tar.gz -o infernal.tar.gz
tar -zxvf infernal.tar.gz
rm -r infernal.tar.gz
cd infernal-1.1.3
./configure
make -j 20
make check -j 20
sudo make install
cd ..