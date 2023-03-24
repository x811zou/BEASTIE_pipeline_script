#!/usr/bin/env python3

import argparse
import sys
import pandas as pd
import csv 

# cat /hpc/group/allenlab/scarlett/output/RNAseq/1000Genome/HG00171/HG00171.no_chr.content.SNPs.vcf.gz | gunzip | head -n 10 | ../script/RNAseq-analysis/pipeline_scripts/filter_vcf.py --GenotypingError-file /hpc/group/allenlab/scarlett/output/RNAseq/1000Genome/HG00171/HG00171_hetSNP_genotypeEr.tsv
parser = argparse.ArgumentParser(description='Filter sites with genotyping error in VCF and generate a filtered VCF file')
parser.add_argument('--GenotypingError-file',help='file contains het SNPs with genotyping error',required=True)

args=parser.parse_args()
genotying_error_sites=args.GenotypingError_file

file=open(genotying_error_sites)
biased_sites=csv.reader(file,delimiter='\t',) 

unique_set=set()
first=True
for sites in biased_sites:
    if first:
        first=False
        continue
    unique_set.add((sites[0],sites[1]))
file.close()

input_file = sys.stdin
output_file = sys.stdout

counter=0
for line in input_file:
    if line[0] == "#":
        output_file.write(line)
        continue
    else:
        split_string=line.split("\t",)
        col12=(split_string[0],split_string[1])
        if col12 in unique_set:
            counter+=1
            continue
        else:
            output_file.write(line)
    
print(f"filter out {counter} SNPs!", file=sys.stderr)
