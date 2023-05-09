#!/bin/bash
#SBATCH --job-name=BEASTIE-filterGenotyingError
#SBATCH --mail-user=xz195@duke.edu
#SBATCH --mail-type=FAIL
#SBATCH --mem=8G
#SBATCH --time=8:00:00
#SBATCH -c 4 
#SBATCH --output=log/%J.stdout
#SBATCH --error=log/%J.stdout
#SBATCH -p scavenger

if [ -n "$SLURM_JOB_ID" ] ; then
    script_path=$(realpath $(scontrol show job $SLURM_JOBID | awk -F= '/Command=/{print $2}' | cut -d' ' -f1 ))
else
    script_path=$(realpath $0)
fi
scripts_dir=$(dirname "$script_path")

source $scripts_dir/setup.sh
source $scripts_dir/helpers.sh

set -e
set -u

##### testing commands
# sample_name_in_vcf=NA12878
# tmp_dir=/hpc/group/allenlab/scarlett/output/RNAseq/GIAB/NA12878/tmp
# input_vcfgz=$tmp_dir/${sample}.no_chr.content.SNPs.hets.vcf.gz
# input_pileup=/hpc/group/allenlab/scarlett/output/RNAseq/GIAB/NA12878/NA12878.pileup.gz
# beastie_outdir=/hpc/group/allenlab/scarlett/output/RNAseq/GIAB/NA12878/beastie
# input_hetsnp=$beastie_outdir/NA12878_hetSNP.tsv
# ancestry=CEU
# read_length=100
# chr_start=1
# chr_end=22
# af_dir=/datacommons/allenlab/scarlett/reference/beastie_reference/AF
# genotypeEr_file=$beastie_outdir/${sample}_genotypeEr.tsv
# genotypeEr_cutoff=0.05
# filtered_hetSNP=$beastie_outdir/${sample}_hetSNP_filtered.tsv
# sbatch -c 4 --mem=16G -p scavenger --job-name=BEASTIE-${sampme} /hpc/group/allenlab/scarlett/script/RNAseq-analysis/pipeline_scripts/BEASTIE_filterGenotypingError.slurm $input_vcfgz $sample_name_in_vcf $input_pileup $input_hetsnp $ancestry $read_length $beastie_outdir $af_dir $genotypeEr_file $filtered_hetSNP $genotypeEr_cutoff 1 22

input_vcfgz=$1
sample=$2
input_pileup=$3
input_hetsnp=$4
ancestry=$5
read_length=$6
out_dir=$7
tmp_dir=$8
af_dir=$9
genotype_error_file=${10}
filtered_hetSNP_file=${11}
genotypeEr_cutoff=${12}
chr_start=${13}
chr_end=${14}

WARMUP=10000
KEEPER=7300


if [ -s "$genotype_error_file" -a -s "$filtered_hetSNP_file" ]; then
    echo "$genotype_error_file and $filtered_hetSNP_file exist and non-empty"
    exit
fi

tmp_filtered_hetSNP=$tmp_dir/tmp_filtered_hetSNP
tmp_genotype_error_file=$tmp_dir/tmp_genotype_error

mkdir -p $out_dir $tmp_dir

run_beastie_image \
    filterGenotypingError \
    --beastie-outdir $out_dir \
    --filtered-het-snp-file $tmp_filtered_hetSNP \
    --outfile $tmp_genotype_error_file \
    --vcfgz-file $input_vcfgz \
    --vcf-sample-name $sample \
    --pileup-file $input_pileup \
    --input-het-snp-file $input_hetsnp \
    --ancestry $ancestry \
    --read-length $read_length \
    --chr-start $chr_start \
    --chr-end $chr_end \
    --af-dir $af_dir \
    --genotypeEr-cutoff $genotypeEr_cutoff \
    --warmup $WARMUP \
    --keeper $KEEPER

mv $tmp_filtered_hetSNP $filtered_hetSNP_file
mv $tmp_genotype_error_file $genotype_error_file