#!/bin/bash

# load module
module load htslib
module load samtools
module load STAR/2.7.5c
module load Picard/2.18.2
module load Parallel
module load bcftools
# specify tmp path
export TMPDIR=/scratch/$USER/tmp
export TMP=/scratch/$USER/tmp
export TEMP=/scratch/$USER/tmp
export APPTAINER_TMPDIR=/scratch/$USER/tmp
export APPTAINER_CACHEDIR=/scratch/$USER/cache

##### fixed parameter
Trimmomatic=/hpc/group/allenlab/scarlett/software/Trimmomatic-0.39
ref=/datacommons/allenlab/scarlett/reference/hg19
star_ind=/datacommons/allenlab/scarlett/reference/STARIndex
mismatchN=10
AnnoDir=/datacommons/allenlab/scarlett/reference/hg19/annotations
shapeit2_ref_dir=/datacommons/allenlab/scarlett/reference/shapeit2/1000GP_Phase3/1000GP_Phase3
shapeit2_ref_sample_name=1000GP_Phase3.sample
shapeit4_ref_dir=/datacommons/allenlab/scarlett/reference/shapeit4/reference/all
util_dir=/datacommons/allenlab/scarlett/reference/twobit
genome_2bit=/datacommons/allenlab/scarlett/reference/hg19/hg19.2bit
ref_fasta=/datacommons/allenlab/scarlett/reference/hg19/hg19.fa
gff=/datacommons/allenlab/hg19/filter/gencode.v19.annotation.level12.gtf
python=/hpc/home/xz195/miniconda3/bin/python
gencode_dir=/datacommons/allenlab/scarlett/reference/hg19/annotations/gencode_chr
af_dir=/datacommons/allenlab/scarlett/reference/beastie_reference/AF

run_dir=/hpc/group/allenlab/scarlett/pipeline_working/run

beastie_singularity_image=/hpc/group/allenlab/scarlett/singularity_beastie/BEASTIE.sif
singularity_mount_paths=( /datacommons/allenlab/scarlett /hpc/group/allenlab/scarlett )

shapeit2_executable=/hpc/group/allenlab/scarlett/software/shapeit2/bin/shapeit
simulator_py=/hpc/group/allenlab/scarlett/github/spliced_simulator/unbiased-spliced-rna-test.py

# program hardcoded variables
star_bam_filename=Aligned.sortedByCoord.out.bam

mkdir -p $TMP

# useful variables
threads=$SLURM_CPUS_ON_NODE

# memory usage
step1_mem=16G
step2_mem=100G
step6_mem=10G
# recommendation:
# 8G for 1000 genome samples
# 9G for GSD samples
step7_mem=130G