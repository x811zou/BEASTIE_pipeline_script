#!/bin/bash
#SBATCH --job-name=submit-pipelines-UDNtrio
#SBATCH --mem=512M
#SBATCH -c 1
#SBATCH --mail-type=END,FAIL
#SBATCH --oversubscribe
#SBATCH --no-requeue
#SBATCH --dependency=singleton
#SBATCH --out=log/%j.out
#SBATCH --error=log/%j.out

########### testing commands
# sbatch /data/allenlab/scarlett/github/BEASTIE_pipeline_script/submit_pipelines_UDN.slurm
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
    # if [[ "$sample" = "UDN042246-P" ]]; then
    #     vcf_sample="894124-UDN042246"
    # fi
    # if [[ "$sample" = "UDN205393-F" ]]; then
    #     vcf_sample="894126-UDN205393"
    # fi
    # if [[ "$sample" = "UDN754343-M" ]]; then
    #     vcf_sample="894125-UDN754343"
    # fi
    source $scripts_dir/setup.sh
    source $scripts_dir/helpers.sh
    echo "submitting pipeline for $sample"

    ### Please change here for your sample: UDN trio
    family="UDN042246_family"
    echo ">>> $family samples!"
    ancestry="CEU"
    sex="X" # this does not matter
    base_working_dir=/data/reddylab/scarlett/output/UDN/$family
    vcf_dir=/data/reddylab/UDN/rawdata/vcf/$family/${sample}.vcf.gz
    raw_fq_dir=/data/reddylab/UDN/rawdata/fastq/$family/$sample
    read_length=150
    simulation_depth=150
    raw_fq_fwd=$(ls $raw_fq_dir/*_R1.fastq.gz)
    raw_fq_rev=$(ls $raw_fq_dir/*_R2.fastq.gz)
    email=xz195@duke.edu
    partition=all

    ### Please do not change below this line
    working_dir=$base_working_dir/$sample
    success_file=$working_dir/success

    job_id=$(sbatch \
        --parsable \
        --job-name=${sample}-${ancestry}-${family}-pipeline \
        -p $partition \
        $scripts_dir//full_pipeline2.slurm \
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
        --noPASSfilter \
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

########### UDN
#UDN042246_family=["UDN042246-P","UDN205393-F","UDN754343-M"]

samples="UDN205393-F UDN754343-M UDN042246-P" 
parallel \
    -j 3 \
    --delay 1 \
    -v --line-buffer \
    submit_and_wait_sample \
    ::: $samples