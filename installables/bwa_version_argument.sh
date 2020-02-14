curl -L "https://sourceforge.net/projects/bio-bwa/files/bwa-$1.tar.bz2/download" -o bwa.tar.bz2
tar -jxvf bwa.tar.bz2
rm -r bwa.tar.bz2
cd "bwa-$1"
make -j 8
sudo ln -sf $(pwd)/bwa /usr/local/bin/bwa
cd ..