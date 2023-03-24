#!/bin/bash

sample=NA18934
ancestry=YRI
sex=male

working_dir=/hpc/group/allenlab/scarlett/output/RNAseq/1000Genome/$sample
vcf_path=/datacommons/allenlab/scarlett/data/VCF/1000_genome/20130502/bgzip
raw_fq_dir=/datacommons/allenlab/scarlett/data/fastq/1000Genome/$sample
raw_fq_fwd=$(ls $raw_fq_dir/*_1.fastq.gz)
raw_fq_rev=$(ls $raw_fq_dir/*_2.fastq.gz)
fastq_read_length=75
simulation_depth=100


if [ -n "$SLURM_JOB_ID" ] ; then
    script_path=$(realpath $(scontrol show job $SLURM_JOBID | awk -F= '/Command=/{print $2}' | cut -d' ' -f1 ))
else
    script_path=$(realpath $0)
fi
scripts_dir=$(dirname "$script_path")

# rm -f log/*

sbatch $scripts_dir/full_pipeline2.slurm \
  --sample $sample \
  --ancestry $ancestry \
  --sex $sex \
  --working-dir $working_dir \
  --vcf-path $vcf_path \
  --raw-fq-fwd $raw_fq_fwd \
  --raw-fq-rev $raw_fq_rev \
  --fastq-read-length $fastq_read_length \
  --simulation-depth $simulation_depth \
  --is-1000Genome \

