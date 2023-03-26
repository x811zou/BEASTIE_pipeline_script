#!/bin/bash
#SBATCH --get-user-env
#SBATCH -c 2
#SBATCH --mem=1G
#SBATCH --mail-user=xz195@duke.edu
#SBATCH --mail-type=FAIL
#SBATCH --out=log/f%j.out
#SBATCH --error=log/%j.out
#SBATCH -p scavenger
#SBATCH --time=02:00:00
#SBATCH --oversubscribe
#SBATCH --no-requeue

############### testing command
# sbatch -p common ../script/RNAseq-analysis/pipeline_scripts/0_filter_vcf.slurm 122687_merged /datacommons/allenlab/scarlett/data/VCF/GSD/DNA_vcf /hpc/group/allenlab/scarlett/output/RNAseq/GSD/122687_merged/tmp/VCF /hpc/group/allenlab/scarlett/output/RNAseq/GSD/122687_merged/tmp/VCF/122687_merged.no_chr.SNPs.hets.vcf.gz
###############

if [ -n "$SLURM_JOB_ID" ] ; then
    script_path=$(realpath $(scontrol show job $SLURM_JOBID | awk -F= '/Command=/{print $2}' | cut -d' ' -f1 ))
else
    script_path=$(realpath $0)
fi
scripts_dir=$(dirname "$script_path")

source $scripts_dir/setup.sh

set -e
set -u
set -x
# read input
sample=$1
if [ "$sample" == "122687_merged" ]; then
    sample_vcf="122687"
else 
    sample_vcf=$sample
fi
input_vcfgz=$2
tmp_dir=$3
bi_vcfgz=$4
bihet_vcfgz=$5
pass=$6

threads=$SLURM_CPUS_ON_NODE

if [[ -s $bi_vcfgz ]] && [[ -s $bihet_vcfgz ]]; then
    if [[ $(zcat "$bi_vcfgz" | head -n20 | wc -l) -gt 11 ]] && [[ $(zcat "$bihet_vcfgz" | head -n20 | wc -l) -gt 11 ]]; then
        echo "both output files exist- skipping"
        exit
    else
        rm ${bihet_vcfgz}*
        rm ${bi_vcfgz}*
    fi
fi

now=$(date +"%T")
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> start with ${sample} :"${now}

mkdir -p $tmp_dir

if [[ "$pass" = true ]]; then
    bgzip -@ $threads -cd $input_vcfgz \
        | grep -v '^#' \
        | awk -v OFS='\t' 'sub(/:.*/,"",$10)  && length($4)==1 && length($5)==1 && $7=="PASS" && ($10=="1/0" || $10== "0/1" || $10=="1|0" || $10=="0|1")' \
        | awk '{gsub(/\chr/, "")}1' \
        > $tmp_dir/tmp.content.vcf
    #wc -l $output_dir/tmp.content.vcf.gz
    zcat $input_vcfgz | grep '^#' > $tmp_dir/tmp.header.vcf
    cat $tmp_dir/tmp.header.vcf $tmp_dir/tmp.content.vcf > $tmp_dir/${sample}.no_chr.content.SNPs.hets.vcf
    ######################################### zip & index VCF
    bgzip -@2 -c -f $tmp_dir/${sample}.no_chr.content.SNPs.hets.vcf > $bihet_vcfgz && tabix -fp vcf $bihet_vcfgz


    bgzip -@ $threads -cd $input_vcfgz \
        | grep -v '^#' \
        | awk -v OFS='\t' 'sub(/:.*/,"",$10)  && length($4)==1 && length($5)==1 && $7=="PASS"' \
        > $tmp_dir/tmp.content.all.vcf
else
    echo "needs code for filtering without PASS"
fi

#wc -l $output_dir/tmp.content.vcf.gz
cat $tmp_dir/tmp.header.vcf $tmp_dir/tmp.content.all.vcf > $tmp_dir/${sample}.no_chr.content.SNPs.vcf
######################################### zip & index VCF
bgzip -@2 -c -f $tmp_dir/${sample}.no_chr.content.SNPs.vcf > $bi_vcfgz && tabix -fp vcf $bi_vcfgz

now=$(date +"%T")
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> done with ${sample} :"${now}


