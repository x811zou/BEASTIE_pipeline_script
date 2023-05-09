#!/bin/bash
#SBATCH --job-name=prepare-shapeit2
#SBATCH --mail-user=xz195@duke.edu
#SBATCH --mail-type=FAIL
#SBATCH --mem=512M
#SBATCH -c 1
#SBATCH --time=8:00:00
#SBATCH --output=log/%j.out
#SBATCH --error=log/%j.out

############### testing command
# sample="HG00096"
# N="X"
# sbatch -p scavenger ../script/RNAseq-analysis/pipeline_scripts/4__prepare_shapeit2_chrom.slurm $sample /hpc/group/allenlab/scarlett/output/RNAseq/1000Genome/$sample/tmp/shapeit2 /hpc/group/allenlab/scarlett/output/RNAseq/1000Genome/$sample/${sample}.no_chr.content.SNPs.hets.vcf.gz ${N}
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
working_dir=$2
vcfgz=$3
N=$4

# specify paths
outDir=$working_dir
mkdir -p $outDir
mkdir -p $outDir/chr${N}
mkdir -p $outDir/chr${N}/vcf
mkdir -p $outDir/chr${N}/phase_withoutseq

now=$(date +"%T")
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> start with ${sample} :"${now}
############ 1. add 'chr', only select few columns
bgzip -@ $threads -cd $vcfgz | grep -E "^[^#]" | grep "^${N}\s" | sed -e 's/^/chr/' > $outDir/chr${N}/vcf/${sample}_bihetSNPs_chr${N}_phased.vcf
wc -l $outDir/chr${N}/vcf/${sample}_bihetSNPs_chr${N}_phased.vcf
#33050

############ 2. change it to be unphased vcf
cat $outDir/chr${N}/vcf/${sample}_bihetSNPs_chr${N}_phased.vcf |  awk -F'\t' 'BEGIN {OFS = FS} { sub(/\|/, "/", $10); sub("1/0", "0/1", $10 ) }1' > $outDir/chr${N}/vcf/${sample}_bihetSNPs_chr${N}_unphased.vcf
wc -l $outDir/chr${N}/vcf/${sample}_bihetSNPs_chr${N}_phased.vcf
wc -l $outDir/chr${N}/vcf/${sample}_bihetSNPs_chr${N}_unphased.vcf

############ 3. add header
TAB="$(printf '\t')"
cat - $outDir/chr${N}/vcf/${sample}_bihetSNPs_chr${N}_unphased.vcf > $outDir/chr${N}/vcf/${sample}_bihetSNPs_chr${N}_unphased.with_header.vcf << ENDOFHEADER
##fileformat=VCFv4.1
##source=pseq
##FILTER=<ID=PASS,Description="Passed variant FILTERs">
#CHROM${TAB}POS${TAB}ID${TAB}REF${TAB}ALT${TAB}QUAL${TAB}FILTER${TAB}INFO${TAB}FORMAT${TAB}${sample}
ENDOFHEADER
mv $outDir/chr${N}/vcf/${sample}_bihetSNPs_chr${N}_unphased.with_header.vcf $outDir/chr${N}/vcf/${sample}_bihetSNPs_chr${N}_unphased.vcf

########### shapeit4 commands
#module load bcftools
#vcfgz=../../../NA12878.no_chr.content.SNPs.hets.vcf.gz
#N=21
#bgzip -@ $threads -cd $vcfgz | grep -E "^[^#]" | grep "^${N}\s"  > chr21.vcf
#cat chr21.vcf |  awk -F'\t' 'BEGIN {OFS = FS} { sub(/\|/, "/", $10); sub("1/0", "0/1", $10 ) }1' > chr21.unphased.vcf
#cat ../../../VCF/tmp.header.vcf chr21.unphased.vcf > chr21.unphased.header.vcf
#bcftools query -f '[%SAMPLE=%GT\n]' chr21.unphased.header.vcf | cut -f 2 -d \=  | sort | uniq -c
#bgzip chr21.unphased.header.vcf
#bcftools index chr21.unphased.header.vcf.gz
#shapeit4 --input chr21.unphased.header.vcf.gz --map /datacommons/allenlab/scarlett/reference/shapeit4/chr21.b37.gmap.gz --region 21 --output chr21.phased.vcf.gz --reference /datacommons/allenlab/scarlett/reference/shapeit4/reference/all/ALL.chr21.phase3_v5.shapeit2_mvncall_integrated.noSingleton.genotypes.vcf.gz
