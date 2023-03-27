# BEASTIE_pipeline_script
This repository contains pipeline script for running BEASTIE on duke DCC/hardac cluster:

step1: data preparation  --> generates files needed to run BEASTIE <br>
step2: run BEASTIE model --> use input file to run BEASTIE model

#### (1) Get code to your directory:
Find a path that you want to store the pipeline scripts: code_path (e.g.)
```
cd $code_path
git clone https://github.com/x811zou/BEASTIE_pipeline_script.git
```

#### (2) Instructions to run step1 pipeline scripts:
##### i. customize your setup file
Setup file contains all reference paths that are necessary for the bioinformatics softwares used in the pipeline. It is important to customize your own version if you want to use your own preferred reference/annotation files.<br>
Example setup files made from allenlab used for DCC and Hardac are: DCC_setup.sh and hardac_setup.sh<br>
After you make your setup file: my_setup.sh (s.g.), use link to name it "setup.sh"
```
ln -s my_setup.sh setup.sh
```
##### i. customize your submission file
Submission file contains parameters that you set for your sample, such as input/output paths, features of VCF file, setting for the fastq simulation, email to receive job information, etc
Example submission files made for 1000 Genome samples, GIAB, GSD samples: submit_pipelines_GIAB.slurm, submit_pipelines_GSD.slurm, submit_pipelines_GIAB.slurm<br>
After reviewing the parameter options, create your own submission file based on examples: submit_pipelines_mysample.slurm (e.g.)
F.Y.I.Please check carefully for your sample. If you have question, please email xue.zou@duke.edu
```
--is-1000Genome    --> default: individual sample has one vcf file. Only 1000 Genome samples have VCF files for each chromosome.
--is-GIAB          --> default: assumes not running shapeit4. Only GIAB sample will run shapeit4 phasing
--simulate-hetSNPs --> default: only mutate het SNPs (which is not recommended)
--keep-tmp         --> default: remove tmp directory to save space.
--random           --> default: even haplotype mode so that p = 0.5
--force            --> default: check success file, if it exists, then skip running the sample
--noPASSfilter     --> default: there is PASS filter in VCF (SNPs will be filtered by quality score > 10 based on SPAG1 sample)
--hardac           --> default: DCC partition "scavenger". Hardac parition "all". (If else, customize it in full_pipeline2.slurm)
--email            --> default: xue.zou@duke.edu. (Please change it to your email address.)
```
##### i. Submit jobs:
Please find a directory to submit your job, and create a "log" folder where you could retrieve your log file for debugging purpose: pipeline_work (e.g.)
```
cd $pipeline_working
sbatch $code_path/BEASTIE_pipeline_script/submit_pipelines_mysample.slurm
```

#### (3) Trial:
You can always try out the existing script before customziing your sample! 
This script now only specifies one sample from 1000 Genome, which will be fast to test out. PLease change output directory before executing! Thanks! 
```
sbatch $code_path/BEASTIE_pipeline_script/submit_pipelines_example.slurm
```
