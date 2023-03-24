#!/bin/bash
#SBATCH --job-name=filter-genotypingError
#SBATCH --mail-user=xz195@duke.edu
#SBATCH --mail-type=FAIL
#SBATCH --mem=1G
#SBATCH --time=8:00:00
#SBATCH --output=log/%j.out
#SBATCH --error=log/%j.out
#SBATCH -c 4
#SBATCH -p scavenger

############### testing command
#../script/RNAseq-analysis/pipeline_scripts/4_filter_genotyingEr.slurm /hpc/group/allenlab/scarlett/output/RNAseq/1000Genome/HG00171/HG00171_genotypeEr.tsv /hpc/group/allenlab/scarlett/output/RNAseq/1000Genome/HG00171/HG00171.no_chr.content.SNPs.vcf.gz /hpc/group/allenlab/scarlett/output/RNAseq/1000Genome/HG00171/HG00171.no_chr.content.SNPs.filtered.vcf.gz /hpc/group/allenlab/scarlett/output/RNAseq/1000Genome/HG00171/HG00171.no_chr.content.SNPs.hets.vcf.gz /hpc/group/allenlab/scarlett/output/RNAseq/1000Genome/HG00171/HG00171.no_chr.content.SNPs.hets.filtered.vcf.gz
###############

if [ -n "$SLURM_JOB_ID" ] ; then
    script_path=$(realpath $(scontrol show job $SLURM_JOBID | awk -F= '/Command=/{print $2}' | cut -d' ' -f1 ))
else
    script_path=$(realpath $0)
fi
scripts_dir=$(dirname "$script_path")

source $scripts_dir/setup.sh

hostname 1>&2
set -e
set -u
set -o pipefail

# read input
genotypingError_sites=$1
bi_vcfgz=$2
bihet_vcfgz=$3
filtered_bi_vcfgz=$4
filtered_bihet_vcfgz=$5
tmp_dir=$6


if [ -s "$filtered_bihet_vcfgz" \
    -a -s "$filtered_bi_vcfgz" ]; then
    echo "$filtered_bihet_vcfgz $filtered_bi_vcfgz already exist!"
    exit
fi

tmp_filtered_bi_vcfgz=$tmp_dir/tmp_genotype_bi_filter.vcf.gz
tmp_filtered_bihet_vcfgz=$tmp_dir/tmp_genotype_bihet_filter.vcf.gz

bgzip -@ $threads -cd $bi_vcfgz | \
    $scripts_dir/filter_vcf.py --GenotypingError-file $genotypingError_sites | \
    bgzip -@ $threads -c > $tmp_filtered_bi_vcfgz &

bgzip -@ $threads -cd $bihet_vcfgz | \
    $scripts_dir/filter_vcf.py --GenotypingError-file $genotypingError_sites | \
    bgzip -@ $threads -c > $tmp_filtered_bihet_vcfgz &

wait

mv $tmp_filtered_bi_vcfgz $filtered_bi_vcfgz
mv $tmp_filtered_bihet_vcfgz $filtered_bihet_vcfgz

echo $(date +"%T") "start indexing"

tabix -fp vcf $filtered_bihet_vcfgz &
tabix -fp vcf $filtered_bi_vcfgz &

wait
echo "Done!"