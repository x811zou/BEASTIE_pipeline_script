#!/bin/bash
#SBATCH --job-name=submit-pipelines-SPAG1-original
#SBATCH --mem=512M
#SBATCH -c 1
#SBATCH --mail-type=END,FAIL
#SBATCH --oversubscribe
#SBATCH --no-requeue
#SBATCH --dependency=singleton
#SBATCH --out=log/%j.out
#SBATCH --error=log/%j.out

########### testing commands
# sbatch /data/allenlab/scarlett/github/BEASTIE_pipeline_script/submit_pipelines_SPAG1.slurm
# JOBID     PARTITION  NAME                                   ST  MIN_MEMORY  TIME_LIMIT    TIME  MIN_CPUS
# 30340858  all        submit-pipelines-SPAG1-original-check  PD  512M        5:00          0:00  1
# 30340863  all        SPAG1-9806-alignment                   PD  150G        2-00:00:00    0:00  8
# 30340864  all        SPAG1-9806-markduplicates-wasp         PD  64G         8:00:00       0:00  6
# 30340865  all        SPAG1-9806-prep-simulation-sam         PD  4G          1-00:00:00    0:00  4
# 30340866  all        SPAG1-9806-check_seqDepth              PD  512M        1:00:00       0:00  4
# 30340868  all        SPAG1-9806-mpileup                     PD  1G          1-00:00:00    0:00  1
# 30340869  all        SPAG1-9806-genotypingEr                PD  8G          8:00:00       0:00  4
# 30340870  all        SPAG1-9806-genotypingEr-filter         PD  1G          8:00:00       0:00  4
# 30340871  all        SPAG1-9806-simulatefastq-even-150      PD  512M        1-00:00:00    0:00  1
# 30340873  all        SPAG1-9806-simulation-alignment        PD  164G        2-00:00:00    0:00  6
# 30340874  all        SPAG1-9806-simulation-mpileup          PD  1G          1-00:00:00    0:00  1
# 30340875  all        SPAG1-9806-EUR-pipeline-check          PD  512M        5:00          0:00  1
# 30340872  all        SPAG1-9806-shapeit2                    PD  2G          1-00:00:00    0:00  1
# 30340856  all        submit-pipelines-SPAG1-original        R   512M        365-00:00:00  5:51  1
# 30340857  all        SPAG1-9806-EUR-pipeline                R   512M        1-12:00:00    5:21  1
# 30340862  all        SPAG1-9806-trimFastq                   R   5G          8:00:00       4:51  6
# 30340867  all        SPAG1-9806-hetSNP                      R   2G          8:00:00       3:51  1
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

    postfix=$sample
    echo ">>> $postfix sample!"
    ancestry="EUR" #GBR,TSI,FIN,CEU
    sex="female"
    base_working_dir=/data/reddylab/scarlett/output/
    vcf_dir=/data/cegs_ccgr/data/raw/wes_vcf/M2780_exome_calls.vcf.gz
    ##### SPAG polyA 
    #raw_fq_dir=/data/cegs_ccgr/data/raw/RNAseq/Azenta_30-835516727
    ##### SPAG original
    raw_fq_dir=/data/cegs_ccgr/data/raw/RNAseq/Azenta_30-803694728_mget/$sample
    read_length=150
    simulation_depth=150 #>=100
    raw_fq_fwd=$(ls $raw_fq_dir/${postfix}*R1*fastq.gz)
    raw_fq_rev=$(ls $raw_fq_dir/${postfix}*R2*fastq.gz)
    email=xz195@duke.edu
    partition=all
    ### Please do not change below this line
    working_dir=$base_working_dir/$sample
    success_file=$working_dir/success

    job_id=$(sbatch \
        --parsable \
        --job-name=${sample}-${ancestry}-pipeline \
        -p $partition \
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
        --keep-tmp \
        --hardac \
    )

    wait_for_jobs $job_id
    echo "finished $sample"
}
export -f submit_and_wait_sample
export scripts_dir
export -f wait_for_jobs

### Please check carefully for your sample. If you have question, please email xue.zou@duke.edu
# --highcoverage     --> default: raw fastq reads coverage <= 75bp. parameters for memory usage is relatively low. 
# --is-1000Genome    --> default: individual sample
# --is-GIAB          --> default: other sample. Only GIAB sample will run shapeit4 phasing
# --simulate-hetSNPs --> default: only mutate het SNPs (which is not recommended)
# --keep-tmp         --> default: remove tmp directory
# --random           --> default: even haplotype mode so that p = 0.5
# --force            --> default: check success file
# --noPASSfilter     --> default: there is PASS filter in VCF (SNPs will be filtered by quality score > 10 based on UDN sample)
# --hardac           --> default: DCC partition "scavenger". Hardac parition "all". (If else, change it in full_pipeline2.slurm)
# --email            --> default: xz195@duke.edu. (Change it to your email address.)

samples="SPAG1-9806" #"SPAG1-9806_polyA"
parallel \
    -j 1 \
    --delay 1 \
    -v --line-buffer \
    submit_and_wait_sample \
    ::: $samples

