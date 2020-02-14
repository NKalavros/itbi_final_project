source ~/.bashrc
counter=1
for arg #Loop over files and use BWA backtrack, since we have very short reads (36 bp)
do
echo $counter
bwa samse $genome/mm.fa "${counter}.sai" $arg > "rep_${counter}.sam"
let "counter=counter+1"
done
