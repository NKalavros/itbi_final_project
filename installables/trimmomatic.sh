wget http://www.usadellab.org/cms/uploads/supplementary/Trimmomatic/Trimmomatic-0.39.zip
unzip Trimmomatic-0.39.zip
rm -r Trimmomatic-0.39.zip
cd Trimmomatic-0.39
sudo chmod 755 Trimmomatic-0.39.jar
echo "export trimmomatic=($(pwd)/trimmomatic-0.39.jar)" >> ~/.bashrc #Call with java -jar $trimmomatic
echo "export adapters=$(pwd)/adapters" >> ~/.bashrc
source ~/.bashrc
cd ..