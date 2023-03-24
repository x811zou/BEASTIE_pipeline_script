#!/bin/bash
#SBATCH --job-name=check_seqDepth
#SBATCH --mem=512M
#SBATCH -c 4
#SBATCH --mail-user=xz195@duke.edu
#SBATCH --mail-type=FAIL
#SBATCH --out=log/%j.out
#SBATCH --error=log/s%j.out
#SBATCH -p scavenger
#SBATCH --time=1:00:00

############### testing command
# working_dir=/hpc/group/allenlab/scarlett/output/RNAseq/1000Genome/HG00097
# sbatch ../script/RNAseq-analysis/pipeline_scripts/2__check_seqDepth.slurm $working_dir
###############
# https://www.metagenomics.wiki/tools/samtools/number-of-reads-in-bam-file

if [ -n "$SLURM_JOB_ID" ] ; then
    script_path=$(realpath $(scontrol show job $SLURM_JOBID | awk -F= '/Command=/{print $2}' | cut -d' ' -f1 ))
else
    script_path=$(realpath $0)
fi
scripts_dir=$(dirname "$script_path")

source $scripts_dir/setup.sh

hostname 1>&2
set -e
set -u

# read input
in_dir=$1 # $tmp_dir/star_2pass_WASP_m10
out_dir=$2

unfiltered_total_seqDepth_file=$out_dir/unfiltered_total_seqDepth
unfiltered_mapped_seqDepth_file=$out_dir/unfiltered_mapped_seqDepth
WASPfiltered_total_seqDepth_file=$out_dir/filtered_total_seqDepth
WASPfiltered_mapped_seqDepth_file=$out_dir/filtered_mapped_seqDepth

echo "$(date +%T) start!"

# samtools command
# ## get the total number of reads of a BAM file (may include unmapped and duplicated multi-aligned reads)
# samtools view -c $in_dir/Aligned.sortedByCoord.out.picard_markdup.bam > $unfiltered_total_seqDepth_file &
# ## counting only mapped (primary aligned) reads
# samtools view -c -F 260 $in_dir/Aligned.sortedByCoord.out.picard_markdup.bam > $unfiltered_mapped_seqDepth_file &
## get the total number of reads of a BAM file (may include unmapped and duplicated multi-aligned reads)
samtools view --threads $threads -c $in_dir/Aligned.sortedByCoord.out.picard_markdup.WASP_filtered.bam > $WASPfiltered_total_seqDepth_file &
## counting only mapped (primary aligned) reads
samtools view --threads $threads -c -F 260 $in_dir/Aligned.sortedByCoord.out.picard_markdup.WASP_filtered.bam > $WASPfiltered_mapped_seqDepth_file &

wait

echo "$(date +%T) done!"