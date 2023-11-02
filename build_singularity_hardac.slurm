#!/bin/bash
#SBATCH --get-user-env
#SBATCH -p all
#SBATCH --mem=32G
#SBATCH -c 4
#SBATCH --mail-user=xz195@duke.edu
#SBATCH --mail-type=FAIL 
#SBATCH --out=/data/allenlab/scarlett/pipeline_working/log/%j.out 
#SBATCH --error=/data/allenlab/scarlett/pipeline_working/log/%j.out
#sbatch /hpc/group/allenlab/scarlett/singularity_beastie/build_singularity.slurm
singularity build -s /data/allenlab/scarlett/BEASTIE-`date -Isec`.sif docker://xuezou/beastie
