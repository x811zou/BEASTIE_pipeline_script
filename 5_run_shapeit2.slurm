#!/bin/bash
#SBATCH --get-user-env
#SBATCH -c 1
#SBATCH --mem=2G
#SBATCH --mail-user=xz195@duke.edu
#SBATCH --mail-type=FAIL
#SBATCH --out=log/%j.out
#SBATCH --error=log/%j.out
#SBATCH -p scavenger
#SBATCH --time=24:00:00
#SBATCH --no-requeue

############### testing command
# sbatch -p scavenger ../script/RNAseq-analysis/pipeline_scripts2/5_run_shapeit2.slurm NA12878 /hpc/group/allenlab/scarlett/output/RNAseq/GIAB/NA12878/tmp/shapeit2 /hpc/group/allenlab/scarlett/software/shapeit2/reference/1000GP_Phase3/1000GP_Phase3 /hpc/group/allenlab/scarlett/software/shapeit2/reference/1000GP_Phase3/1000GP_Phase3 /hpc/group/allenlab/scarlett/software/shapeit2/reference/1000GP_Phase3/1000GP_Phase3/1000GP_Phase3.sample /hpc/group/allenlab/scarlett/output/RNAseq/GIAB/NA12878/NA12878.no_chr.content.SNPs.hets.filtered.vcf.gz /hpc/group/allenlab/scarlett/output/RNAseq/GIAB/NA12878/NA12878.shapeit.tsv
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

# specify parameters
sample=$1
tmp_dir=$2
ref_dir=$3
hap_dir=$4
ref_sample=$5
vcfgz=$6
out_shapeit2=$7

# check output file existence
if [ -s "$out_shapeit2" -a -s "$vcfgz" ]; then
    echo "$out_shapeit2 exists and non-empty, newer than $vcfgz."
    exit
fi

# create new directories
mkdir -p $tmp_dir

now=$(date +"%T")
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> start with ${sample} :"${now}
input_sample=$ref_sample
input_ref_dir=$ref_dir


# II.check and run shapeit2:
job_ids=()
for N in {1..22}
do
    mkdir -p $tmp_dir/chr${N}/phase_withoutseq
    mkdir -p $tmp_dir/chr${N}/vcf
    input_haplotype=$hap_dir/1000GP_Phase3_chr${N}.hap.gz
    ref_legend=$ref_dir/1000GP_Phase3_chr${N}.legend.gz 
    ref_genetic_map=$ref_dir/genetic_map_chr${N}_combined_b37.txt
    if [[ "$N" = "X" ]]
    then
        input_haplotype=$hap_dir/1000GP_Phase3_chrX_NONPAR.hap.gz
        ref_genetic_map=$ref_dir/genetic_map_chrX_nonPAR_combined_b37.txt
        ref_legend=$ref_dir/1000GP_Phase3_chrX_NONPAR.legend.gz
    fi

    #echo "I. prepare shapeit2 vcf"
    prep_job_id=$(sbatch --parsable \
        --job-name=${sample}-shapeit2-prep-vcf-chr${N} \
        $scripts_dir/5__prepare_shapeit2_chrom.slurm \
        $sample $tmp_dir $vcfgz $N \
    )
    preparation_job_ids=( $prep_job_id )

    #echo "II. check shapeit2"
    check_job_id=$(sbatch --parsable \
        --dependency=afterok:$prep_job_id \
        --kill-on-invalid-dep=yes \
        --job-name=${sample}-shapeit2-check-chr${N} \
        $scripts_dir/5__check_shapeit2_chrom.slurm \
        $sample $tmp_dir $input_haplotype $input_sample $ref_legend $ref_genetic_map $N \
    )
    
    #echo "III. run shapeit2"
    job_id=$(sbatch --parsable \
        --dependency=afterok:$check_job_id \
        --kill-on-invalid-dep=yes \
        --job-name=${sample}-shapeit2-run-chr${N} \
        $scripts_dir/5__run_shapeit2_chrom.slurm \
        $sample $tmp_dir $input_haplotype $input_sample $ref_legend $ref_genetic_map $N \
    )
    job_ids+=( $job_id )
done

now=$(date +"%T")
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> waiting for chromosomes:" ${now}

wait_for_jobs ${job_ids[@]} || exit 1

now=$(date +"%T")
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> done processing chromosomes ${sample} :"${now}
# III. combine shapeit2 result:sort the pos for each chromosome output, and then concatenate them in order
arguments=()
for N in {1..22}
do
    arg="<(sort -k3 -n $tmp_dir/chr${N}/phase_withoutseq/${sample}_chr${N}.phased.with.ref.haps \
        | cut -d' ' -f2 --complement \
        | awk '!seen[\$1_\$2]++' \
        | tr ' ' '\t')"
    arguments+=( "$arg" )
done

tmp_output=$tmp_dir/combined
header='chr pos ref alt e_paternal e_maternal'
eval cat <(echo "$header") ${arguments[@]} > $tmp_output
mv $tmp_output $out_shapeit2

now=$(date +"%T")
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> done with combining shapeit ${sample} :"${now}

#shapeit4 --input NA12878.no_chr.content.SNPs.hets.filtered.vcf.gz --map /datacommons/allenlab/scarlett/reference/shapeit4/chr21.b37.gmap.gz --region 21 --output shapeit4.vcf.gz