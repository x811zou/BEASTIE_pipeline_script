#!/bin/bash
#SBATCH --job-name=move-files-NA
#SBATCH --mem=10G
#SBATCH -c 4
#SBATCH --mail-type=END,FAIL
#SBATCH -p scavenger
#SBATCH --oversubscribe
#SBATCH --no-requeue
#SBATCH --dependency=singleton
#SBATCH --out=log/%j.out
#SBATCH --error=log/%j.out

module load Parallel
hostname 1>&2
set -e
set -u

########### testing commands
# sbatch ../script/RNAseq-analysis/pipeline_scripts2/move_files.slurm
###########
mv /work/xz195/NA* /hpc/group/allenlab/scarlett/output/RNAseq/1000Genome/.