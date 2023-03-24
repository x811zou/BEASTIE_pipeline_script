#!/bin/bash
#SBATCH --job-name=run-shapeit4-chrom
#SBATCH --mail-user=xz195@duke.edu
#SBATCH --mail-type=FAIL
#SBATCH --mem=1G
#SBATCH -c 4
#SBATCH --time=8:00:00
#SBATCH --output=log/%j.out
#SBATCH --error=log/%j.out
#SBATCH -p scavenger

############### testing command
# sample=NA12878
# outDir=/hpc/group/allenlab/scarlett/output/RNAseq/GIAB/NA12878/tmp/shapeit4
# header=/hpc/group/allenlab/scarlett/output/RNAseq/GIAB/NA12878/tmp/VCF/tmp.header.vcf
# vcfgz=/hpc/group/allenlab/scarlett/output/RNAseq/GIAB/NA12878/NA12878.no_chr.content.SNPs.hets.filtered.vcf.gz
# N=21
# ref=/datacommons/allenlab/scarlett/reference/shapeit4/reference/all/ALL.chr${N}.phase3_v5.shapeit2_mvncall_integrated.noSingleton.genotypes.vcf.gz
# sbatch -p scavenger ../script/RNAseq-analysis/pipeline_scripts2/5__run_shapeit4_chrom.slurm $sample $outDir $header $vcfgz $N $ref
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


# specify sample
sample=$1
outDir=$2
N=$3

# bcftools index --threads $threads -f $ref

now=$(date +"%T")
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> start with ${sample} :"${now}
############ 1. add 'chr', only select few columns
bgzip -@ $threads -cd $outDir/chr${N}/chr${N}.phased.vcf.gz | grep -E "^[^#]" | sort -k3 -n | cut -f2,6,7,8,9 --complement -d $'\t' | awk -F'\t' 'BEGIN {OFS=FS} {split($NF,a,"|"); $NF=a[1]; $(NF+1)=a[2]; print}' > $outDir/chr${N}.phased.cleaned.vcf
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> done"
