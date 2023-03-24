#!/bin/bash
#SBATCH --job-name=create_modified_haplotype_s4
#SBATCH --mail-user=xz195@duke.edu
#SBATCH --mail-type=FAIL
#SBATCH --mem=512M
#SBATCH -c 2
#SBATCH --time=8:00:00
#SBATCH --output=log/%j.out
#SBATCH --error=log/%j.out
#SBATCH -p scavenger

############### testing command
# sample="HG00096"
# sbatch -p scavenger ../script/RNAseq-analysis/pipeline_scripts/4__create_modified_hap_chrom.slurm $sample /hpc/group/allenlab/scarlett/output/RNAseq/1000Genome/$sample/tmp/shapeit2/ref_rm${sample} /hpc/group/allenlab/scarlett/software/shapeit2/reference/1000GP_Phase3/1000GP_Phase3/1000GP_Phase3_chr21.hap.gz /hpc/group/allenlab/scarlett/output/RNAseq/1000Genome/$sample/tmp/shapeit2/ref_rm${sample}/1000GP_Phase3_chr${N}_rm${sample}.hap.gz ${N} 2
###############

if [ -n "$SLURM_JOB_ID" ] ; then
    script_path=$(realpath $(scontrol show job $SLURM_JOBID | awk -F= '/Command=/{print $2}' | cut -d' ' -f1 ))
else
    script_path=$(realpath $0)
fi
scripts_dir=$(dirname "$script_path")

source $scripts_dir/setup.sh
source $scripts_dir/helpers.sh

hostname 1>&2
set -e
set -u

# read input
ref_haplotype=$1
modified_haplotype=$2
N=$3
index=$4

bgzip -@ $threads -cd $ref_haplotype \
    | awk 'BEGIN{OFS="\t"} { if ($0 ~ /^##/) { print } else { $'$index'=""; sub(/\t\t/, "\t", $0); print } }' \
    | awk '{ if ($0 !~ /^#/) print | "sort -k1,1V -k2,2n"; else print }' \
    | bgzip -@ $threads -c -l3 > $modified_haplotype
bcftools index $modified_haplotype

