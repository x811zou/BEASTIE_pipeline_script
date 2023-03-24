#!/bin/bash
#SBATCH --job-name=submit-pipelines-GIAB
#SBATCH --mem=512M
#SBATCH -c 1
#SBATCH --mail-type=END,FAIL
#SBATCH -p scavenger
#SBATCH --oversubscribe
#SBATCH --no-requeue
#SBATCH --dependency=singleton
#SBATCH --out=log/%j.out
#SBATCH --error=log/%j.out


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

########### testing commands
# sbatch /hpc/group/allenlab/scarlett/github/BEASTIE_pipeline_script/submit_pipelines_GIAB.slurm
###########

function get_ancestry() {
    local raw_fq_dir=$1

    local ancestry_file=$raw_fq_dir/ancestry
    if [ ! -e "$ancestry_file" ]; then
        >&2 echo "Error ancestry file not found at ${ancestry_file}"
        return 5
    fi
    local ancestry=$(cat $ancestry_file)
    if [ -z "$ancestry" ]; then
        >&2 echo "No ancestry data found in file ${ancestry_file}"
        return 5
    fi
    echo "${ancestry}"
}

function get_sex() {
    local raw_fq_dir=$1

    local sex_file=$raw_fq_dir/sex
    if [ ! -e "$sex_file" ]; then
        >&2 echo "Error sex file not found at ${sex_file}"
        return 5
    fi
    local sex=$(cat $sex_file)
    if [ -z "$sex" ]; then
        >&2 echo "No sex data found in file ${sex_file}"
        return 5
    fi
    echo "${sex}"
}

function submit_and_wait_sample() {
    sample=$1

    source $scripts_dir/setup.sh
    source $scripts_dir/helpers.sh

    echo "submitting pipeline for $sample"

    postfix="GIAB"
    echo ">>> GIAB sample!"
    ### GIAB
    base_working_dir=/hpc/group/allenlab/scarlett/output/RNAseq/GIAB
    vcf_dir=/datacommons/allenlab/scarlett/data/VCF/GIAB/NA12878/HG001_GRCh37_GIAB_highconf_CG-IllFB-IllGATKHC-Ion-10X-SOLID_CHROM1-X_v.3.3.2_highconf_PGandRTGphasetransfer.vcf.gz
    raw_fq_dir=/datacommons/allenlab/scarlett/data/fastq/$sample
    read_length=101
    simulation_depth=101

    working_dir=$base_working_dir/$sample
    success_file=$working_dir/success
    
    raw_fq_fwd=$(ls $raw_fq_dir/*_1.fastq.gz)
    raw_fq_rev=$(ls $raw_fq_dir/*_2.fastq.gz)
    ancestry=$(get_ancestry $raw_fq_dir)
    sex=$(get_sex $raw_fq_dir)

    job_id=$(sbatch \
        --parsable \
        --job-name=${sample}-${ancestry}-pipeline-${postfix} \
        /hpc/group/allenlab/scarlett/github/BEASTIE_pipeline_script/full_pipeline2.slurm \
        --sample $sample \
        --ancestry $ancestry \
        --sex $sex \
        --working-dir $working_dir \
        --vcf-path $vcf_dir \
        --raw-fq-fwd $raw_fq_fwd \
        --raw-fq-rev $raw_fq_rev \
        --fastq-read-length $read_length \
        --simulation-depth $simulation_depth \
        --keep-tmp \
    )

    wait_for_jobs $job_id

    echo "finished $sample"
}
export -f submit_and_wait_sample
export -f get_sex
export -f get_ancestry
export scripts_dir
# export -f wait_for_jobs
# options for pipeline
# --is-1000Genome    --> default: individual sample
# --simulate-allSNPs --> default: only mutate het SNPs 
# --keep-tmp         --> default: remove tmp directory2222
# --random           --> default: even haplotype mode so that p = 0.5
# --force            --> default: check success file
samples="NA12878"
parallel \
    -j 1 \
    --delay 1 \
    -v --line-buffer \
    submit_and_wait_sample \
    ::: $samples

#start 20 samples,submit each one after 1s of submitting the previous one
