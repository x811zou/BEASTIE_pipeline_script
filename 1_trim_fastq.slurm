#!/bin/bash
#SBATCH --job-name=trimFastq
#SBATCH --mail-user=xz195@duke.edu
#SBATCH --mail-type=FAIL
#SBATCH --mem=16G
#SBATCH --time=8:00:00
#SBATCH -c 6
#SBATCH --output=log/%j.out
#SBATCH --error=log/%j.out
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
# sample="HG00097"
# sbatch ../script/RNAseq-analysis/pipeline_scripts/1_trim_fastq.slurm 
###############

# read input
Trimmomatic_path=$1

sample=$2
rawfastq_fwd=$3
rawfastq_rev=$4
trimmedfastq_dir=$5

# check 
mkdir -p $trimmedfastq_dir
tmp_fwd_reads=$trimmedfastq_dir/${sample}_FWD_paired.tmp.fq.gz
tmp_rev_reads=$trimmedfastq_dir/${sample}_REV_paired.tmp.fq.gz
tmp_fwd_reads_unpaired=$trimmedfastq_dir/${sample}_FWD_unpaired.tmp.fq.gz
tmp_rev_reads_unpaired=$trimmedfastq_dir/${sample}_REV_unpaired.tmp.fq.gz

fwd_reads=$trimmedfastq_dir/${sample}_FWD_paired.fq.gz
rev_reads=$trimmedfastq_dir/${sample}_REV_paired.fq.gz
fwd_reads_unpaired=$trimmedfastq_dir/${sample}_FWD_unpaired.fq.gz
rev_reads_unpaired=$trimmedfastq_dir/${sample}_REV_unpaired.fq.gz

if [ -s "$fwd_reads" \
    -a -s "$rev_reads" \
]; then
    echo "$fwd_reads and $rev_reads exist."
    exit
fi

now=$(date +"%T")
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> start with ${sample} :"${now}

# use zsh as it waits until process substitions finish before completing.
zsh -c "eval \
java -jar $Trimmomatic_path/trimmomatic-0.39.jar PE -threads $threads -phred33 \
    <(bgzip -@ $threads -cd $rawfastq_fwd) \
    <(bgzip -@ $threads -cd $rawfastq_rev) \
    >(bgzip -@ $threads -l3 -c > $tmp_fwd_reads) \
    >(bgzip -@ $threads -l3 -c > $tmp_fwd_reads_unpaired) \
    >(bgzip -@ $threads -l3 -c > $tmp_rev_reads) \
    >(bgzip -@ $threads -l3 -c > $tmp_rev_reads_unpaired) \
    ILLUMINACLIP:$Trimmomatic_path/adapters/TruSeq3-PE.fa:2:30:10 LEADING:3 TRAILING:3 SLIDINGWINDOW:4:15 MINLEN:36 \
"

echo "waiting $(date +%T)"
wait
echo "done waiting $(date +%T)"

# rename completed files

mv $tmp_fwd_reads_unpaired $fwd_reads_unpaired
mv $tmp_rev_reads_unpaired $rev_reads_unpaired
mv $tmp_fwd_reads $fwd_reads
mv $tmp_rev_reads $rev_reads

# echo "fwd_reads lines"
# zcat $fwd_reads | wc -l

now=$(date +"%T")
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> done with ${sample} :"${now}
