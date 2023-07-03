#!/bin/bash
#SBATCH --job-name=submit-BEASTIE-TSI
#SBATCH --mem=512M
#SBATCH -c 1
#SBATCH --mail-type=END,FAIL
#SBATCH -p scavenger
#SBATCH --oversubscribe
#SBATCH --no-requeue
#SBATCH --dependency=singleton
#SBATCH --out=/hpc/group/allenlab/scarlett/pipeline_working/log/%j.out
#SBATCH --error=/hpc/group/allenlab/scarlett/pipeline_working/log/%j.out

########### testing commands
## GIAB/GSD
# sbatch /hpc/group/allenlab/scarlett/github/BEASTIE_pipeline_script/submit_BEASTIE_runModel_single.slurm
## 1000 Genome
# sbatch /hpc/group/allenlab/scarlett/github/BEASTIE_pipeline_script/submit_BEASTIE_runModel_single.slurm YRI
# sbatch /hpc/group/allenlab/scarlett/github/BEASTIE_pipeline_script/submit_BEASTIE_runModel_single.slurm CEU
# sbatch /hpc/group/allenlab/scarlett/github/BEASTIE_pipeline_script/submit_BEASTIE_runModel_single.slurm GBR
# sbatch /hpc/group/allenlab/scarlett/github/BEASTIE_pipeline_script/submit_BEASTIE_runModel_single.slurm FIN
# sbatch /hpc/group/allenlab/scarlett/github/BEASTIE_pipeline_script/submit_BEASTIE_runModel_single.slurm TSI
###########

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

ancestry=${1-}
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

function submit_and_wait_sample() {
    sample=$1

    source $scripts_dir/setup.sh
    source $scripts_dir/helpers.sh
    GSD_list=("123375" "123667" "125249" "125260" "122687_merged" "122698")
    echo "submitting pipeline for $sample"

    if [[ "$sample" = "NA12878" ]];then
        postfix="GIAB"
        echo ">>> GIAB sample!"
        ### GIAB
        base_working_dir=/hpc/group/allenlab/scarlett/output/RNAseq/GIAB
        raw_fq_dir=/datacommons/allenlab/scarlett/data/fastq/$sample
        read_length=101
        simulation_depth=101
    elif [[ " ${GSD_list[*]} " == *" $sample "* ]]; then
        postfix="GSD"
        echo "$sample is present in the GSD list"
        ### GSD
        base_working_dir=/hpc/group/allenlab/scarlett/output/RNAseq/GSD
        raw_fq_dir=/datacommons/allenlab/scarlett/data/GSD/ShortReadRNA/$sample
        read_length=50
        simulation_depth=100    
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
    modelname="iBEASTIE4"
    working_dir=$base_working_dir/$sample
    ancestry=$(get_ancestry $raw_fq_dir)
    beastie_dir=$working_dir/beastie
    input_vcfgz=$working_dir/${sample}.no_chr.content.SNPs.hets.filtered.vcf.gz
    output_dir=$beastie_dir/runModel_phased_even${simulation_depth}
    input_simulation_pileup=$working_dir/${sample}.simulation_even_${simulation_depth}.pileup.gz
    filtered_hetSNP_file=$working_dir/${sample}_hetSNP_filtered.tsv
    input_shapeit2=$working_dir/${sample}.shapeit.tsv
    sigma1=0.7
    sigma2=1
    #
    all_job_ids=()
    job_id=$(sbatch \
        --parsable \
        --job-name=${sample}-${ancestry}-${modelname}-${sigma1} \
        $scripts_dir/BEASTIE_runModel.slurm \
        $input_vcfgz $sample $ancestry $output_dir $chr_start $chr_end $sigma1 $read_length $filtered_hetSNP_file $modelname False $input_simulation_pileup $input_shapeit2
    )
    all_job_ids+=( $job_id )
    job_id2=$(sbatch \
        --parsable \
        --dependency=singleton,afterok:$job_id \
        --kill-on-invalid-dep=yes \
        --job-name=${sample}-${ancestry}-${modelname}-${sigma2} \
        $scripts_dir/BEASTIE_runModel.slurm \
        $input_vcfgz $sample $ancestry $output_dir $chr_start $chr_end $sigma2 $read_length $filtered_hetSNP_file $modelname False $input_simulation_pileup $input_shapeit2
    )
    all_job_ids+=( $job_id2 )

    wait_for_jobs ${all_job_ids[@]}

    echo "finished $sample"

}

export -f submit_and_wait_sample
export -f get_ancestry
export scripts_dir

### Please change here for your sample: HG00096
# samples="NA12878"
# parallel \
#     -j 1 \
#     --delay 1 \
#     -v --line-buffer \
#     submit_and_wait_sample \
#     ::: $samples

### Please change here for your sample: GSD
#samples="123375"
parallel \
    -j 5 \
    --delay 1 \
    -v --line-buffer \
    submit_and_wait_sample \
    ::: $samples

### Please change here for your sample from 1000 Genome
# parallel \
#     -j 5 \
#     --delay 1 \
#     -v --line-buffer \
#     submit_and_wait_sample \
#     ::: $samples
