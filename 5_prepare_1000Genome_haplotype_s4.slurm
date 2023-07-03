#!/bin/bash
#SBATCH --get-user-env
#SBATCH -c 1
#SBATCH --mem=2G
#SBATCH --mail-user=xz195@duke.edu
#SBATCH --mail-type=FAIL
#SBATCH --out=log/%j.out
#SBATCH --error=log/%j.out
#SBATCH --time=24:00:00
#SBATCH --no-requeue

############### testing command
# sample=NA12878 #
# ref_sample=/datacommons/allenlab/scarlett/reference/shapeit2/1000GP_Phase3/1000GP_Phase3/1000GP_Phase3.sample
# ref_dir=/datacommons/allenlab/scarlett/reference/shapeit4/reference/all
# out_dir=/hpc/group/allenlab/scarlett/output/RNAseq/GIAB/NA12878/tmp/shapeit4/modified_haplotype
# sbatch /hpc/group/allenlab/scarlett/github/BEASTIE_pipeline_script/5_prepare_1000Genome_haplotype_s4.slurm $sample $ref_sample $ref_dir $out_dir
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

# specify parameters
sample=$1
ref_sample=$2
ref_dir=$3
out_dir=$4

# check output file existence
if [ -d "$out_dir" ]; then
    echo "$out_dir exists"
    exit
fi

# create new directories
tmp_out_dir=${out_dir}.tmp
mkdir -p $tmp_out_dir

# I. create modified reference sample/haplotype
modified_sample=$tmp_out_dir/1000GP_Phase3.sample
# II. create modified sample: extract the line with sample from 1000 genome reference panel 2505 individuals, remove this line from sample file
index=$(cat ${ref_sample} | grep -n ${sample} | head -n1 | cut -d: -f 1)
sed -e "${index}d" ${ref_sample} > $modified_sample

# II. prepare, check and run shapeit2:
preparation_job_ids=()
for N in {1..22}
do
    ref_haplotype=$ref_dir/*chr${N}.*.vcf.gz
    modified_haplotype=$tmp_out_dir/1000GP_Phase3_chr${N}_rm${sample}.vcf.gz
    prep_job_id=$(sbatch --parsable \
        --job-name=${sample}-modify-1000genome-haplotype-chr${N}-s4 \
        $scripts_dir/5__create_modified_hap_chrom_s4.slurm \
        $ref_haplotype $modified_haplotype $N $index \
    )
    preparation_job_ids+=( $prep_job_id )
done

wait_for_jobs ${preparation_job_ids[@]} || exit 1

mv $tmp_out_dir $out_dir
echo "done"
