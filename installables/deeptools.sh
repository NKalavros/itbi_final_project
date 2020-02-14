#Prior dependencies: Python, Samtools
#Package specific dependencies
pip3 install numpy scipy py2bit pyBigWig pysam matplotlib ipython jupyter pandas sympy nose
git clone https://github.com/deeptools/deepTools
cd deepTools
python3 setup.py install --prefix $(pwd)
echo "export PATH=$(pwd)/bin:$PATH" >> ~/.bashrc
source ~/.bashrc
cd ..
	