#!/bin/bash
#SBATCH --job-name=run-shapeit4
#SBATCH --get-user-env
#SBATCH -c 1
#SBATCH --mem=2G
#SBATCH --mail-user=xz195@duke.edu
#SBATCH --mail-type=FAIL
#SBATCH --out=log/%j.out
#SBATCH --error=log/%j.out
#SBATCH -p scavenger
#SBATCH --time=24:00:00
#SBATCH --no-requeue

############### testing command
# sbatch -p scavenger ../script/RNAseq-analysis/pipeline_scripts2/5_run_shapeit4.slurm NA12878 /hpc/group/allenlab/scarlett/output/RNAseq/GIAB/NA12878/tmp/shapeit4 /hpc/group/allenlab/scarlett/output/RNAseq/GIAB/NA12878/tmp/VCF/tmp.header.vcf /hpc/group/allenlab/scarlett/output/RNAseq/GIAB/NA12878/NA12878.no_chr.content.SNPs.hets.filtered.vcf.gz /hpc/group/allenlab/scarlett/output/RNAseq/GIAB/NA12878/NA12878.shapeit4.tsv /hpc/group/allenlab/scarlett/output/RNAseq/GIAB/NA12878/tmp/shapeit4/modified_ref
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
tmp_dir=$2
header_vcf=$3
vcfgz=$4
out_shapeit4=$5
ref_dir=$6
# check output file existence
if [ -s "$out_shapeit4" -a -s "$vcfgz" ]; then
    echo "$out_shapeit4 exists and non-empty, newer than $vcfgz."
    exit
fi

# create new directories
mkdir -p $tmp_dir

now=$(date +"%T")
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> start with ${sample} :"${now}

# II.check and run shapeit2:
job_ids=()
for N in {1..22}
do
    ref=$ref_dir/chr${N}.vcf.gz
    job_id=$(sbatch --parsable \
        --job-name=${sample}-shapeit4-run-chr${N} \
        $scripts_dir/5__run_shapeit4_chrom.slurm \
        $sample $tmp_dir $header_vcf $vcfgz $N $ref \
    )
    job_ids+=( $job_id )
done

now=$(date +"%T")
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> waiting for chromosomes:" ${now}

wait_for_jobs ${job_ids[@]} || exit 1

job_ids2=()
for N in {1..22}
do
    job_id2=$(sbatch --parsable \
        --job-name=${sample}-shapeit4-finish-chr${N} \
        $scripts_dir/5__clean_shapeit4_chrom.slurm \
        $sample $tmp_dir $N \
    )
    job_ids2+=( $job_id2 )
done

wait_for_jobs ${job_ids2[@]} || exit 1

now=$(date +"%T")
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> done processing chromosomes ${sample} :"${now}

# III. combine shapeit2 result:sort the pos for each chromosome output, and then concatenate them in order
header='chr pos ref alt e_paternal e_maternal'
tmp_output=$tmp_dir/combined
cat $tmp_dir/chr{1..22}.phased.cleaned.vcf > $tmp_output
sed -i 's/^/chr/' $tmp_output
cat <(echo "$header") $tmp_output > $tmp_output
mv $tmp_output $out_shapeit4

now=$(date +"%T")
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> done with combining shapeit ${sample} :"${now}
