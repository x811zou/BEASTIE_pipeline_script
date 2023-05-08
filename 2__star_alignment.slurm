#!/bin/bash
#SBATCH --job-name=RNAseq_alignment
#SBATCH --mem=70G
#SBATCH -c 8
#SBATCH --mail-user=xz195@duke.edu
#SBATCH --mail-type=FAIL
#SBATCH --out=log/%j.out
#SBATCH --error=log/%j.out
#SBATCH -p scavenger
#SBATCH --time=24:00:00

############### testing command
#ref=/data/reddylab/scarlett/reference/hg19
#star_ind=/data/reddylab/scarlett/reference/STARIndex
#AnnoDir=$ref/annotations
# sbatch ../script/RNAseq-analysis/pipeline_scripts/2__star_alignment.slurm NA12878 /datacommons/allenlab/scarlett/reference/hg19 /datacommons/allenlab/scarlett/reference/STARIndex /datacommons/allenlab/hg19/filter/gencode.v19.annotation.level12.gtf /hpc/group/allenlab/scarlett/output/RNAseq/for_verification/new/fastq /hpc/group/allenlab/scarlett/output/RNAseq/for_verification/new/star_2pass_WASP_m10 /hpc/group/allenlab/scarlett/output/RNAseq/GIAB/NA12878/NA12878.no_chr.content.SNPs.filtered.vcf.gz 10 /hpc/group/allenlab/scarlett/output/RNAseq/for_verification/new/${sample}.chr21.pileup.gz
# sbatch /data/allenlab/scarlett/github/BEASTIE_pipeline_script/2__star_alignment.slurm SPAG1-9806 $ref $star_ind $AnnoDir 10 /data/reddylab/scarlett/output/SPAG1-9806/SPAG1-9806.no_chr.content.SNPs.hets.vcf.gz /data/reddylab/scarlett/output/SPAG1-9806/tmp/trimmed_fastq/SPAG1-9806_FWD_paired.fq.gz /data/reddylab/scarlett/output/SPAG1-9806/tmp/trimmed_fastq/SPAG1-9806_REV_paired.fq.gz /data/reddylab/scarlett/output/SPAG1-9806/tmp/star_2pass_WASP_m10
###############

# cmd to generate star index
#srun STAR --runMode genomeGenerate --genomeDir $star_ind --genomeFastaFiles $ref/hg19.fa --sjdbGTFfile $Annotation --runThreadN 8 --outFileNamePrefix $star_ind

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
# read input
sample=$1
ref=$2
star_ind=$3
Annotation=$4
N=$5
vcfgz=$6
in_fwd_fastq=$7
in_rev_fastq=$8
alignedbam_path=$9

out_bam=$alignedbam_path/$star_bam_filename

if [ "$out_bam" -nt "$in_fwd_fastq" -a -s "$out_bam" ]; then
    echo "$out_bam exists and non-empty, newer than $in_fwd_fastq."
    exit
fi

echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> start with ${sample} $(date +%T)"
mkdir -p $alignedbam_path

STAR --twopassMode Basic \
--runThreadN $threads \
--genomeDir $star_ind \
--readFilesIn $in_fwd_fastq $in_rev_fastq \
--alignEndsType EndToEnd \
--waspOutputMode SAMtag \
--varVCFfile <(bgzip -@ $threads -cd $vcfgz | grep -E "^[^#]" | sed -e 's/^/chr/') \
--outSAMattributes vA vG vW \
--outFilterMismatchNmax $N \
--outSAMtype BAM SortedByCoordinate --outReadsUnmapped Fastx \
--readFilesCommand "bgzip -@ threads -cd" \
--limitBAMsortRAM $(get_slurm_memory_limit_bytes) \
--outFileNamePrefix $alignedbam_path/

# --outBAMsortingBinsN 100 \
echo "Finish STAR 2pass EndtoEnd alignment"

echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> indexing with ${sample} $(date +%T)"

srun samtools index -@ $threads $out_bam

echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> done with ${sample} $(date +%T)"
