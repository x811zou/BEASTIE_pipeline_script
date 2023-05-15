#!/bin/bash
#SBATCH --job-name=submit-BEASTIE-GIAB
#SBATCH --mem=512M
#SBATCH -c 1
#SBATCH --mail-type=END,FAIL
#SBATCH --oversubscribe
#SBATCH --no-requeue
#SBATCH --dependency=singleton
#SBATCH --out=log/%j.out
#SBATCH --error=log/%j.out

########### testing commands
# sbatch /hpc/group/allenlab/scarlett/github/BEASTIE_pipeline_script/submit_BEASTIE_runModel_single_GIAB.slurm
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

    ### Please change here for your sample: HG00096
    chr_start=1
    chr_end=22
    read_length=101
    simulation_length=101
    working_dir=/hpc/group/allenlab/scarlett/output/RNAseq/GIAB/NA12878
    raw_fq_dir=/datacommons/allenlab/scarlett/data/fastq/NA12878
    email=xue.zou@duke.edu

    ### Please do not change below this line
    modelname="iBEASTIE3"
    sigma=0.5
    ancestry="CEU"
    beastie_dir=$working_dir/beastie
    input_vcfgz=$working_dir/${sample}.no_chr.content.SNPs.hets.filtered.vcf.gz
    output_dir=$beastie_dir/runModel_phased_even${simulation_length}
    input_simulation_pileup=$working_dir/${sample}.simulation_even_${simulation_length}.pileup.gz
    filtered_hetSNP_file=$working_dir/${sample}_hetSNP_filtered.tsv
    input_shapeit2=$working_dir/${sample}.shapeit.tsv
    
    job_id=$(sbatch \
        --parsable \
        --job-name=${sample}-${ancestry}-${modelname}-sigma${sigma} \
        --mail-user=$email \
        $scripts_dir/BEASTIE_runModel.slurm \
        $input_vcfgz $sample $ancestry $output_dir $chr_start $chr_end $sigma $read_length $filtered_hetSNP_file $modelname False $input_simulation_pileup $input_shapeit2
    )

    wait_for_jobs $job_id
    echo "finished $sample"

}
export -f submit_and_wait_sample
export scripts_dir

samples="NA12878"
parallel \
    -j 1 \
    --delay 1 \
    -v --line-buffer \
    submit_and_wait_sample \
    ::: $samples
