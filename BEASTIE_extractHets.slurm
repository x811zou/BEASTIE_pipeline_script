#!/bin/bash
#SBATCH --job-name=BEASTIE-extractHets
#SBATCH --mail-user=xz195@duke.edu
#SBATCH --mail-type=FAIL
#SBATCH --mem=2G
#SBATCH --time=8:00:00
#SBATCH -c 1
#SBATCH --output=log/%j.out
#SBATCH --error=log/%j.out
#SBATCH -p scavenger

##### testing commands
# sample="UDN042246-P"
# input_vcfgz=/data/reddylab/scarlett/output/UDN/UDN042246_family/${sample}/tmp/${sample}.no_chr.content.SNPs.hets.vcf.gz
# gencode_dir=/data/reddylab/scarlett/reference/beastie_reference/gencode_chr
# output=/data/reddylab/scarlett/output/UDN/UDN042246_family/${sample}/${sample}_hetSNP.tsv
# tmp_dir=/data/reddylab/scarlett/output/UDN/UDN042246_family/${sample}/tmp
# sbatch -c 4 --mem=16G -p all --job-name=BEASTIE-${sampme} /data/allenlab/scarlett/github/BEASTIE_pipeline_script/BEASTIE_extractHets.slurm $sample $input_vcfgz $gencode_dir 1 22 $output $tmp_dir

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

sample=$1
input_vcfgz=$2
gencode_dir=$3
chr_start=$4
chr_end=$5
output=$6
tmp_dir=$7
pass=$8

if [ -s "$output" -a "$output" -nt "$input_vcfgz" ]; then
    if [[ $(cat "$output" | head -n20 | wc -l) -gt 11 ]]; then 
        echo "$output exists and non-empty, newer than $input_vcfgz."
        exit
    fi
fi

pass_arg=""
if [[ "$pass" = false ]]; then
    pass_arg="--skip-require-pass"
fi

now=$(date +"%T")
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> start with ${sample} :"${now}
echo "hetSNP generation for sample"

tmp_output=$tmp_dir/extract_hets.tmp.tsv

run_beastie_image \
    extractHets \
    --vcfgz-file $input_vcfgz \
    --vcf-sample-name $sample \
    --chr-start $chr_start \
    --chr-end $chr_end \
    --gencode-dir $gencode_dir \
    --output $tmp_output \
    $pass_arg

mv $tmp_output $output

now=$(date +"%T")
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> done with ${sample} :"${now}


