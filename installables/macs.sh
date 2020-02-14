sudo apt-get -y install python3 python python3-pip python-pip
pip3 install setuptools wheel numpy cython
pip3 install -U MACS2
echo "export PYTHONPATH=/usr/local/lib/python3.6/dist-packages/:$PYTHONPATH" >> ~/.bashrc
echo "export PATH=/usr/local/lib/python3.6/dist-packages/:$PATH" >> ~/.bashrc
cd ..