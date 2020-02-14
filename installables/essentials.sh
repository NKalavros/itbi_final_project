sudo apt-get -y update
#Compilers
sudo apt-get -y install build-essential
#Python
sudo apt-get -y install python2 python3 python2-pip python3-pip gzip unzip tar parallel
pip2 install setuptools wheel cython virtualenv
pip3 install setuptools wheel cython virtualenv
#R
sudo apt-get -y install apt-transport-https software-properties-common build-essential
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E298A3A825C0D65DFD57CBB651716619E084DAB9
sudo add-apt-repository 'deb https://cloud.r-project.org/bin/linux/ubuntu bionic-cran35/'
sudo apt-get update
sudo apt-get -y install r-base r-base-dev
#Java
sudo apt-get -y install default-jre default-jdk
#Installing Jupyter
pip3 install jupyter
echo "export PATH=~/.local/bin:$PATH" >> ~/.bashrc
jupyter notebook --generate-config
echo 'c = get_config()
c.NotebookApp.ip = "*"
c.NotebookApp.open_browser = False
c.NotebookApp.port = 5000' >> ~/.jupyter/jupyter_notebook_config.py