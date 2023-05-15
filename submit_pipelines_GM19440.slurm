#!/bin/bash
#SBATCH --job-name=submit-pipelines-experimentalVCF
#SBATCH --mem=512M
#SBATCH -c 1
#SBATCH --mail-type=END,FAIL
#SBATCH -p scavenger
#SBATCH --oversubscribe
#SBATCH --no-requeue
#SBATCH --dependency=singleton
#SBATCH --out=log/%j.out
#SBATCH --error=log/%j.out

########### testing commands
# sbatch /hpc/group/allenlab/scarlett/github/BEASTIE_pipeline_script/submit_pipelines_GM19440.slurm
###########

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


function submit_and_wait_sample() {
    sample=$1
    source $scripts_dir/setup.sh
    source $scripts_dir/helpers.sh
    echo "submitting pipeline for $sample"

    ### Please change here for your sample: GIAB
    postfix=$sample
    ancestry="AFR"
    echo ">>> $postfix sample!"
    base_working_dir=/hpc/group/allenlab/scarlett/output/RNAseq/experimental_VCF/
    vcf_dir=/datacommons/allenlab/scarlett/data/VCF/1000Genomes_10X_28Individuals/$sample/${sample}_phased_variants.vcf.gz
    raw_fq_dir=/datacommons/allenlab/scarlett/data/fastq/$sample
    read_length=0
    simulation_depth=0
    raw_fq_fwd=0
    raw_fq_rev=0
    email=xz195@duke.edu

    ### Please do not change below this line
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

    job_id=$(sbatch \
        --parsable \
        --job-name=${sample}-${ancestry}-pipeline-${postfix} \
        $scripts_dir/full_pipeline2.slurm \
        --sample $sample \
        --ancestry $ancestry \
        --sex "Male" \
        --working-dir $working_dir \
        --vcf-path $vcf_dir \
        --raw-fq-fwd $raw_fq_fwd \
        --raw-fq-rev $raw_fq_rev \
        --fastq-read-length $read_length \
        --simulation-depth $simulation_depth \
        --email $email \
        --VCF-only \
        --keep-tmp \
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

samples="GM19440"
parallel \
    -j 1 \
    --delay 1 \
    -v --line-buffer \
    submit_and_wait_sample \
    ::: $samples

