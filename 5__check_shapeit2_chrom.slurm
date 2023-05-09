#!/bin/bash
#SBATCH --job-name=shapeit2
#SBATCH --mail-user=xz195@duke.edu
#SBATCH --mail-type=FAIL
#SBATCH --mem=4G
#SBATCH -c 1
#SBATCH --time=8:00:00
#SBATCH --output=log/%j.out
#SBATCH --error=log/%j.out

############### testing command
# sample="HG00096"
# N="X"
# sbatch -p scavenger ../script/RNAseq-analysis/pipeline_scripts/4__check_shapeit2_chrom.slurm $sample /hpc/group/allenlab/scarlett/output/RNAseq/1000Genome/$sample/tmp/shapeit2 /hpc/group/allenlab/scarlett/output/RNAseq/1000Genome/$sample/tmp/shapeit2/ref_rm${sample}/1000GP_Phase3_chr${N}_rm${sample}.hap.gz /hpc/group/allenlab/scarlett/output/RNAseq/1000Genome/$sample/tmp/shapeit2/ref_rm${sample}/1000GP_Phase3_rmHG00096.sample /hpc/group/allenlab/scarlett/software/shapeit2/reference/1000GP_Phase3/1000GP_Phase3/1000GP_Phase3_chrX_NONPAR.legend.gz /hpc/group/allenlab/scarlett/software/shapeit2/reference/1000GP_Phase3/1000GP_Phase3/genetic_map_chrX_nonPAR_combined_b37.txt ${N}
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

# read input
sample=$1
outDir=$2
input_hap=$3
input_sample=$4
ref_legend=$5
ref_genetic_map=$6
N=$7
#male 1
#female 2

if [ "$N" = "X" ];then
    echo "chr $N"
    chrX="--chrX"
else
    chrX=""
fi
############ 5. checking shapeit2
now=$(date +"%T")
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> start with ${sample} checking:"${now}

/hpc/group/allenlab/scarlett/software/shapeit2/bin/shapeit \
    -check \
    --thread $threads \
    -V $outDir/chr${N}/vcf/${sample}_bihetSNPs_chr${N}_unphased.vcf \
    -M $ref_genetic_map \
    --input-ref $input_hap $ref_legend $input_sample \
    --output-log $outDir/chr${N}/phase_withoutseq/${sample}_chr${N}.AlignmentChecks \
    $chrX \
    || true

now=$(date +"%T")
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> done with ${sample} checking:"${now}
