#!/bin/bash
#SBATCH --job-name=full-pipeline
#SBATCH --mem=512M
#SBATCH --mail-user=xz195@duke.edu
#SBATCH --mail-type=FAIL
#SBATCH --time=36:00:00
#SBATCH -c 1
#SBATCH --out=log/%j.out
#SBATCH --error=log/%j.out
#SBATCH -p scavenger
#SBATCH --dependency=singleton
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

sample=""
vcf_path=""
raw_fq_fwd=""
raw_fq_rev=""
fastq_read_length=""
simulation_depth=""
working_dir=""
modelname=""
ancestry=""
sex=""
keep_tmp=""
force=""

force=false
keep_tmp=false
simulation_haplotype_mode="even"
simulate_allSNPs=true
is_1000Genome=false

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --sample) sample="$2"; shift ;;
        # path to vcf file, or vcf dir containing per chromosome for 1000Genome
        --vcf-path) vcf_path="$2"; shift ;;
        --raw-fq-fwd) raw_fq_fwd="$2"; shift ;;
        --raw-fq-rev) raw_fq_rev="$2"; shift ;;
        --fastq-read-length) fastq_read_length="$2"; shift ;;
        --simulation-depth) simulation_depth="$2"; shift ;;
        --working-dir) working_dir="$2"; shift ;;
        --ancestry) ancestry="$2"; shift ;;
        --sex) sex="$2"; shift ;;
        --simulate-hets-only) simulate_allSNPs=false ;;
        --is-1000Genome) is_1000Genome=true ;;
        --simulate_random) simulation_haplotype_mode="random";;
        --keep-tmp) keep_tmp=true ;;
        ---force) force=true ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

if [ -z "${sample}" ]; then
    echo "-s/--sample is required"
    exit 1
fi
if [ -z "${vcf_path}" ]; then
    echo "--vcf-path is required"
    exit 1
fi

if [ -z "${raw_fq_fwd}" ]; then
    echo "--raw-fq-fwd is required"
    exit 1
fi
if [ -z "${raw_fq_rev}" ]; then
    echo "--raw-fq-rev is required"
    exit 1
fi

if [ -z "${fastq_read_length}" ]; then
    echo "--fastq-read-length is required"
    exit 1
fi
if [ -z "${simulation_depth}" ]; then
    echo "--simulation-depth is required"
    exit 1
fi
if [ -z "${working_dir}" ]; then
    echo "--working-dir is required"
    exit 1
fi
if [ -z "${ancestry}" ]; then
    echo "--ancestry is required"
    exit 1
fi
if [ -z "${sex}" ]; then
    echo "--sex is required"
    exit 1
fi

echo "Running pipeline for sample $sample"


tmp_dir=$working_dir/tmp
simulation_dir=$tmp_dir/simulation_${simulation_haplotype_mode}_${simulation_depth}
trimmedfastq_dir=$tmp_dir/trimmed_fastq
alignment_working_dir=$tmp_dir/star_2pass_WASP_m${mismatchN}
bi_vcfgz=$tmp_dir/${sample}.no_chr.content.SNPs.vcf.gz
bihet_vcfgz=$tmp_dir/${sample}.no_chr.content.SNPs.hets.vcf.gz
filtered_bi_vcfgz=$working_dir/${sample}.no_chr.content.SNPs.filtered.vcf.gz
filtered_bihet_vcfgz=$working_dir/${sample}.no_chr.content.SNPs.hets.filtered.vcf.gz
hetSNP=$working_dir/${sample}_hetSNP.tsv
filtered_hetSNP=$working_dir/${sample}_hetSNP_filtered.tsv
real_bam=$alignment_working_dir/Aligned.sortedByCoord.out.picard_markdup.WASP_filtered.bam
real_sam=$alignment_working_dir/$sample.sam.gz
simulation_bam=$simulation_dir/star_2pass_WASP_m${mismatchN}/$star_bam_filename
real_pileup=$working_dir/${sample}.pileup.gz
simulation_fwd_fastq=$simulation_dir/${sample}_FWD_paired.fq.gz
simulation_rev_fastq=$simulation_dir/${sample}_REV_paired.fq.gz
simulation_pileup=$working_dir/${sample}.simulation_${simulation_haplotype_mode}_${simulation_depth}.pileup.gz
shapeit2=$working_dir/${sample}.shapeit.tsv
shapeit4=$working_dir/${sample}.shapeit4.tsv
success_file=$working_dir/success
seed_file=$working_dir/simulation_seed
genotypingError_sites=$working_dir/${sample}_genotypeEr.tsv
genotype_error_dir=$working_dir/filterGenotypingError


if [[ "$simulate_allSNPs" = true ]]; then
    simulation_vcfgz=$filtered_bi_vcfgz
else
    simulation_vcfgz=$filtered_bihet_vcfgz
fi
  
#if not force and -s non-empty success file
if [ "$force" != true -a -s "$success_file" ]; then
    echo "Found success file at $success_file, skipping"
    exit
fi

mkdir -p $working_dir
mkdir -p $tmp_dir

ancestry_file=$working_dir/ancestry
echo "$ancestry" > $ancestry_file

sex_file=$working_dir/sex
echo "$sex" > $sex_file

all_job_ids=()


# if not filtered and not unfiltered
modify_haplotype_job_id=""
shapeit2_working_dir=$tmp_dir/shapeit2
shapeit4_working_dir=$tmp_dir/shapeit4
if [[ "$is_1000Genome" = true ]]; then
    # extract 1000 genome VCF
    extract_vcf_job_id=$(sbatch --parsable \
        --job-name=${sample}-extractVCF \
        --dependency=singleton \
        $scripts_dir/0_extract_vcf_1000genome.slurm $sample $tmp_dir/VCF $vcf_path $bi_vcfgz $bihet_vcfgz)
    # prepare haplotype file
    haplotype_dir=$shapeit2_working_dir/modified_haplotype
    shapeit2_ref_sample=$shapeit2_ref_dir/$shapeit2_ref_sample_name
    modify_haplotype_job_id=$(sbatch --parsable \
        --job-name=${sample}-modifyHaplotype-s2 \
        --dependency=singleton \
        $scripts_dir/5_prepare_1000Genome_haplotype_s2.slurm $sample $shapeit2_ref_sample $shapeit2_ref_dir $haplotype_dir )
    shapeit2_haplotype_dir=$haplotype_dir
else
    # TODO test this
    # individual VCF
    extract_vcf_job_id=$(sbatch --parsable \
        --job-name=${sample}-filterVCF \
        --dependency=singleton \
        $scripts_dir/0_filter_vcf_individual.slurm $sample $vcf_path $tmp_dir/VCF $bi_vcfgz $bihet_vcfgz)
    shapeit4_haplotype_dir=$shapeit4_ref_dir
    shapeit2_haplotype_dir=$shapeit2_ref_dir
    # prepare shapeit4 reference file
    haplotype4_dir=$shapeit4_working_dir/modified_reference
    shapeit4_ref_dir=$shapeit4_ref_dir
    modify_haplotype_job_id=$(sbatch --parsable \
        --job-name=${sample}-modifyHaplotype-s4 \
        --dependency=singleton \
        $scripts_dir/5_prepare_1000Genome_haplotype_s4.slurm $sample $shapeit4_ref_dir $haplotype4_dir )
    shapeit4_haplotype_dir=$haplotype4_dir
fi
all_job_ids+=( $extract_vcf_job_id )
all_job_ids+=( $modify_haplotype_job_id )

# step1: trim fastq reads
trim_real_fastq_job_id=$(sbatch --parsable \
    --job-name=${sample}-trimFastq \
    --dependency=singleton \
    $scripts_dir/1_trim_fastq.slurm \
    $Trimmomatic \
    $sample $raw_fq_fwd $raw_fq_rev \
    $trimmedfastq_dir)
all_job_ids+=( $trim_real_fastq_job_id )


# step2: align trimmed fastq reads and then mark duplicates & WASP filtering      (depend on step1)
star_working_dir=$tmp_dir/star_2pass_WASP_m${mismatchN}
star_out_file=$star_working_dir/$star_bam_filename
align_real_fastq_job_id=$(sbatch --parsable \
    --dependency=singleton,afterok:$extract_vcf_job_id:$trim_real_fastq_job_id \
    --kill-on-invalid-dep=yes \
    --job-name=${sample}-alignment \
    $scripts_dir/2__star_alignment.slurm \
    $sample \
    $ref $star_ind $AnnoDir $mismatchN \
    $bihet_vcfgz \
    $trimmedfastq_dir/${sample}_FWD_paired.fq.gz \
    $trimmedfastq_dir/${sample}_REV_paired.fq.gz \
    $star_working_dir \
    )
all_job_ids+=( $align_real_fastq_job_id )

markDuplicates_waspFilter_job_id=$(sbatch --parsable \
    --dependency=singleton,afterok:$align_real_fastq_job_id \
    --kill-on-invalid-dep=yes \
    --job-name=${sample}-markduplicates-wasp \
    $scripts_dir/2__markDuplicates_waspFilter.slurm \
    $star_out_file \
    $star_working_dir \
    $real_bam \
    )
all_job_ids+=( $markDuplicates_waspFilter_job_id )

# convert trimmed bam to sam for simulator
simulator_sam_job_id=$(sbatch --parsable \
    --dependency=singleton,afterok:$markDuplicates_waspFilter_job_id \
    --kill-on-invalid-dep=yes \
    --job-name=${sample}-prep-simulation-sam \
    $scripts_dir/convert_bam_to_sam.slurm $real_bam $real_sam \
)
all_job_ids+=( $simulator_sam_job_id )

checkseq_depth_job_id=$(sbatch --parsable \
    --dependency=singleton,afterok:$markDuplicates_waspFilter_job_id \
    --kill-on-invalid-dep=yes \
    --job-name=${sample}-check_seqDepth \
    $scripts_dir/2__check_seqDepth.slurm \
    $star_working_dir \
    $working_dir \
    )
all_job_ids+=( $checkseq_depth_job_id )

# step3: extract het SNPs and then samtools mpileup for real data  (depend on step1)
hetSNP_job_id=$(sbatch --parsable \
    --dependency=singleton,afterok:$extract_vcf_job_id \
    --kill-on-invalid-dep=yes \
    --job-name=${sample}-hetSNP \
    $scripts_dir/BEASTIE_extractHets.slurm \
    $sample $bihet_vcfgz $gencode_dir 1 22 $hetSNP \
    $tmp_dir \
    )
all_job_ids+=( $hetSNP_job_id )


mpileup_real_job_id=$(sbatch --parsable \
    --dependency=singleton,afterok:$markDuplicates_waspFilter_job_id:$hetSNP_job_id \
    --kill-on-invalid-dep=yes \
    --job-name=${sample}-mpileup \
    $scripts_dir/3_samtools_mpileup.slurm \
    $sample $tmp_dir $tmp_dir/mpileup $hetSNP $real_bam $real_pileup $ref_fasta \
    )
all_job_ids+=( $mpileup_real_job_id )


# step4: genotyping error filtering
genotypingEr_filter_job_id=$(sbatch --parsable \
    --dependency=singleton,afterok:$extract_vcf_job_id:$trim_real_fastq_job_id:$align_real_fastq_job_id:$markDuplicates_waspFilter_job_id:$hetSNP_job_id:$mpileup_real_job_id \
    --kill-on-invalid-dep=yes \
    --job-name=${sample}-genotypingEr \
    $scripts_dir/BEASTIE_filterGenotypingError.slurm \
    $bihet_vcfgz \
    $sample \
    $real_pileup \
    $hetSNP \
    $ancestry \
    $fastq_read_length \
    $genotype_error_dir \
    $tmp_dir \
    $af_dir \
    $genotypingError_sites \
    $filtered_hetSNP \
    0.05 1 22 \
    )
all_job_ids+=( $genotypingEr_filter_job_id )

genotypingEr_filter_job2_id=$(sbatch --parsable \
    --dependency=singleton,afterok:$extract_vcf_job_id:$genotypingEr_filter_job_id \
    --kill-on-invalid-dep=yes \
    --job-name=${sample}-genotypingEr-filter \
    $scripts_dir/4_filter_genotyingEr.slurm \
    $genotypingError_sites $bi_vcfgz $bihet_vcfgz $filtered_bi_vcfgz $filtered_bihet_vcfgz $tmp_dir \
    )
all_job_ids+=( $genotypingEr_filter_job2_id )

# step6: simulating fastq reads
simulator_job_id=$(sbatch --parsable \
    --dependency=singleton,afterok:$markDuplicates_waspFilter_job_id:$genotypingEr_filter_job2_id:$simulator_sam_job_id \
    --kill-on-invalid-dep=yes \
    --job-name=${sample}-simulatefastq-${simulation_haplotype_mode}-${simulation_depth} \
    $scripts_dir/6_run_simulation.slurm \
    $sample \
    $simulation_fwd_fastq \
    $simulation_rev_fastq \
    $simulation_dir \
    $util_dir $genome $gff \
    $real_sam \
    $simulation_vcfgz \
    $simulation_depth \
    $seed_file \
    $simulate_allSNPs \
    $simulation_haplotype_mode \
    )
all_job_ids+=( $simulator_job_id )

if [[ "$is_1000Genome" == true ]]; then
    # step5: shapeit2 phasing
    shapeit2_ref_sample=$shapeit2_haplotype_dir/$shapeit2_ref_sample_name
    shapeit2_job_dependencies=($modify_haplotype_job_id $genotypingEr_filter_job2_id)
    shapeit2_phasing_job_id=$(sbatch --parsable \
        --nice \
        --dependency=singleton,afterok:$(echo "${shapeit2_job_dependencies[@]}" | tr ' ' ':') \
        --kill-on-invalid-dep=yes \
        --job-name=${sample}-shapeit2 \
        $scripts_dir/5_run_shapeit2.slurm \
        $sample \
        $shapeit2_working_dir \
        $shapeit2_ref_dir \
        $shapeit2_haplotype_dir \
        $shapeit2_ref_sample \
        $filtered_bihet_vcfgz \
        $shapeit2 \
        )
    all_job_ids+=( $shapeit2_phasing_job_id )
else
    shapeit4_job_dependencies=($extract_vcf_job_id $modify_haplotype_job_id)
    shapeit4_phasing_job_id=$(sbatch --parsable \
        --nice \
        --dependency=singleton,afterok:$(echo "${shapeit4_job_dependencies[@]}" | tr ' ' ':') \
        --kill-on-invalid-dep=yes \
        --job-name=${sample}-shapeit4 \
        $scripts_dir/5_run_shapeit4.slurm \
        $sample \
        $shapeit4_working_dir \
        $filtered_bihet_vcfgz \
        $shapeit4 \
        $shapeit4_haplotype_dir \
        )
    all_job_ids+=( $shapeit4_phasing_job_id )
fi
# step7: align simulated fastq
align_sim_fastq_job_id=$(sbatch --parsable \
    --dependency=singleton,afterok:$simulator_job_id:$genotypingEr_filter_job2_id \
    --kill-on-invalid-dep=yes \
    --job-name=${sample}-simulation-alignment \
    --mem=120G \
    -c 6 \
    $scripts_dir/2__star_alignment.slurm \
    $sample \
    $ref $star_ind $AnnoDir $mismatchN \
    $filtered_bihet_vcfgz \
    $simulation_fwd_fastq \
    $simulation_rev_fastq \
    $simulation_dir/star_2pass_WASP_m${mismatchN} \
    )
all_job_ids+=( $align_sim_fastq_job_id )


# step8: samtools mpileup for simulation data
mpileup_sim_job_id=$(sbatch --parsable \
    --dependency=singleton,afterok:$align_sim_fastq_job_id:$hetSNP_job_id \
    --kill-on-invalid-dep=yes \
    --job-name=${sample}-simulation-mpileup \
    $scripts_dir/3_samtools_mpileup.slurm \
    $sample $simulation_dir $simulation_dir/mpileup $hetSNP $simulation_bam $simulation_pileup $ref_fasta \
    )
all_job_ids+=( $mpileup_sim_job_id )

wait_for_jobs ${all_job_ids[@]}

echo "writing success file"
echo `date` > $success_file

if [[ "$keep_tmp" != true ]]; then
    echo "cleaning tmp dir"
    rm -r $tmp_dir
fi
