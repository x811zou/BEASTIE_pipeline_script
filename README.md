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
Example submission files made for 1000 Genome samples, GIAB, GSD samples: submit_pipelines_GIAB.slurm, submit_pipelines_GSD.slurm, submit_pipelines_GIAB.slurm<br>

F.Y.I.Please check carefully for your sample. If you have question, please email xue.zou@duke.edu
```
--is-1000Genome    --> default: individual sample
--is-GIAB          --> default: other sample. Only GIAB sample will run shapeit4 phasing
--simulate-hetSNPs --> default: only mutate het SNPs (which is not recommended)
--keep-tmp         --> default: remove tmp directory
--random           --> default: even haplotype mode so that p = 0.5
--force            --> default: check success file
--noPASSfilter     --> default: there is PASS filter in VCF (SNPs will be filtered by quality score > 10 based on SPAG1 sample)
--hardac           --> default: DCC partition "scavenger". Hardac parition "all". (If else, customize it in full_pipeline2.slurm)
--email            --> default: xz195@duke.edu. (Change it to your email address.)
```
#### (3) Instructions to run step2 pipeline scripts:
