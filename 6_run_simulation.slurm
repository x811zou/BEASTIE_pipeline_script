#!/bin/bash
#SBATCH --job-name=simulation
#SBATCH --mail-user=xz195@duke.edu
#SBATCH --mail-type=FAIL
#SBATCH --mem=512M
#SBATCH --time=24:00:00
#SBATCH --output=log/%j.out
#SBATCH --error=log/%j.out
#SBATCH -c 1
#SBATCH -p scavenger
#SBATCH --oversubscribe
#SBATCH --no-requeue

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

############### testing command
# sample="NA12878"
# out_path=/hpc/group/allenlab/scarlett/output/RNAseq/GIAB/NA12878
# util_dir=/hpc/home/bmajoros/twobit
# genome=/datacommons/allenlab/hg19/hg19.2bit
# gff=/datacommons/allenlab/hg19/filter/gencode.v19.annotation.level12.gtf
# bam=$out_path/tmp/star_2pass_WASP_m10/Aligned.sortedByCoord.out.picard_markdup.WASP_filtered.bam
# vcfgz=$out_path/${sample}.no_chr.content.SNPs.filtered.vcf.gz
# depth=101
# seed=$out_path/simulation_seed
# mode=SNPs
# haplotype=even
# sbatch ../script/RNAseq-analysis/pipeline_scripts/6_run_simulation.slurm $sample $out_path/tmp $util_dir $genome $gff $bam $vcfgz $depth $seed $mode $haplotype $simulation_pileup
# python /hpc/group/allenlab/scarlett/script/spliced_simulator/unbiased-spliced-rna.py /hpc/home/bmajoros/twobit /datacommons/allenlab/hg19/hg19.2bit /datacommons/allenlab/hg19/filter/gencode.v19.annotation.level12.gtf /hpc/group/allenlab/scarlett/output/RNAseq/$sample/tmp/simulation/input/${sample}.sam.gz /hpc/group/allenlab/scarlett/output/RNAseq/$sample/${sample}.no_chr.content.SNPs.hets.vcf.gz /hpc/group/allenlab/scarlett/output/RNAseq/$sample/tmp/simulation/fastq $depth --out-prefix chr${N} --chr chr${N} -r -v 
###############

sample=$1
out_fwd=$2
out_rev=$3
simulation_working_dir=$4

util_dir=$5
genome=$6
gff=$7
sam=$8
vcfgz=$9
depth=${10}
seed_file=${11}
simulate_allSNPs=${12}
haplotype=${13}

####################### run simulation

if [ -s "$out_fwd" \
    -a -s "$out_rev" \
    -a "$out_fwd" -nt "$sam" \
    -a "$out_rev" -nt "$sam" \
]; then
    echo "$out_fwd exists and non-empty, newer than $sam."
    exit
fi

mkdir -p $simulation_working_dir

now=$(date +"%T")
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> writing ${sample} simulation seed file ${seed_file}: "${now}
seed=$(od -A n -t u -N 4 /dev/urandom)
echo "$seed" > $seed_file

now=$(date +"%T")
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> start with ${sample} simulation : "${now}
# recommendation:
# 8G for 1000 genome samples
# 10G for 10G
mem="16G"

# II. loop through 22 chromosome
jobs_ids=()
for N in {1..22} 
do
        job_id=$(sbatch --parsable \
            --job-name=${SLURM_JOB_NAME}-chr${N} \
            --mem=$mem \
            $scripts_dir/6__run_simulation_chrom.slurm \
            $sample \
            $simulation_working_dir \
            $util_dir $genome $gff \
            $sam $vcfgz \
            $depth $N $seed \
            $simulate_allSNPs $haplotype \
        )
        job_ids+=( $job_id )
done

wait_for_jobs ${job_ids[@]} || exit 1

now=$(date +"%T")
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> combining ${sample} : "${now}

fwd_tmp=$simulation_working_dir/fwd.tmp.fastq.gz
rev_tmp=$simulation_working_dir/rev.tmp.fastq.gz

cat $simulation_working_dir/chr{1..22}_1.fastq.gz > $fwd_tmp &
cat $simulation_working_dir/chr{1..22}_2.fastq.gz > $rev_tmp &

wait

mv $fwd_tmp $out_fwd
mv $rev_tmp $out_rev

now=$(date +"%T")
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> cleanup individual chr : "${now}

rm $simulation_working_dir/chr{1..22}_1.fastq.gz $simulation_working_dir/chr{1..22}_2.fastq.gz

now=$(date +"%T")
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> done with ${sample} : "${now}
