curl -L http://homer.ucsd.edu/homer/configureHomer.pl -o configureHomer.pl
perl configureHomer.pl -install
echo "export PATH=$(pwd)/homer/bin/:PATH" >> ~/.bashrc