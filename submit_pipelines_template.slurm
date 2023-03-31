#!/bin/bash
#SBATCH --job-name=submit-pipelines-template
#SBATCH --mem=512M
#SBATCH -c 1
#SBATCH --mail-type=END,FAIL
#SBATCH --oversubscribe
#SBATCH --no-requeue
#SBATCH --dependency=singleton
#SBATCH --out=log/%j.out
#SBATCH --error=log/%j.out

########### testing commands
# sbatch /hpc/group/allenlab/scarlett/github/BEASTIE_pipeline_script/submit_pipelines_template.slurm
###########

if [ -n "$SLURM_JOB_ID" ] ; then
    script_path=$(realpath $(scontrol show job $SLURM_JOBID | awk -F= '/Command=/{print $2}' | cut -d' ' -f1 ))
else
    script_path=$(realpath $0)
fi
scripts_dir=$(dirname "$script_path")

source $scripts_dir/setup.sh
source $scripts_dir/helpers.sh
module load Parallel
hostname 1>&2
set -e
set -u

function submit_and_wait_sample() {
    sample=$1
    source $scripts_dir/setup.sh
    source $scripts_dir/helpers.sh
    echo "submitting pipeline for $sample"
    
    ### Please change here for your sample: GIAB
    postfix= ####
    base_working_dir= ####
    vcf_dir= ####
    raw_fq_dir= ####
    read_length= ####
    simulation_depth= ####
    raw_fq_fwd= ####
    raw_fq_rev= ####
    email= ####
    ancestry= ### 
    sex=  ### 

    ### Please do not change below this line
    echo ">>> $postfix sample!"
    working_dir=$base_working_dir/$sample
    success_file=$working_dir/success
    if [[ -s $success_file ]]; then
        echo "found success file $success_file"
        if [ -d "$working_dir/tmp" ]; then
            echo "tmp dir still exists"
            rmdir $working_dir/tmp
        fi
            echo "tmp dir not exists"
        return 0
    fi

    ### Please review/modify the parameters below
    job_id=$(sbatch \
        --parsable \
        --job-name=${sample}-${ancestry}-pipeline-${postfix} \
        --mail-user=$email \
        $scripts_dir/full_pipeline2.slurm \
        --sample $sample \
        --ancestry $ancestry \
        --sex $sex \
        --working-dir $working_dir \
        --vcf-path $vcf_dir \
        --raw-fq-fwd $raw_fq_fwd \
        --raw-fq-rev $raw_fq_rev \
        --fastq-read-length $read_length \
        --simulation-depth $simulation_depth \
        --email $email \
        # --keep-tmp \
    )

    wait_for_jobs $job_id

    echo "finished $sample"
}
export -f submit_and_wait_sample
export -f get_sex
export -f get_ancestry
export scripts_dir
export -f wait_for_jobs

### Please check carefully for your sample. If you have question, please email xue.zou@duke.edu
# --is-1000Genome    --> default: individual sample
# --is-GIAB          --> default: other sample. Only GIAB sample will run shapeit4 phasing
# --simulate-hetSNPs --> default: only mutate het SNPs (which is not recommended)
# --keep-tmp         --> default: remove tmp directory
# --random           --> default: even haplotype mode so that p = 0.5
# --force            --> default: check success file
# --noPASSfilter     --> default: there is PASS filter in VCF (SNPs will be filtered by quality score > 10 based on SPAG1 sample)
# --hardac           --> default: DCC partition "scavenger". Hardac parition "all". (If else, change it in full_pipeline2.slurm)
# --email            --> default: xz195@duke.edu. (Change it to your email address.)

samples=  ###
parallel \
    -j 1 \
    --delay 1 \
    -v --line-buffer \
    submit_and_wait_sample \
    ::: $samples
