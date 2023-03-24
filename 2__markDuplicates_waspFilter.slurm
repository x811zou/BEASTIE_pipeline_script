#!/bin/bash
#SBATCH --job-name=markDuplicates
#SBATCH --mem=64G
#SBATCH -c 6
#SBATCH --mail-user=xz195@duke.edu
#SBATCH --mail-type=FAIL
#SBATCH --out=log/%j.out
#SBATCH --error=log/%j.out
#SBATCH -p scavenger
#SBATCH --time=8:00:00

############### testing command
# sbatch ../script/RNAseq-analysis/pipeline_scripts/2__markDuplicates_waspFilter.slurm /hpc/group/allenlab/scarlett/output/RNAseq/1000Genome/HG00097/tmp/star_2pass_WASP_m10
###############

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
in_bam=$1
working_dir=$2
out_bam=$3

if [ "$out_bam" -nt "$in_bam" \
    -a -s "$out_bam" \
    -a "${out_bam}.bai" -nt "$out_bam" \
]; then
    echo "$out_bam exists and non-empty, newer than $in_bam."
    exit
fi

echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> start $(date +%T)"

picard_out_bam=$working_dir/Aligned.sortedByCoord.out.picard_markdup.bam

java -Xmx48G \
    -jar $PICARD MarkDuplicates \
    I=$in_bam \
    O=$picard_out_bam \
    M=/dev/null

echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> wasp filtering $(date +%T)"

samtools view -@ $threads -h $picard_out_bam \
    -e '!([vW] >= 2)' -b -o $out_bam
    
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> indexing $(date +%T)"

srun samtools index -@ $threads $out_bam

# echo "Finish filtering"
# echo "Start samtools flagstat for picard"
# srun samtools flagstat $alignedbam_path/Aligned.sortedByCoord.out.picard_markdup.WASP_filtered.bam > $alignedbam_path/flagstat_markdup_picard.txt
# echo "Start counting unique read pair"
# srun samtools view -@ 4 -bh -q 30 -f 3 -F 2316 -c $alignedbam_path/Aligned.sortedByCoord.out.picard_markdup.WASP_filtered.bam
# srun samtools view -@ 4 -bh -q 30 -f 3 -F 3340 -c $alignedbam_path/Aligned.sortedByCoord.out.picard_markdup.WASP_filtered.bam

echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> done $(date +%T)"
