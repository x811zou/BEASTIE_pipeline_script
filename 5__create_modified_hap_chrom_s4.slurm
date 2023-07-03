#!/bin/bash
#SBATCH --job-name=create_modified_haplotype_s4-chr6
#SBATCH --mail-user=xz195@duke.edu
#SBATCH --mail-type=FAIL
#SBATCH --mem=512M
#SBATCH -c 2
#SBATCH --time=8:00:00
#SBATCH --output=log/%j.out
#SBATCH --error=log/%j.out
#SBATCH -p scavenger

############### testing command
# N=6
# ref_haplotype=/datacommons/allenlab/scarlett/reference/shapeit4/reference/all/ALL.chr${N}.phase3_v5.shapeit2_mvncall_integrated.noSingleton.genotypes.vcf.gz
# modified_haplotype=/hpc/group/allenlab/scarlett/output/RNAseq/GIAB/NA12878/tmp/shapeit4/modified_haplotype.tmp/1000GP_Phase3_chr${N}_rmNA12878.vcf.gz
# index=1754
# sbatch /hpc/group/allenlab/scarlett/github/BEASTIE_pipeline_script/5__create_modified_hap_chrom_s4.slurm $ref_haplotype $modified_haplotype $N $index
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
echo "done!"