#!/bin/bash
#SBATCH --job-name=submit-BEASTIE-GIAB
#SBATCH --mem=512M
#SBATCH -c 1
#SBATCH --mail-type=END,FAIL
#SBATCH -p scavenger
#SBATCH --oversubscribe
#SBATCH --no-requeue
#SBATCH --dependency=singleton
#SBATCH --out=log/%j.out
#SBATCH --error=log/%j.out


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

########### testing commands
# sbatch ../script/RNAseq-analysis/pipeline_scripts2/submit_BEASTIE_runModel_single.slurm
###########
ancestry=${1-}
###########  1000 Genome samples
#file=$path/British.txt GBR #188/2=94 #8-86-86 HG00104 HG00124 HG00134 HG00135 HG00152 HG00156 HG00247 HG00249
#file=$path/Finnish.txt FIN #190/2=95 #3-92-92 HG00312 HG00359 HG00377
#file=$path/Tuscan.txt  TSI #186/2=93 #2-91-91 NA20537 NA20816
#file=$path/Utah.txt    CEU #182/2=91 #2-89-89 NA11993 NA07346
#file=$path/Yoruba.txt  YRI #178/2=89 #2-87-87 NA18487 NA19150
# 94+95+93+91+89 = 465 - (9+3+3+2+2) = 445 | 445

ancestry_arg=""
if [ -n "$ancestry" ]; then
    ancestry_arg=$ancestry
    echo "We are processing smaples from ancestry: $ancestry_arg"
    path=/datacommons/allenlab/scarlett/data/fastq/1000Genome
    file=$path/${ancestry}.txt
    start=1
    count=100
    samples=$(cat ${file} | awk '{print $1}' | uniq | tail -n+${start} | head -n $count)
fi

function get_ancestry() {
    local raw_fq_dir=$1

    local ancestry_file=$raw_fq_dir/ancestry
    if [ ! -e "$ancestry_file" ]; then
        >&2 echo "Error ancestry file not found at ${ancestry_file}"
        return 5
    fi
    local ancestry=$(cat $ancestry_file)
    if [ -z "$ancestry" ]; then
        >&2 echo "No ancestry data found in file ${ancestry_file}"
        return 5
    fi
    echo "${ancestry}"
}


function submit_and_wait_sample() {
    sample=$1

    source $scripts_dir/setup.sh
    source $scripts_dir/helpers.sh

    echo "submitting pipeline for $sample"

    if [ "$sample" = "NA12878" ];
    then
        postfix="GIAB"
        echo ">>> GIAB sample!"
        ### GIAB
        base_working_dir=/hpc/group/allenlab/scarlett/output/RNAseq/GIAB
        raw_fq_dir=/datacommons/allenlab/scarlett/data/fastq/$sample
        read_length=101
        simulation_depth=101
    else
        postfix="1000Genome"
        echo ">>> 1000 genome sample!"
        #### 1000 Genome
        base_working_dir=/hpc/group/allenlab/scarlett/output/RNAseq/1000Genome
        # base_working_dir=/work/xz195
        raw_fq_dir=/datacommons/allenlab/scarlett/data/fastq/1000Genome/$sample
        read_length=75
        simulation_depth=100
    fi
    chr_start=1
    chr_end=22
    modelname="iBEASTIE3"
    working_dir=$base_working_dir/$sample
    ancestry=$(get_ancestry $raw_fq_dir)
    beastie_dir=$working_dir/beastie
    input_vcfgz=$working_dir/${sample}.no_chr.content.SNPs.hets.filtered.vcf.gz
    output_dir=$beastie_dir/runModel_phased_even${simulation_depth}
    input_simulation_pileup=$working_dir/${sample}.simulation_even_${simulation_depth}.pileup.gz
    filtered_hetSNP_file=$working_dir/${sample}_hetSNP_filtered.tsv
    input_shapeit2=$working_dir/${sample}.shapeit.tsv
    sigma1=0.5
    sigma2=1000000
    #
    all_job_ids=()
    job_id=$(sbatch \
        --parsable \
        --job-name=${ancestry}-${sample}-${modelname}-${sigma1} \
        /hpc/group/allenlab/scarlett/script/RNAseq-analysis/pipeline_scripts2/BEASTIE_runModel.slurm \
        $input_vcfgz $sample $ancestry $output_dir $chr_start $chr_end $sigma1 $read_length $filtered_hetSNP_file $modelname False $input_simulation_pileup $input_shapeit2
    )
    all_job_ids+=( $job_id )
    job_id2=$(sbatch \
        --parsable \
        --dependency=singleton,afterok:$job_id \
        --kill-on-invalid-dep=yes \
        --job-name=${ancestry}-${sample}-${modelname}-${sigma2} \
        /hpc/group/allenlab/scarlett/script/RNAseq-analysis/pipeline_scripts2/BEASTIE_runModel.slurm \
        $input_vcfgz $sample $ancestry $output_dir $chr_start $chr_end $sigma2 $read_length $filtered_hetSNP_file $modelname False $input_simulation_pileup $input_shapeit2
    )
    all_job_ids+=( $job_id2 )

    wait_for_jobs ${all_job_ids[@]}

    echo "finished $sample"

}
export -f submit_and_wait_sample
export -f get_ancestry
export scripts_dir
samples="NA12878"

parallel \
    -j 1 \
    --delay 1 \
    -v --line-buffer \
    submit_and_wait_sample \
    ::: $samples

#start 20 samples,submit each one after 1s of submitting the previous one
