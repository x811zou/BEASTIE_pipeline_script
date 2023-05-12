#!/bin/bash
#SBATCH --job-name=submit-pipelines-1000Genome
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
### commands with a specific sample name
# sbatch /hpc/group/allenlab/scarlett/github/BEASTIE_pipeline_script/submit_pipelines.slurm
### commands with a specific ancestry
# sbatch /hpc/group/allenlab/scarlett/github/BEASTIE_pipeline_script/submit_pipelines.slurm CEU
###########

###########  1000 Genome samples
ancestry=${1-}
# Utan, British, Yoruba, Tuscan, Finnish
#file=$path/British.txt GBR #188/2=94 #8-86-86 HG00104 HG00124 HG00134 HG00135 HG00152 HG00156 HG00247 HG00249
#file=$path/Finnish.txt FIN #190/2=95 #3-92-92 HG00312 HG00359 HG00377
#file=$path/Tuscan.txt  TSI #186/2=93 #2-91-91 NA20537 NA20816
#file=$path/Utah.txt    CEU #182/2=91 #2-89-89 NA11993 NA07346
#file=$path/Yoruba.txt  YRI #178/2=89 #2-87-87 NA18487 NA19150
# 94+95+93+91+89 = 465 - (9+3+3+2+2) = 445 | 445

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


ancestry_arg=""
if [ -n "$ancestry" ]; then
    ancestry_arg=$ancestry
    echo "We are processing smaples from ancestry: $ancestry_arg"
    path=/datacommons/allenlab/scarlett/data/fastq/1000Genome
    file=$path/${ancestry}.txt
    start=1
    count=100
    samples=$(cat ${file} | awk '{print $1}' | uniq | tail -n+${start} | head -n $count)
fi

function submit_and_wait_sample() {
    sample=$1
    source $scripts_dir/setup.sh
    source $scripts_dir/helpers.sh
    echo "submitting pipeline for $sample"
    
    ### Please change here for your sample: GIAB
    postfix="1000Genome"
    echo ">>> 1000 genome sample!"
    base_working_dir=/hpc/group/allenlab/scarlett/output/RNAseq/1000Genome
    # base_working_dir=/work/xz195 (only choose this when I want to run multiple samples at one time)
    vcf_dir=/datacommons/allenlab/scarlett/data/VCF/1000_genome/20130502/bgzip
    raw_fq_dir=/datacommons/allenlab/scarlett/data/fastq/1000Genome/$sample
    read_length=75
    simulation_depth=100
    raw_fq_fwd=$(ls $raw_fq_dir/*_1.fastq.gz)
    raw_fq_rev=$(ls $raw_fq_dir/*_2.fastq.gz)
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
    ancestry=$(get_ancestry $raw_fq_dir)
    sex=$(get_sex $raw_fq_dir)

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
        --is-1000Genome
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
samples="NA18934"
parallel \
    -j 10 \
    --delay 1 \
    -v --line-buffer \
    submit_and_wait_sample \
    ::: $samples

#start 10 samples,submit each one after 1s of submitting the previous one
