# facets-nf
## Pipeline using facets for fraction and copy number estimate from tumor/normal sequencing

## UNDER DEVELOPMENT

[![CircleCI](https://circleci.com/gh/IARCbioinfo/template-nf.svg?style=svg)](https://circleci.com/gh/IARCbioinfo/template-nf)
[![Docker Hub](https://img.shields.io/badge/docker-ready-blue.svg)](https://hub.docker.com/r/iarcbioinfo/template-nf/)
[![https://www.singularity-hub.org/static/img/hosted-singularity--hub-%23e32929.svg](https://www.singularity-hub.org/static/img/hosted-singularity--hub-%23e32929.svg)](https://singularity-hub.org/collections/1404)
[![DOI](https://zenodo.org/badge/94193130.svg)](https://zenodo.org/badge/latestdoi/94193130)

![Workflow representation](template-nf.png)

## Description
...

## Dependencies

1. This pipeline is based on [nextflow](https://www.nextflow.io). As we have several nextflow pipelines, we have centralized the common information in the [IARC-nf](https://github.com/IARCbioinfo/IARC-nf) repository. Please read it carefully as it contains essential information for the installation, basic usage and configuration of nextflow and our pipelines.
2. External software:
- [facets](https://github.com/mskcc/facets)

You can avoid installing all the external software by only installing Docker. See the [IARC-nf](https://github.com/IARCbioinfo/IARC-nf) repository for more information.


## Input
  | Type      | Description     |
  |-----------|---------------|
  | --tumor_bam_folder    | Folder containing tumor BAM files |
  | --normal_bam_folder    | Folder containing normal BAM files|
  

  Specify the test files location

## Parameters

  * #### Mandatory
| Name      | Example value | Description     |
|-----------|---------------|-----------------|
| --snppileup_path    |            tools/ | Path to snppileup software 
| --ref    |            hg19/hg38 | Version of genome: hg19 or hg38 |
| --dbsnp_vcf_ref    |            ref/dbsnp_vcf_ref | Path to dbsnp vcf reference

  * #### Optional
| Name      | Default value | Description     |
|-----------|---------------|-----------------|
| --analysis_type    |            genome/exome | Type of analysis: whole genome (by default) or whole exome  |
| --suffix_tumor   |            "T" | specific suffix for tumor bam file name |
| --suffix_normal   |            "N" | specific suffix for normal bam file name |
| --min-map-quality   |            15 | 
| --min-base-quality    |            20 | 
| --pseudo-snps   |            100 | 
| --facets_stats_out   |            facets_stats_summary.txt | Name of stats summary file |
| --plot_file_out    |            png | Plot output in png or pdf |
| --out_folder    |            facets_out | Folder name for output files (by default current folder)|

  * #### Flags

Flags are special parameters without value.

| Name      | Description     |
|-----------|-----------------|
| --help    | Display help |
| --output_pdf    |Program outputs a pdf |

## Usage
  ```
  nextflow run facets.nf --snppileup_path path/to/snppileup --tumor_bam_folder path/to/T_BAMS --normal_bam_folder path/to/N_BAMS --analysis_type genome --ref hg38 --dbsnp_vcf_ref path/to/dbSNP_vcf_ref --out_folder path/to/output
  ```

## Output
  | Type      | Description     |
  |-----------|---------------|
  | output1    | ...... |
  | output2    | ...... |


## Detailed description (optional section)
...

## Directed Acyclic Graph
[![DAG](dag.png)](http://htmlpreview.github.io/?https://github.com/IARCbioinfo/template-nf/blob/master/dag.html)

## Contributions

  | Name      | Email | Description     |
  |-----------|---------------|-----------------|
  | contrib1*    |            xx | Developer to contact for support (link to specific gitter chatroom) |
  | contrib2    |            xx | Developer |
  | contrib3    |            xx | Tester |

## References (optional)

## FAQ (optional)

