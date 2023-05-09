#!/bin/bash
#SBATCH --job-name=simulation
#SBATCH --mail-user=xz195@duke.edu
#SBATCH --mail-type=FAIL
#SBATCH --mem=512M
#SBATCH --output=log/%j.out
#SBATCH --error=log/%j.out
#SBATCH -c 1
#SBATCH --time=4:00:00

if [ -n "$SLURM_JOB_ID" ] ; then
    script_path=$(realpath $(scontrol show job $SLURM_JOBID | awk -F= '/Command=/{print $2}' | cut -d' ' -f1 ))
else
    script_path=$(realpath $0)
fi
scripts_dir=$(dirname "$script_path")

source $scripts_dir/setup.sh

set -e
set -u

# read input
hetSNP=$1
bam=$2
output=$3
chr=$4
ref=$5

samtools mpileup -d 0 -s -f $ref -r chr$chr \
    -l <(cat $hetSNP | tail -n+2 | awk '{print $1,$3}' | grep 'chr'${chr}'\s') \
    $bam > $output
#    --output-extra FLAG,QNAME,RG,NM $bam > $output
