curl -L https://sourceforge.net/projects/bbmap/files/latest/download -o bbmap.tar.gz
tar -zxvf bbmap.tar.gz
rm -r bbmap.tar.gz
cd bbmap
echo "export PATH=$(pwd):$PATH" >> ~/.bashrc
source ~/.bashrc
cd ..