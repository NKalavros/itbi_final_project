curl -L http://meme-suite.org/meme-software/5.1.1/meme-5.1.1.tar.gz -o meme-5.1.1.tar.gz
tar -zxvf meme-5.1.1.tar.gz
rm -r meme-5.1.1.tar.gz
cd meme-5.1.1
./configure --prefix=$HOME/meme --with-url="http://meme-suite.org"
make -j 10
sudo make install
cd ..
echo "export PATH=$(pwd)/meme/bin:$PATH" >> ~/.bashrc
echo "export PATH=$(pwd)/meme/libexec/meme-5.1.1:$PATH" >> ~/.bashrc
sudo cpan App::cpanminus
sudo cpanm XML::Simple
sudo apt-get -y install imagemagick
source ~/.bashrc