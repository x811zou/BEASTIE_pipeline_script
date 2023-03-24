#!/bin/bash
#SBATCH --job-name=simulation
#SBATCH --mail-user=xz195@duke.edu
#SBATCH --mail-type=FAIL
#SBATCH --mem=8G
#SBATCH --time=12:00:00
#SBATCH --output=log/%j.out
#SBATCH --error=log/%j.out
#SBATCH -c 1
#SBATCH -p scavenger

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

############### testing command
# module load htslib
# module load samtools/1.11-rhel8
######### 1000 Genome individuals
# N=1
# sample="HG00096"
# util_dir=/hpc/home/bmajoros/twobit
# genome=/datacommons/allenlab/hg19/hg19.2bit
# gff=/datacommons/allenlab/hg19/filter/gencode.v19.annotation.level12.gtf
# sam=/hpc/group/allenlab/scarlett/output/RNAseq/1000Genome/$sample/tmp/simulation_SNPs_even_100/${sample}.sam.gz
# vcfgz=/hpc/group/allenlab/scarlett/output/RNAseq/1000Genome/$sample/${sample}.no_chr.content.SNPs.filtered.vcf.gz
# out_path=/hpc/group/allenlab/scarlett/output/RNAseq/1000Genome/$sample/tmp/simulation_test
# read_depth=1
######### GSD individuals
# sample="123375"
# sam=/hpc/group/allenlab/scarlett/output/RNAseq/GSD/$sample/tmp/simulation_SNPs_even_100/${sample}.sam.gz
# vcfgz=/hpc/group/allenlab/scarlett/output/RNAseq/GSD/$sample/${sample}.no_chr.content.SNPs.filtered.vcf.gz
# out_path=/hpc/group/allenlab/scarlett/output/RNAseq/GSD/$sample/tmp/simulation_test
# read_depth=1
#
# EXAMPLE running command:
# python /hpc/group/allenlab/scarlett/script/spliced_simulator/unbiased-spliced-rna-test.py $util_dir $genome $gff $sam $vcfgz $out_path $read_depth --out-prefix chr${N} --chr chr${N} --allSNPs
# srun -c 4 --mem=32G ../script/RNAseq-analysis/pipeline_scripts/6__run_simulation_chrom.slurm $sample /hpc/group/allenlab/scarlett/output/RNAseq/GSD/$sample/tmp/simulation_test /hpc/home/bmajoros/twobit /datacommons/allenlab/hg19/hg19.2bit /datacommons/allenlab/hg19/filter/gencode.v19.annotation.level12.gtf /hpc/group/allenlab/scarlett/output/RNAseq/GSD/$sample/tmp/simulation_SNPs_even_100/${sample}.sam.gz /hpc/group/allenlab/scarlett/output/RNAseq/GSD/$sample/${sample}.no_chr.content.SNPs.filtered.vcf.gz 1 1 1234 SNPs even
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



sample=$1
out_path=$2
util_dir=$3
genome=$4
gff=$5
sam=$6
vcfgz=$7
depth=$8
N=$9 
seed=${10}
snp=${11}
haplotype=${12}

snp_arg=""
if [ "$snp" = true ];then
    snp_arg="--all_snps"
    echo ">>> all snps simulation"
fi

random_arg=""
if [ "$haplotype" = "random" ];then
    random_arg="--random"
fi

echo ">>> chromosome: chr${N}"

mkdir -p $out_path

out1=$out_path/chr${N}_1.fastq.gz
out2=$out_path/chr${N}_2.fastq.gz

# latest version of simulator
python $simulator_py \
    $util_dir $genome $gff $sam $vcfgz \
    --out1 $out1 \
    --out2 $out2 \
    --read_depth $depth \
    --chr chr${N} \
    --seed $seed \
    $snp_arg \
    $random_arg

