#for athlates protocol manuscript, author: Chang Liu, WUSM, cliu32@wustl.edu
#!/bin/bash

#export the path to the bamtools library:
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/path/to/bamtools-2.3.0/lib #update path here

#path:
athlates=/path/to/athlates #update path here
dataf=/path/to/data #update path here
rsltf=$dataf"_rslt"
db=$athlates/db #includes ref, msa, bed

#imgt/hla version, suffix/prefix for data files
version="hla_3.29.0" #update database version here
suffix1="_1.fastq.gz" #update data file suffix here
suffix2="_2.fastq.gz" #update data file suffix here

#load required tools to be called for this pipeline, examples are shown below
#module load novoalignV3.03.00
#module load samtools-1.3


mkdir $rsltf
cd $dataf

for file in *1.fastq.gz ; do
	sample=$(echo $file | awk -F'_' '{print $1}')
	mkdir $rsltf/$sample
	cd $rsltf/$sample
	#read mapping using novoalign 
	novoalign -o SAM -r Random -i PE 100-1400 -H -t 30 -n 100 -c 12 -d $db/ref/$version.clean.ndx -f $dataf/$sample$suffix1 $dataf/$sample$suffix2 | samtools view -bS -h -F 4 - > $sample.bam
	#generating sorted bam file
	samtools sort $sample.bam -o $sample.sorted.bam
	#run athlates for in silico HLA typing, on locus at a time. 
	for locus in A B C DRB1 DQB1 DPB1; do
		perl $athlates/runAthlates.pl -ibam $sample.sorted.bam -bed $db/bed/$version.$locus.bed -nbed $db/bed/$version.non-$locus.bed -msa $db/msa/$version.$locus'_nuc.txt' -odir . -oprf $sample.$locus
	done
	cd $dataf
done
