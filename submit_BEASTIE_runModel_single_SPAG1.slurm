#!/bin/bash
#SBATCH --job-name=submit-BEASTIE-SPAG1-original
#SBATCH --mem=512M
#SBATCH -c 1
#SBATCH --mail-type=END,FAIL
#SBATCH --oversubscribe
#SBATCH -p all
#SBATCH --no-requeue
#SBATCH --dependency=singleton
#SBATCH --out=log/%j.out
#SBATCH --error=log/%j.out

########### testing commands
# sbatch /data/allenlab/scarlett/github/BEASTIE_pipeline_script/submit_BEASTIE_runModel_single_SPAG1.slurm
###########

if [ -n "$SLURM_JOB_ID" ] ; then
    script_path=$(realpath $(scontrol show job $SLURM_JOBID | awk -F= '/Command=/{print $2}' | cut -d' ' -f1 ))
else
    script_path=$(realpath $0)
fi
scripts_dir=$(dirname "$script_path")

source $scripts_dir/setup.sh

hostname 1>&2
set -x
set -u
set -e

function submit_and_wait_sample() {
    sample=$1
    source $scripts_dir/setup.sh
    source $scripts_dir/helpers.sh
    echo "submitting pipeline for $sample"

    ### Please change here for your sample: HG00096
    chr_start=1
    chr_end=22
    read_length=150
    simulation_length=150
    working_dir=/data/reddylab/scarlett/output/$sample
    raw_fq_dir=/data/cegs_ccgr/data/raw/RNAseq/Azenta_30-803694728_mget/$sample
    email=xue.zou@duke.edu
    partition=all

    ### Please do not change below this line
    modelname="iBEASTIE3"
    sigma=0.7
    ancestry="EUR"
    beastie_dir=$working_dir/beastie
    input_vcfgz=$working_dir/${sample}.no_chr.content.SNPs.hets.filtered.vcf.gz
    output_dir=$beastie_dir/runModel_phased_even${simulation_length}
    input_simulation_pileup=$working_dir/${sample}.simulation_even_${simulation_length}.pileup.gz
    filtered_hetSNP_file=$working_dir/${sample}_hetSNP_filtered.tsv
    #input_shapeit2=$working_dir/${sample}.shapeit.tsv
    
    job_id=$(sbatch \
        --parsable \
        --job-name=${sample}-${ancestry}-${modelname}-sigma${sigma} \
        --mail-user=$email \
        -p $partition \
        $scripts_dir/BEASTIE_runModel.slurm \
        $input_vcfgz $sample $ancestry $output_dir $chr_start $chr_end $sigma $read_length $filtered_hetSNP_file $modelname False $input_simulation_pileup
    )

    wait_for_jobs $job_id
    echo "finished $sample"

}
export -f submit_and_wait_sample
export scripts_dir

samples="SPAG1-9806"
parallel \
    -j 1 \
    --delay 1 \
    -v --line-buffer \
    submit_and_wait_sample \
    ::: $samples
