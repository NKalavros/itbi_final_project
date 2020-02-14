#Dependencies: Essentials
#Requires 3.12 matplotlib and no higher (3.1.3 is the current version as of writing and therefore incompatible)
pip3 uninstall --yes matplotlib
pip3 install -Iv "matplotlib==3.1.1"
curl -LOk https://github.com/ewels/MultiQC/archive/master.zip
unzip master.zip
rm -r master.zip
cd MultiQC-master
sudo python3 setup.py install
cd ..