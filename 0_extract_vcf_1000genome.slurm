#!/bin/bash
#SBATCH --get-user-env
#SBATCH -c 1
#SBATCH --mem=1G
#SBATCH --mail-user=xz195@duke.edu
#SBATCH --mail-type=FAIL
#SBATCH --out=log/%j.out
#SBATCH --error=log/%j.out
#SBATCH -p scavenger
#SBATCH --time=02:00:00
#SBATCH --oversubscribe
#SBATCH --no-requeue

############### testing command
# sbatch -p common ../script/RNAseq-analysis/pipeline_scripts/0_extract_vcf.slurm NA06989 /hpc/group/allenlab/scarlett/output/RNAseq/NA06989/tmp/VCF /datacommons/allenlab/scarlett/data/VCF/1000_genome/20130502/bgzip/
###############


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

# read input
sample=$1
tmp_dir=$2
vcf_dir=$3
bi_vcfgz=$4
bihet_vcfgz=$5


if [[ -s $bi_vcfgz ]] && [[ -s $bihet_vcfgz ]]; then
    if [[ $(zcat "$bi_vcfgz" | head -n20 | wc -l) -gt 11 ]] && [[ $(zcat "$bihet_vcfgz" | head -n20 | wc -l) -gt 11 ]]; then
        echo "both output files exist- skipping"
        exit
    else
        rm ${bihet_vcfgz}*
        rm ${bi_vcfgz}*
    fi
fi

mkdir -p $tmp_dir

now=$(date +"%T")
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> start with ${sample} :"${now}

job_ids=()
for N in {1..22} X
do
    input_vcfgz=$vcf_dir/ALL.chr${N}.*.vcf.gz
    output_vcf=$tmp_dir/${sample}_chr${N}.vcf

    output_header_file=""
    if [ $N == 21 ]; then
        output_header_file=$tmp_dir/${sample}_header.vcf
    else
        output_header_file=""
    fi

    job_id=$(sbatch \
        --parsable \
        --job-name=${sample}-extractVCF-chr${N} \
        $scripts_dir/0__extract_vcf_chrom_1000genome.slurm \
        $sample $input_vcfgz $output_vcf $output_header_file \
    )
    job_ids+=( $job_id )
done

combine_job_id=$(sbatch \
    --parsable \
    --kill-on-invalid-dep=yes \
    --dependency=afterok:$(echo "${job_ids[@]}" | tr ' ' ':') \
    --job-name=${SLURM_JOB_NAME}-combine \
    $scripts_dir/0__combine_VCF_1000genome.slurm $sample $tmp_dir $bi_vcfgz $bihet_vcfgz \
)

wait_for_jobs ${job_ids[@]} "$combine_job_id" || exit 1

now=$(date +"%T")
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> done with ${sample} :"${now}
