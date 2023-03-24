#!/bin/bash

#SBATCH --job-name=simulation
#SBATCH --mail-user=xz195@duke.edu
#SBATCH --mail-type=FAIL
#SBATCH --mem=4G
#SBATCH --time=24:00:00
#SBATCH --output=log/%j.out
#SBATCH --error=log/%j.out
#SBATCH -c 4
#SBATCH -p scavenger
#sbatch ../script/RNAseq-analysis/pipeline_scripts/6__prep_simulation.slurm /hpc/group/allenlab/scarlett/output/RNAseq/1000Genome/HG00171/tmp/star_2pass_WASP_m10/Aligned.sortedByCoord.out.picard_markdup.WASP_filtered.bam /hpc/group/allenlab/scarlett/output/RNAseq/1000Genome/HG00171/tmp/simulation/input/${sample}.sam.gz

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



bam=$1
out_sam=$2

out_sam_index=$out_sam.tbi

if [ -s "$out_sam" \
    -a -s "$out_sam_index" \
    -a "$out_sam_index" -nt "$out_sam" \
    -a "$out_sam" -nt "$bam" \
]; then
        echo "$out_sam and $out_sam_index already exists."
        exit
fi

echo "$(date +%R) - Start bam to sam conversion"
samtools view -h --threads $threads $bam | bgzip -l3 -@ ${threads} > $out_sam.tmp

mv $out_sam.tmp $out_sam

echo "$(date +%R) - Start tabix indexing"
tabix -p sam $out_sam

echo "$(date +%R) - Done"