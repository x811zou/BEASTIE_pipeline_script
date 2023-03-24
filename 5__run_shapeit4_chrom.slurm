#!/bin/bash
#SBATCH --job-name=run-shapeit4-chrom
#SBATCH --mail-user=xz195@duke.edu
#SBATCH --mail-type=FAIL
#SBATCH --mem=4G
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
header=$3
vcfgz=$4
N=$5
ref=$6

# specify paths
mkdir -p $outDir
mkdir -p $outDir/chr${N}
# bcftools index --threads $threads -f $ref

now=$(date +"%T")
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> start with ${sample} :"${now}
############ 1. add 'chr', only select few columns
bgzip -@ $threads -cd $vcfgz | grep -E "^[^#]" | grep "^${N}\s" > $outDir/chr${N}/${sample}_bihetSNPs_chr${N}.vcf

############ 2. change it to be unphased vcf
cat $outDir/chr${N}/${sample}_bihetSNPs_chr${N}.vcf |  awk -F'\t' 'BEGIN {OFS = FS} { sub(/\|/, "/", $10); sub("1/0", "0/1", $10 ) }1' > $outDir/chr${N}/${sample}_bihetSNPs_chr${N}.unphased.vcf

############ 3. add header
cat $header $outDir/chr${N}/${sample}_bihetSNPs_chr${N}.unphased.vcf > $outDir/chr${N}/${sample}_bihetSNPs_chr${N}.unphased.header.vcf
bcftools query -f '[%SAMPLE=%GT\n]' $outDir/chr${N}/${sample}_bihetSNPs_chr${N}.unphased.header.vcf | cut -f 2 -d \=  | sort | uniq -c

############ 4. indexing
bgzip -@ $threads -f $outDir/chr${N}/${sample}_bihetSNPs_chr${N}.unphased.header.vcf
bcftools index --threads $threads -f $outDir/chr${N}/${sample}_bihetSNPs_chr${N}.unphased.header.vcf.gz

########### shapeit4 commands
shapeit4 --input $outDir/chr${N}/${sample}_bihetSNPs_chr${N}.unphased.header.vcf.gz \
    --thread $threads \
    --map /datacommons/allenlab/scarlett/reference/shapeit4/chr${N}.b37.gmap.gz \
    --region $N \
    --output $outDir/chr${N}/chr${N}.phased.vcf.gz \
    --reference $ref

bgzip -@ $threads -cd $outDir/chr${N}/chr${N}.phased.vcf.gz | grep -E "^[^#]" | sort -k3 -n | cut -f3,6,7,8,9 --complement -d $'\t' | awk -F'\t' 'BEGIN {OFS=FS} {split($NF,a,"|"); $NF=a[1]; $(NF+1)=a[2]; print}' > $outDir/chr${N}.phased.cleaned.vcf

echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> done"
# vcfgz=../../../NA12878.no_chr.content.SNPs.hets.vcf.gz
# N=21
# bgzip -@ $threads -cd $vcfgz | grep -E "^[^#]" | grep "^${N}\s"  > chr21.vcf
# cat chr21.vcf |  awk -F'\t' 'BEGIN {OFS = FS} { sub(/\|/, "/", $10); sub("1/0", "0/1", $10 ) }1' > chr21.unphased.vcf
# cat ../../../VCF/tmp.header.vcf chr21.unphased.vcf > chr21.unphased.header.vcf
# bcftools query -f '[%SAMPLE=%GT\n]' chr21.unphased.header.vcf | cut -f 2 -d \=  | sort | uniq -c
# bgzip chr21.unphased.header.vcf
# bcftools index chr21.unphased.header.vcf.gz
# shapeit4 --input chr21.unphased.header.vcf.gz --map /datacommons/allenlab/scarlett/reference/shapeit4/chr21.b37.gmap.gz --region 21 --output chr21.phased.vcf.gz --reference /datacommons/allenlab/scarlett/reference/shapeit4/reference/all/ALL.chr21.phase3_v5.shapeit2_mvncall_integrated.noSingleton.genotypes.vcf.gz
