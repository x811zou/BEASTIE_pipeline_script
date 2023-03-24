#!/bin/bash
#SBATCH --get-user-env
#SBATCH -c 2
#SBATCH --mem=2G
#SBATCH --mail-user=xz195@duke.edu
#SBATCH --mail-type=FAIL
#SBATCH --out=log/%j.out
#SBATCH --error=log/%j.out
#SBATCH -p scavenger
#SBATCH --time=00:30:00

if [ -n "$SLURM_JOB_ID" ] ; then
    script_path=$(realpath $(scontrol show job $SLURM_JOBID | awk -F= '/Command=/{print $2}' | cut -d' ' -f1 ))
else
    script_path=$(realpath $0)
fi
scripts_dir=$(dirname "$script_path")

source $scripts_dir/setup.sh

set -u
set -e

# read input
sample=$1
tmp_dir=$2
bi_vcfgz=$3
bihet_vcfgz=$4

now=$(date +"%T")
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> start with ${sample} :"${now}

header_vcf=$tmp_dir/${sample}_header.vcf
all_chr_vcf=$tmp_dir/${sample}_allchr.vcf
all_chr_hets_vcf=$tmp_dir/${sample}_allchr.X.hets.vcf

cat $tmp_dir/${sample}_chr{1..22}.vcf $tmp_dir/${sample}_chrX.vcf > $all_chr_vcf
cat $all_chr_vcf | awk '{ if ($10=="1|0" || $10=="0|1") {print} }' > $all_chr_hets_vcf

cat $header_vcf $all_chr_vcf | bgzip -@2 -c > $bi_vcfgz &
cat $header_vcf $all_chr_hets_vcf | bgzip -@2 -c > $bihet_vcfgz &

wait

now=$(date +"%T")
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> start indexing :"${now}

tabix -fp vcf $bi_vcfgz &
tabix -fp vcf $bihet_vcfgz &

wait

rm -r $tmp_dir


now=$(date +"%T")
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> done with ${sample} :"${now}
