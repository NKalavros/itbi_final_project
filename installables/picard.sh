#Dependencies: Essentials
wget https://github.com/broadinstitute/picard/releases/download/2.21.7/picard.jar
sudo chmod 755 picard.jar
echo "export picard=($(pwd)/picard.jar)" >> ~/.bashrc #Due to this, you need to run Picard as java -jar $picard
source ~/.bashrc