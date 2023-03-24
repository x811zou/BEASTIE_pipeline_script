#!/bin/bash
#SBATCH --job-name=step3-samtools-mpileup
#SBATCH --mem=1G
#SBATCH --mail-user=xz195@duke.edu
#SBATCH --mail-type=FAIL
#SBATCH --time=24:00:00
#SBATCH -c 1
#SBATCH --out=log/%j.out
#SBATCH --error=log/%j.out
#SBATCH -p scavenger
#SBATCH --oversubscribe
#SBATCH --no-requeue

###### testing commands
# sample="NA12878"
# tmp_dir=/hpc/group/allenlab/scarlett/output/RNAseq/for_verification/new
# save_dir=$tmp_dir/mpileup
# hetSNP=/hpc/group/allenlab/scarlett/output/RNAseq/GIAB/NA12878/NA12878_hetSNP.tsv
# bam=$tmp_dir/star_2pass_WASP_m10/Aligned.sortedByCoord.out.bam
# pileup=$tmp_dir/NA12878.pileup.gz
# ref=/datacommons/allenlab/scarlett/reference/hg19/hg19.fa
# sbatch ../script/RNAseq-analysis/pipeline_scripts/3_samtools_mpileup.slurm $sample $tmp_dir $save_dir $hetSNP $bam $pileup $ref
######

if [ -n "$SLURM_JOB_ID" ] ; then
    script_path=$(realpath $(scontrol show job $SLURM_JOBID | awk -F= '/Command=/{print $2}' | cut -d' ' -f1 ))
else
    script_path=$(realpath $0)
fi
scripts_dir=$(dirname "$script_path")

source $scripts_dir/setup.sh
source $scripts_dir/helpers.sh

set -e
set -u

# read input
sample=$1
tmp_dir=$2
save_dir=$3
hetSNP=$4
bam=$5
output_file=$6
ref=$7

# check 
if [ -s "$output_file" ]; then
    echo "$output_file exists."
    exit
fi

mkdir -p $save_dir
now=$(date +"%T")
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> start with ${sample} :"${now}

# II. loop through 22 chromosome
job_ids=()
for N in {1..22}
do
        output=${save_dir}/${sample}_chr${N}.pileup
        job_id=$(sbatch --parsable \
		    --job-name=${SLURM_JOB_NAME}-chr${N} \
            $scripts_dir/3__samtools_mpileup_chrom.slurm \
            $hetSNP $bam $output $N $ref \
        )
        job_ids+=( $job_id )
done

# wait for all jobs to complete
wait_for_jobs ${job_ids[@]} || exit 1

now=$(date +"%T")
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> done with all chromosomes :"${now}

# III. combine fastq
combined_tmp=$save_dir/combined.gz
#cat $tmp_dir/${sample}_chr{1..22}.pileup $tmp_dir/${sample}_chrX.pileup | bgzip -c > $combined_tmp
cat $save_dir/${sample}_chr{1..22}.pileup | bgzip -@ $threads -l3 -c > $combined_tmp
mv $combined_tmp $output_file

now=$(date +"%T")
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> done with ${sample} :"${now}
