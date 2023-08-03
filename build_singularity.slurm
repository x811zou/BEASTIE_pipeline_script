#!/bin/bash
#SBATCH --get-user-env
#SBATCH -p all
#SBATCH --mem=32G
#SBATCH -c 4
#SBATCH --mail-user=xz195@duke.edu
#SBATCH --mail-type=FAIL 
#SBATCH --out=log/%j.out 
#SBATCH --error=log/%j.out
#sbatch /data/allenlab/scarlett/github/BEASTIE_pipeline_script/build_singularity.slurm
singularity build -s /data/allenlab/scarlett/BEASTIE-`date -Isec`.sif docker://xuezou/beastie
