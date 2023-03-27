# BEASTIE_pipeline_script
This repository contains pipeline script for running BEASTIE on duke DCC/hardac cluster:

step1: data preparation  --> generates files needed to run BEASTIE <br>
step2: run BEASTIE model --> use input file to run BEASTIE model

(1) Get code to your directory:
find a path that you want to store the pipeline scripts: code_path (e.g.)
```
cd $code_path
git clone https://github.com/x811zou/BEASTIE_pipeline_script.git
```

(2) Instructions to run step1 pipeline scripts:

F.Y.I.Please check carefully for your sample. If you have question, please email xue.zou@duke.edu
```
--is-1000Genome    --> default: individual sample
--is-GIAB          --> default: other sample. Only GIAB sample will run shapeit4 phasing
--simulate-hetSNPs --> default: only mutate het SNPs (which is not recommended)
--keep-tmp         --> default: remove tmp directory
--random           --> default: even haplotype mode so that p = 0.5
--force            --> default: check success file
--noPASSfilter     --> default: there is PASS filter in VCF (SNPs will be filtered by quality score > 10 based on SPAG1 sample)
--hardac           --> default: DCC partition "scavenger". Hardac parition "all". (If else, change it in full_pipeline2.slurm)
--email            --> default: xz195@duke.edu. (Change it to your email address.)
```
(3) Instructions to run step2 pipeline scripts:
