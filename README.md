# BEASTIE_pipeline_script
This repository contains a pipeline script for running BEASTIE on the Duke DCC/Hardac cluster. The pipeline consists of two steps: data preparation and running the BEASTIE model.

## Getting Started
### Installation
To get started, clone this repository to a directory of your choice, and create the "beastie" environment using the YAML file:

```
cd $code_path
git clone https://github.com/x811zou/BEASTIE_pipeline_script.git
conda env create -f environment.yml
```

### Running the Pipeline
<br>
Step1: Data Preparation<br>
<br>
Before running the pipeline, you need to customize the setup file and the submission file.

#### Customize your setup file
The setup file contains all reference paths that are necessary for the bioinformatics software used in the pipeline. It is important to customize your own version if you want to use your own preferred reference/annotation files. Example setup files made from Allen Lab used for DCC and Hardac are DCC_setup.sh and hardac_setup.sh. After you make your setup file **my_setup.sh** (for example), use the following command to name it "setup.sh":
```
ln -s my_setup.sh setup.sh
```
#### Customize your submission file
The submission file contains parameters that you set for your sample, such as input/output paths, features of VCF file, setting for the fastq simulation, email to receive job information, etc. After reviewing the parameter options, create your own submission file, for example, **submit_pipelines_mysample.slurm**,based on the template: **submit_pipelines_template.slurm** Example submission files made for 1000 Genome samples, GIAB, GSD samples are submit_pipelines_GIAB.slurm, submit_pipelines_GSD.slurm, submit_pipelines_GIAB.slurm. <br><br>

Please check the options carefully for your sample. If you have any questions, please email xue.zou@duke.edu.
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
#### Submit jobs:
To submit jobs, find a directory to submit your job, and create a "log" folder where you can retrieve your log file for debugging purposes. For example:
```
cd $pipeline_working
sbatch $code_path/BEASTIE_pipeline_script/submit_pipelines_mysample.slurm
```
<br>
Step 2: Run BEASTIE Model<br>
<br>
After the data preparation is complete, use the input file to run the BEASTIE model.<br>

#### Customize your submission file
The BEASTIE model submission file contains parameters that you set for your sample, such as regions of chromosomes you want to cover, and the parameters you choose in step1 submission file. Create your own submission file based on examples, for example, submit_BEASTIE_runModel_single_mysample.slurm <br><br>

#### Submit jobs:
Use the same directory to submit this job:
```
cd $pipeline_working
sbatch $code_path/BEASTIE_pipeline_script/submit_BEASTIE_runModel_single_mysample.slurm
```

### Testing case on DCC:
You can always try out the existing script before customizing your sample. The following script specifies only one sample from 1000 Genome, which will be fast to test out. Please change the output directory before executing: 
```
sbatch $code_path/BEASTIE_pipeline_script/submit_pipelines_example.slurm
```
After this job finishes and success file generated, you can run step2 script: 
```
sbatch $code_path/BEASTIE_pipeline_script/submit_BEASTIE_runModel_single_example.slurm
```


### Testing case on HARDAC:
You can always try out the existing script before customizing your sample. The following script specifies only one sample from SPAG1, which will be fast to test out. Please change the output directory before executing: 
```
sbatch $code_path/BEASTIE_pipeline_script/submit_pipelines_SPAG1.slurm
```
After this job finishes and success file generated, you can run step2 script: 
```
sbatch $code_path/BEASTIE_pipeline_script/submit_BEASTIE_runModel_single_SPAG1.slurm
```
