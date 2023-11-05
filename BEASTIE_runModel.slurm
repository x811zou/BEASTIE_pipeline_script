#!/bin/bash
#SBATCH --job-name=BEASTIE
#SBATCH --mail-user=xz195@duke.edu
#SBATCH --mail-type=FAIL
#SBATCH --mem=8G
#SBATCH --time=8:00:00
#SBATCH -c 4 
#SBATCH --output=log/%J.out
#SBATCH --error=log/%J.out
#SBATCH -p scavenger

##### testing commands
# sample=SPAG1-9806
# ancestry=EUR
# working_dir=/data/reddylab/scarlett/output/SPAG1-9806
# beastie_dir=$working_dir/beastie
# input_vcfgz=$working_dir/${sample}.no_chr.content.SNPs.hets.filtered.vcf.gz
# chr_start=1
# chr_end=22
# sigma=0.7
# read_length=150
# output_dir=$beastie_dir/runModel_vcf_even${read_length}
# input_simulation_pileup=$working_dir/${sample}.simulation_even_150.pileup.gz
# filtered_hetSNP_file=$working_dir/${sample}_hetSNP_filtered.tsv
# modelname="iBEASTIE4"
# sbatch -c 4 --mem=16G -p all --job-name=BEASTIE-${sample} /data/allenlab/scarlett/github/BEASTIE_pipeline_script/BEASTIE_runModel.slurm $input_vcfgz $sample $ancestry $output_dir 1 22 $sigma $read_length $filtered_hetSNP_file $modelname False $input_simulation_pileup


if [ -n "$SLURM_JOB_ID" ] ; then
    script_path=$(realpath $(scontrol show job $SLURM_JOBID | awk -F= '/Command=/{print $2}' | cut -d' ' -f1 ))
else
    script_path=$(realpath $0)
fi
scripts_dir=$(dirname "$script_path")

source $scripts_dir/setup.sh
source $scripts_dir/helpers.sh

set -e
set -u

input_vcfgz=$1
sample_name_in_vcf=$2
ancestry=$3
output_dir=$4
chr_start=${5}
chr_end=${6}
sigma=${7}
read_length=${8}
filtered_hetSNP_file=${9}
modelname=${10}
nophasing=${11-}
input_simulation_pileup=${12-}
input_shapeit2=${13-}
LD_token=${14-}

# parameters set
min_single_count=0
min_total_count=1
binomialp_cutoff=0.05
ASE_cutoff=0.5

simulation_arg=""
if [ -n "$input_simulation_pileup" ]; then
    simulation_arg="--simulation-pileup-file $input_simulation_pileup"
fi

shapeit2_arg=""
if [ -n "$input_shapeit2" ]; then
    shapeit2_arg="--shapeit2-phasing-file $input_shapeit2"
fi

nophasing_arg=""
if [ "$nophasing" = "True" ]; then
    nophasing_arg="--nophasing $nophasing"
fi

stan_path="/usr/local/bin"
if [ "$modelname" != "iBEASTIE3" ]; then
    stan_path="/hpc/group/allenlab/scarlett/github/RNAseq-analysis/stan_models/"
fi

ld_token_arg=""
if [ -n "$LD_token" ]; then
    ld_token_arg="--ld-token $LD_token"
fi

mkdir -p $output_dir

save_intermediate_option="--save-intermediate"

final_output_pickle=$output_dir/chr1-22_alignBiasp0.05_s${sigma}_a0.05_sinCov0_totCov1_W1000K1000/$modelname/output_pkl/iBEASTIE/theta/stan.pickle
if [ -s "$final_output_pickle" ]; then
    echo "$final_output_pickle exists"
    exit
fi

run_beastie_image \
    runModel \
    --vcfgz-file $input_vcfgz \
    --vcf-sample-name $sample_name_in_vcf \
    --filtered-het-snp-file $filtered_hetSNP_file \
    --ancestry $ancestry \
    --chr-start $chr_start \
    --chr-end $chr_end \
    --min-single-cov $min_single_count \
    --min-total-cov $min_total_count \
    --read-length $read_length \
    --output-dir $output_dir \
    ${save_intermediate_option} \
    --alignBiasP-cutoff $binomialp_cutoff \
    --ase-cutoff $ASE_cutoff \
    $ld_token_arg \
    --model $modelname \
    --gam-model-name iBEASTIE4_s0.7_GAM/gam4_lambdamodel.pkl \
    --sigma $sigma \
    $shapeit2_arg \
    $simulation_arg \
    $nophasing_arg \
    --ldlink-cache-dir /data/allenlab/scarlett/pipeline_working/beastie_cache \
    --ldlink-token-db /data/allenlab/scarlett/pipeline_working/beastie_cache/ldlink_tokens.db

