#!/bin/bash
#SBATCH --job-name=shapeit2
#SBATCH --mail-user=xz195@duke.edu
#SBATCH --mail-type=FAIL
#SBATCH --mem=4G
#SBATCH -c 1
#SBATCH --time=4:00:00
#SBATCH --output=log/%j.out
#SBATCH --error=log/%j.out

############### testing command
# sample="SPAG1-9806_polyA"
# N="21"
# sbatch -p all /data/allenlab/scarlett/github/BEASTIE_pipeline_script/5__run_shapeit2_chrom.slurm $sample /data/reddylab/scarlett/output/SPAG1-9806_polyA/tmp/shapeit2/shapeit2_EUR /data/allenlab/scarlett/software/shapeit2/reference/1000GP_Phase3/1000GP_Phase3/1000GP_Phase3_chr${N}.hap.gz /data/allenlab/scarlett/software/shapeit2/reference/1000GP_Phase3/1000GP_Phase3/1000GP_Phase3.sample /data/allenlab/scarlett/software/shapeit2/reference/1000GP_Phase3/1000GP_Phase3/1000GP_Phase3_chr${N}.legend.gz /data/allenlab/scarlett/software/shapeit2/reference/1000GP_Phase3/1000GP_Phase3/genetic_map_chr${N}_combined_b37.txt ${N} EUR
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
set -x

# specify sample
sample=$1
working_dir=$2
modified_haplotype=$3
modified_sample=$4
ref_legend=$5
ref_geneticMap=$6
N=$7
group=${8}

# specify paths
outDir=$working_dir

############ run shapeit2
now=$(date +"%T")
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> start with ${sample} phasing:"${now}
input_hap=$modified_haplotype
input_sample=$modified_sample
input_legend=$ref_legend
input_genetic_map=$ref_geneticMap

exclude_snp_file=$outDir/chr${N}/phase_withoutseq/${sample}_chr${N}.AlignmentChecks.snp.strand.exclude
chrX=""
if [ "$N" = "X" ];then
    echo "chr $N"
    chrX="--chrX"
else
    chrX=""
fi

exclude_SNP=""
if [ -s "$exclude_snp_file" ];then
    echo "$exclude_snp_file exists."
    exclude_SNP="--exclude-snp $exclude_snp_file"
else
    exclude_SNP=""
fi

group_list=""
if [ "$group" != "all" ];then
    echo "$group exists."
    group_list="--include-grp $group"
fi

$shapeit2_executable \
    --no-mcmc \
    --thread $threads \
    -V $outDir/chr${N}/vcf/${sample}_bihetSNPs_chr${N}_unphased.vcf  \
    -M $input_genetic_map \
    --input-ref $input_hap $input_legend $input_sample \
    -O $outDir/chr${N}/phase_withoutseq/${sample}_chr${N}.phased.with.ref \
    --output-log $outDir/chr${N}/phase_withoutseq/${sample}_chr${N}.Phasing \
    $exclude_SNP \
    $group_list #$chrX

now=$(date +"%T")
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> done with ${sample} phasing:"${now}
