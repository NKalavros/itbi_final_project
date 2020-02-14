# Small scale ChIP seq analysis for the course Introduction to Bioinformatics

## A short introduction

This repository holds the code, as well as documentation about the final project assignment in my M.Sc. course (Data Science and Information Technologies, Biomedical Data Science and Bioinformatics Specialization). The project is about a small-scale ChIP-seq analysis. The data analyzed were based [on this paper](https://www.ncbi.nlm.nih.gov/pubmed/25122613)[12].

*This code was tested on a vanilla _Ubuntu 18.04 LTS_ system running on a Google Cloud VM with 24 cores and 64 gigabytes of RAM. At many points, this comes into play during some commands that can be executed using multithreading. It should also be noted that these commands assume that the user has `sudo` access. The `.sh` file itself contains line by line comment, in order to be as clear as possible.*

The scripts are split into two general folders. A folder named scripts that contains the code to implement the pipeline and a folder called installables that contains .sh files to install all needed programs in a vanilla system. It also appends the PATH variable accordingly, so that every program is accessible from anywhere just by running:

`source ~/.bashrc`

Finally, some of the diagnostic plots that were generated are uploaded in this repository, such as the QC reports, the results from running MACS2, MEME and other programs, as well as all logfiles generated.

## Downloading the files

First, a folder is created to host the project's files. Then, the script navigates to it, creates a subfolder named genome, navigates to that and downloads the appropriate genome (mm9 in this case). It also creates a global variable `genome` for easy later access. This is accomplished with the following code block. Finally, _bwa_[1] is used to create an index for later mapping.

```mkdir itbi_project
cd itbi_project
mkdir genome
cd genome
curl -L ftp://ftp.ensembl.org/pub/release-67/fasta/mus_musculus/dna/Mus_musculus.NCBIM37.67.dna.toplevel.fa.gz -o mm.fa.gz #Download genome
gunzip mm.fa.gz
bwa index mm.fa &> index_creation.log &
echo "export genome=$(pwd)" >> ~/.bashrc
```

## Performing some miscellaneous quality control

After this step is complete, the scripts navigates one level up and creates a folder named *reads_noqc*. The .fastq files are downloaded there (assigned in the project description). A _FastQC_[2] report is generated pert, as well as a report for all 3 replicates. Afterwards, the resulting .html files can be displayed using a Jupyter Notebook (Done to circumvent the lack of an interface by creating a port to the Notebook). This is achieved with the following block of code. The .html files of the reports themselves will be also uploaded in the repository itself.

```cd ..
mkdir reads_noqc
cd reads_noqc
curl -L ftp://ftp.sra.ebi.ac.uk/vol1/fastq/ERR435/ERR435987/ERR435987.fastq.gz -o rep1.fastq.gz
curl -L ftp://ftp.sra.ebi.ac.uk/vol1/fastq/ERR435/ERR435999/ERR435999.fastq.gz -o rep2.fastq.gz
curl -L ftp://ftp.sra.ebi.ac.uk/vol1/fastq/ERR435/ERR435998/ERR435998.fastq.gz -o rep3.fastq.gz
readfiles=$(find -name "*.fastq.gz")
gunzip $readfiles
readfiles=$(find $(pwd) -name "*.fastq")
fastqc -t 8 -f fastq $readfiles
multiqc $(pwd)
cp ../../scripts/qc_files.ipnyb ./qc_files.ipnyb
jupyter-notebook --no-browser --port=5000
```

After inspecting the QC report, it was made clear that actions needed to be taken to combat the bad lane quality and perhaps tackle the presence of adapters. For this reason, Trimmomatic[4] was used (which is specialized for Illumina generated reads), as well as the Picard suite[5]. As in the above cases, the following block of code achieves that, while also creating specific files for each step of the experiment, complete with .html files generated from FastQC and MultiQC. The folders are amply named *reads_trimmomatic* and *reads_filter_trimmomatic*. The read names were also changed back to the Illumina standard, because EBI adds its own tag that makes them unreadable to the `filterbytile` script.

```cd ..
mkdir reads_trimmomatic
cd reads_trimmomatic
counter=1
for i in $readfiles
do
echo $counter
java -jar $trimmomatic SE -threads 8 -phred33 $i "rep${counter}_trimmomatic.fastq" ILLUMINACLIP:$adapters/TruSeq3-SE.fa:2:30:10 LEADING:3 TRAILING:3 SLIDINGWINDOW:4:15 MINLEN:36 &> "rep${counter}_trimmomatic.log"
let "counter=counter+1"
done
cp ../reads_noqc/scripts/qc_files.ipynb ./qc_files.ipynb
readfiles=$(find $(pwd) -name "*.fastq") && fastqc -t 8 -f fastq $readfiles && multiqc $(pwd) && jupyter-notebook --no-browser --port=5000
cd ..
mkdir reads_filter_trimmomatic
cd reads_filter_trimmomatic
cat $readfiles > all.fq
cat all.fq | sed -e "s/^@ERR[[:digit:]]\+\.[[:digit:]]\+\s/@/g" >> all_reformat.fq &
filterbytile.sh in=all_reformat.fq dump=dump.flowcell >& filter_all.log &
counter=1
for i in $readfiles
do
echo $counter
cat $i | sed -e "s/^@ERR[[:digit:]]\+\.[[:digit:]]\+\s/@/g" >> "rep${counter}.fq"
filterbytile.sh in="rep${counter}.fq" out="rep${counter}_filter_trimmomatic.fastq" indump=dump.flowcell &> "rep${counter}_filtering.log"
let "counter=counter+1"
done
cp ../reads_noqc/scripts/qc_files.ipynb ./qc_files.ipynb
readfiles=$(find $(pwd) -name "*.fastq") && fastqc -t 8 -f fastq $readfiles && multiqc $(pwd) && jupyter-notebook --no-browser --port=5000
```

## Aligning the reads to the genome

This concludes the preliminary quality control step. Now, moving onto the aligning step, yet another folder is created to house the newly created files. The files are aligned, using bwa-backtrack, first outputed into .SAM format, then processed using SAMtools[6] to .BAM format. 

```cd .. && mkdir aligned_reads && cd aligned_reads
echo 'source ~/.bashrc
counter=1
for arg
do
echo $counter
bwa aln -t 8 $genome/mm.fa $arg > "${counter}.sai"
bwa samse $genome/mm.fa "${counter}.sai" $arg > "rep_${counter}.sam"
let "counter=counter+1"
done' >> alignment_script.sh
alignment_script.sh $readfiles &> "alignment.log" &
readfiles=$(find $(pwd) -name "*.sam")
counter=1
for i in $readfiles
do
echo $counter
samtools view -S -b rep_${counter}.sam > rep_${counter}.bam
let "counter=counter+1"
done
readfiles=$(find $(pwd) -name "*.bam")
```

## Peak calling using MACS2

Now that alignment is complete, the pipeline can proceed to peak calling. For this step, MACS2[7] is used. Due to an unidentified complication in the dataset, MACS2 with default parameters only returns motifs that are one base long (perhaps this is due to the promiscuity of RNAPIII itself). For that reason, it was ran using the `--broad` flag for broad peak calling. MACS2 was ran twice, one for each replicate separately and one where all of them are pooled. Due to the samples provided in the assignment, no control (input/FLAG) sample was present. The files are deposited in a new folder named *reads_peak_calling*. The effective genome size parameter was also changed, as the default value is the effective genome size of the human genome and not the mouse one.

```cd .. && mkdir reads_peak_calling && cd reads_peak_calling
counter=1
for i in $readfiles #loop over them 
do
echo $counter
macs2 callpeak -t $i -n rep_${counter} -g 1.87e9 --broad -q 0.05 &> "peaks_rep_${counter}.log" &
let "counter=counter+1"
done
readfilesbed=$(find $(pwd) -name "*.broadPeak")
counter=1
for i in $readfilesbed
do
echo $counter
sort -k 9,9 -n -r $i > ${counter}_sorted_peaks.bed
head ${counter}_sorted_peaks.bed -n 3 > ${counter}_top_peaks.bed
let "counter=counter+1"
done
macs2 callpeak -t $readfiles -n reps_pooled -g 1.87e9 -q 0.05 --broad &> "peaks_rep_pooled.log" &
toppeaks=$(find $(pwd) -name "*top_peaks.bed")
filepooled=$(find $(pwd) -name "*pooled_peaks.broadPeak")
```

## Visualization of the top 3 peaks of each of the 3 samples using IGV

Subsequently, the top 3 peaks for each sample were selected (based on -log10(q-value)) and visualized with IGV[8], along with the files. For that reasons, the .BAM files had to be sorted and indexed using SAMtools. The files are once again placed in a new folder named *igv_visualization*. An image follows that shows the peak identified in chromosome X in all 3 replicates, as seen in IGV.

```cd .. && mkdir igv_visualization && cd igv_visualization
counter=1
for i in $readfiles
do
echo $counter
samtools sort -O BAM -@ 10 $i > rep_${counter}_sorted.bam
samtools index -@ 10 rep_${counter}_sorted.bam
let "counter=counter+1"
done
readfilesigv=$(find $(pwd) -name "*.bam")
igv.sh -g  $(pwd)/../genome/mm.fa $toppeaks $readfilexigv
```

## Analysis of emerging motifs using MEME

In the final steps of the analysis, the Gibbs sampling based technique MEME was used to infer consensus motifs from the pooled replicates' peaks. Both MEME[9] and the more specialized MEME-ChIP[10] modules of the MEME Suite[11] were used. The files are placed in a folder named motif_analysis.

```cd .. && mkdir motif_analysis && cd motif_analysis
bedtools getfasta -fi $(pwd)/../genome/mm.fa -bed $filepooled > peaks_pooled.fa
meme peaks_pooled.fa -o pooled_meme.out -dna >& meme.log &
meme peaks_pooled.fa -o pooled_meme_chip.out -dna >& meme_chip.log &
```

## References:

[1] Heng Li, Richard Durbin, Fast and accurate short read alignment with Burrows–Wheeler transform, Bioinformatics, Volume 25, Issue 14, 15 July 2009, Pages 1754–1760, https://doi.org/10.1093/bioinformatics/btp324

[2] https://www.bioinformatics.babraham.ac.uk/projects/fastqc/

[3] Philip Ewels, Måns Magnusson, Sverker Lundin, Max Käller, MultiQC: summarize analysis results for multiple tools and samples in a single report, Bioinformatics, Volume 32, Issue 19, 1 October 2016, Pages 3047–3048, https://doi.org/10.1093/bioinformatics/btw354

[4] Bolger AM, Lohse M, Usadel B. Trimmomatic: a flexible trimmer for Illumina sequence data. Bioinformatics. 2014;30(15):2114–2120. doi:10.1093/bioinformatics/btu170

[5] Broad Institute. (Accessed: 2020/02/13; version 2.17.8). “Picard Tools.” Broad Institute, GitHub repository. http://broadinstitute.github.io/picard/

[6] Heng Li, Bob Handsaker, Alec Wysoker, Tim Fennell, Jue Ruan, Nils Homer, Gabor Marth, Goncalo Abecasis, Richard Durbin, 1000 Genome Project Data Processing Subgroup, The Sequence Alignment/Map format and SAMtools, Bioinformatics, Volume 25, Issue 16, 15 August 2009, Pages 2078–2079, https://doi.org/10.1093/bioinformatics/btp352

[7] Zhang, Y., Liu, T., Meyer, C.A. et al. Model-based Analysis of ChIP-Seq (MACS). Genome Biol 9, R137 (2008). https://doi.org/10.1186/gb-2008-9-9-r137

[8] James T. Robinson, Helga Thorvaldsdóttir, Aaron M. Wenger, Ahmet Zehir, Jill P. Mesirov. Variant Review with the Integrative Genomics Viewer (IGV). Cancer Research 77(21) 31-34 (2017)

[9] Timothy L. Bailey and Charles Elkan, "Fitting a mixture model by expectation maximization to discover motifs in biopolymers", Proceedings of the Second International Conference on Intelligent Systems for Molecular Biology, pp. 28-36, AAAI Press, Menlo Park, California, 1994
 
[10] Philip Machanick and Timothy L. Bailey, "MEME-ChIP: motif analysis of large DNA datasets", Bioinformatics 27(12):1696-1697, 2011

[11] Timothy L. Bailey, Mikael Bodén, Fabian A. Buske, Martin Frith, Charles E. Grant, Luca Clementi, Jingyuan Ren, Wilfred W. Li, William S. Noble, "MEME SUITE: tools for motif discovery and searching", Nucleic Acids Research, 37:W202-W208, 2009

[12] Schmitt BM, Rudolph KL, Karagianni P, et al. High-resolution mapping of transcriptional dynamics across tissue development reveals a stable mRNA-tRNA interface. Genome Res. 2014;24(11):1797–1807. doi:10.1101/gr.176784.114
