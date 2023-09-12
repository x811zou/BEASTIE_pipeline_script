#!/bin/bash
#SBATCH --get-user-env
#SBATCH -p scavenger
#SBATCH --mem=32G
#SBATCH -c 4
#SBATCH --mail-user=xz195@duke.edu
#SBATCH --mail-type=FAIL 
#SBATCH --out=/hpc/group/allenlab/scarlett/pipeline_working/log/%j.out 
#SBATCH --error=/hpc/group/allenlab/scarlett/pipeline_working/log/%j.out
#sbatch /hpc/group/allenlab/scarlett/singularity_beastie/build_singularity.slurm
singularity build -s /hpc/group/allenlab/scarlett/singularity_beastie/BEASTIE-`date -Isec`.sif docker://xuezou/beastie
