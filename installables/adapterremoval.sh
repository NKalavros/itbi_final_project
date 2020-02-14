wget -O adapterremoval-2.3.1.tar.gz https://github.com/MikkelSchubert/adapterremoval/archive/v2.3.1.tar.gz
tar xvzf adapterremoval-2.3.1.tar.gz
cd adapterremoval-2.3.1
make -j 10
sudo make install
cd ..