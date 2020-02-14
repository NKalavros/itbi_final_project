source ~/.bashrc
counter=1
for arg #Loop over files and use BWA backtrack, since we have very short reads (36 bp)
do
echo $counter
bwa aln -t 8 $genome/mm.fa $arg > "${counter}.bwa"
bwa samse -t 8 $genome/mm.fa "${counter}.bwa" $arg > "rep_${counter}.sam"
let "counter=counter+1"
done
