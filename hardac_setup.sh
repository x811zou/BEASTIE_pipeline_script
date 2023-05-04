#!/bin/bash
source ~/.bashrc
conda activate beastie
# load module
module load STAR/2.7.2b-gcb01
module load bcftools
module load picard-tools/2.4.1-gcb01
module load java

##### fixed parameter
Trimmomatic=/data/allenlab/scarlett/software/Trimmomatic-0.39
ref=/data/reddylab/scarlett/reference/hg19
star_ind=/data/reddylab/scarlett/reference/STARIndex
mismatchN=10
AnnoDir=$ref/annotations
shapeit2_ref_dir=/data/allenlab/scarlett/software/shapeit2/reference/1000GP_Phase3/1000GP_Phase3
shapeit2_ref_sample_name=1000GP_Phase3.sample
util_dir=/data/reddylab/scarlett/reference/twobit
genome_2bit=$util_dir/hg19.2bit
ref_fasta=/data/allenlab/scarlett/data/reference/hg19/hg19.fa
gff=$AnnoDir/gencode.v19.annotation.filtered.gtf
beastie_ref_dir=/data/reddylab/scarlett/reference/beastie_reference
gencode_dir=$beastie_ref_dir/gencode_chr
af_dir=$beastie_ref_dir/AF
min_total=1
min_single=0

# run_dir=/hpc/group/allenlab/scarlett/pipeline_working/run
beastie_singularity_image=/data/allenlab/scarlett/BEASTIE-2023-02-21T08:03:20-0500.sif
singularity_mount_paths=( /data/reddylab/scarlett /data/allenlab/scarlett)

shapeit2_executable=/data/allenlab/scarlett/software/shapeit2/bin/shapeit
simulator_py=/data/allenlab/scarlett/github/spliced_simulator/unbiased-spliced-rna-test.py

# program hardcoded variables
star_bam_filename=Aligned.sortedByCoord.out.bam

# useful variables
threads=$SLURM_CPUS_ON_NODE

# memory usage suggested
step1_mem=5G
step2_mem=150G
step6_mem=15G
step7_mem=164G

## SPAG1-original memory usage
#step1_mem=5G
#step2_mem=XG