#Actual project code
#Installs: essentials, samtools, deeptools, bwa (0.7.17), FastQC, Trimmomatic, BBTools, MACS2, bedtools

mkdir itbi_project #Make a directory for the project
cd itbi_project #Go into that directory
mkdir genome #Subdirectory for the genome
cd genome #Go into that directory
curl -L ftp://ftp.ensembl.org/pub/release-67/fasta/mus_musculus/dna/Mus_musculus.NCBIM37.67.dna.toplevel.fa.gz -o mm.fa.gz #Download genome
gunzip mm.fa.gz #unzip it with gzip
bwa index mm.fa &> index_creation.log & #Make an index with bwa. Takes a good while (1.5 h)
echo "export genome=$(pwd)" >> ~/.bashrc #Export the directory for easier access

#You can check memory usage with ps -o pid,user,%mem,command ax | sort -b -k3 | tail
#You can also use pmap <PID> | tail -n 1 that specific pid for more detailed results.

cd .. #Go up one level
mkdir reads_noqc #Beginning reads_noqc
cd reads_noqc #Going into that directory
#Downloading the reads (each file is about 1.1 Gigabytes)
curl -L ftp://ftp.sra.ebi.ac.uk/vol1/fastq/ERR435/ERR435987/ERR435987.fastq.gz -o rep1.fastq.gz
curl -L ftp://ftp.sra.ebi.ac.uk/vol1/fastq/ERR435/ERR435999/ERR435999.fastq.gz -o rep2.fastq.gz
curl -L ftp://ftp.sra.ebi.ac.uk/vol1/fastq/ERR435/ERR435998/ERR435998.fastq.gz -o rep3.fastq.gz
readfiles=$(find -name "*.fastq.gz") #Create an array variable with the read filenames
gunzip $readfiles #Unzip all of them
readfiles=$(find $(pwd) -name "*.fastq") #Remake the array with the extracted files
fastqc -t 8 -f fastq $readfiles #Run FastQC on each file
multiqc $(pwd) #Amalgamate all QC runs with multiqc
cp ../../scripts/qc_files.ipnyb ./qc_files.ipnyb #Add the .ipnyb script here
jupyter-notebook --no-browser --port=5000 #Open up a Jupyter notebook, paste token shown in command line when asked. Open up a Python notebook and run the .ipnyb file

#After checking the QC reports, it is obvious that we need to use Trimmomatic (Remove bad lanes) and Picard (Remove duplicates)
#In contrast, even though there is much sequence duplication, Picard will not be ran because it interfereces with the goal of the experiment

cd .. #Navigate one level above
mkdir reads_trimmomatic #Make a folder for the reads after undergoing trimmomatic
cd reads_trimmomatic #Navigate to that directory
counter=1
for i in $readfiles #Loop over the files and run Trimmomatic.
do
echo $counter
java -jar $trimmomatic SE -threads 8 -phred33 $i "rep${counter}_trimmomatic.fastq" ILLUMINACLIP:$adapters/TruSeq3-SE.fa:2:30:10 LEADING:3 TRAILING:3 SLIDINGWINDOW:4:15 MINLEN:36 &> "rep${counter}_trimmomatic.log" #Default parameters
let "counter=counter+1"
done
#Repeat the same QC scheme
cp ../reads_noqc/scripts/qc_files.ipynb ./qc_files.ipynb
readfiles=$(find $(pwd) -name "*.fastq") && fastqc -t 8 -f fastq $readfiles && multiqc $(pwd) && jupyter-notebook --no-browser --port=5000

#Trimmomatic seems to not have fixed the problem with the Per Tile Sequence Quality, therefore, filterbytile from the BBMap suite will be used.

cd .. #Navigate one level above
mkdir reads_filter_trimmomatic #Create yet another directory for this filtering step
cd reads_filter_trimmomatic
cat $readfiles > all.fq #Create a big file that contains all replicates (Not advised in large scale analyses as it will be too huge!). Could also do this:  -e "s|#0/1||g"
cat all.fq | sed -e "s/^@ERR[[:digit:]]\+\.[[:digit:]]\+\s/@/g" >> all_reformat.fq & #Some hacky filtering of the files for the script to recognise the format. Using GNU parallel here to speed up sed
filterbytile.sh in=all_reformat.fq dump=dump.flowcell >& filter_all.log & #Run one filtering step to get some aggregate statistics on bad tiles
counter=1
for i in $readfiles #Loop over the files and run filterbytile, using the aggregate stats each time (Takes quite a while).
do
echo $counter
cat $i | sed -e "s/^@ERR[[:digit:]]\+\.[[:digit:]]\+\s/@/g" >> "rep${counter}.fq"
filterbytile.sh in="rep${counter}.fq" out="rep${counter}_filter_trimmomatic.fastq" indump=dump.flowcell &> "rep${counter}_filtering.log" #Default parameters
let "counter=counter+1"
done
#Repeat QC a third time
cp ../reads_noqc/scripts/qc_files.ipynb ./qc_files.ipynb
readfiles=$(find $(pwd) -name "*.fastq") && fastqc -t 8 -f fastq $readfiles && multiqc $(pwd) && jupyter-notebook --no-browser --port=5000

##This seems to have sufficiently fixed the reads, so we will proceed to downstream analysis

cd .. && mkdir aligned_reads && cd aligned_reads #Make directory and go in it (clear files)
echo 'source ~/.bashrc
counter=1
for arg #Loop over files and use BWA backtrack, since we have very short reads (36 bp)
do
echo $counter
bwa aln -t 8 $genome/mm.fa $arg > "${counter}.sai"
bwa samse $genome/mm.fa "${counter}.sai" $arg > "rep_${counter}.sam"
let "counter=counter+1"
done' >> alignment_script.sh #Throw everything in a second layer of scripting to retain access to shell
alignment_script.sh $readfiles &> "alignment.log" &
readfiles=$(find $(pwd) -name "*.sam") #Pick up the sam files
counter=1 #Counter scheme as in all other for loops
for i in $readfiles #loop over them 
do
echo $counter
samtools view -S -b rep_${counter}.sam > rep_${counter}.bam #Convert them to .bam, optionally delete .sam afterwards
let "counter=counter+1"
done
readfiles=$(find $(pwd) -name "*.bam") #Pick up the newly created .bam files
cd .. && mkdir reads_peak_calling && cd reads_peak_calling #Make more directories because we have ample space
counter=1 #Counter scheme as in all other for loops
for i in $readfiles #loop over them 
do
echo $counter
#Call peaks for one sample at a time for some reason, why? Realized that allpeaks were 1 nt afterwards, performing broad peak calling.
macs2 callpeak -t $i -n rep_${counter} -g 1.87e9 --broad -q 0.05 &> "peaks_rep_${counter}.log" &
let "counter=counter+1"
done
readfilesbed=$(find $(pwd) -name "*.broadPeak") #Pick up the newly created .broadPeak files
counter=1 #Counter scheme as in all other for loops
for i in $readfilesbed #loop over them 
do
echo $counter
sort -k 9,9 -n -r $i > ${counter}_sorted_peaks.bed #Sort by q-value at peak summit to obtain importances
head ${counter}_sorted_peaks.bed -n 3 > ${counter}_top_peaks.bed #Obtain the top 3 peaks only
let "counter=counter+1" #Increment
done
macs2 callpeak -t $readfiles -n reps_pooled -g 1.87e9 -q 0.05 --broad &> "peaks_rep_pooled.log" & #Run for all
toppeaks=$(find $(pwd) -name "*top_peaks.bed") #Pick up the top .bed files
filepooled=$(find $(pwd) -name "*pooled_peaks.broadPeak")
cd .. && mkdir igv_visualization && cd igv_visualization
#Sort your BAMs for IGV
counter=1 #Counter scheme as in all other for loops
for i in $readfiles #loop over them 
do
echo $counter
samtools sort -O BAM -@ 10 $i > rep_${counter}_sorted.bam #Index readfiles for IGV
samtools index -@ 10 rep_${counter}_sorted.bam
let "counter=counter+1"
done
readfilesigv=$(find $(pwd) -name "*.bam") #Pick up the newly created sorted .bam files
igv.sh -g  $(pwd)/../genome/mm.fa $toppeaks $readfilexigv #IGV visualization of the top 3 peaks
cd .. && mkdir motif_analysis && cd motif_analysis
bedtools getfasta -fi $(pwd)/../genome/mm.fa -bed $filepooled > peaks_pooled.fa
meme peaks_pooled.fa -o pooled_meme.out -dna >& meme.log & #Run MEME for motif finding
meme peaks_pooled.fa -o pooled_meme_chip.out -dna >& meme_chip.log & #Run MEME chip for good measure
#Setting up remote desktop for the IGV visualization (this is platform specific)w
wget https://dl.google.com/linux/direct/chrome-remote-desktop_current_amd64.deb
sudo apt-get -y update
sudo dpkg --install chrome-remote-desktop_current_amd64.deb
sudo apt-get install --assume-yes --fix-broken
sudo DEBIAN_FRONTEND=noninteractive apt-get install --assume-yes cinnamon-core desktop-base
sudo bash -c 'echo "exec /etc/X11/Xsession /usr/bin/cinnamon-session-cinnamon2d" > /etc/chrome-remote-desktop-session'
sudo systemctl disable lightdm.service
rm chrome-remote-desktop_current_amd64.deb