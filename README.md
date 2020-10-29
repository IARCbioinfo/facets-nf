# facets-nf
## current version 2.0

[![CircleCI](https://circleci.com/gh/IARCbioinfo/template-nf.svg?style=svg)](https://circleci.com/gh/IARCbioinfo/facets-nf)
[![Docker Hub](https://img.shields.io/badge/docker-ready-blue.svg)](https://hub.docker.com/r/iarcbioinfo/facets-nf/)
[![DOI](https://zenodo.org/badge/94193130.svg)](https://zenodo.org/badge/latestdoi/94193130)


Table of Contents
=================
  * [Description](#description)
  * [Usage](#usage)
  * [Dependencies](#dependencies)
  * [Input (mandatory)](#input--mandatory-)
    + [Example of Tumor/Normal pairs file (--tn_file)](#example-of-tumor-normal-pairs-file----tn-file-)
  * [Parameters](#parameters)
      - [Minimal](#minimal)
      - [Optional](#optional)
  * [Output](#output)
  * [Common errors](#common-errors)
    + [Facets](#facets)
    + [Singularity](#singularity)
  * [Contributions](#contributions)


## Description
Pipeline using facets for fraction and copy number estimate from tumor/normal sequencing data.

## Usage
  ```
  #using a tn_pairs file
  nextflow run iarcbioinfo/facets-nf -r 2.0 \
   -profile singularity --ref hg38  \
   --dbsnp_vcf_ref snps.vcf.gz \
   --tn_file tn_pairs.txt \
   --cohort_dir /path/CRAM 
  
  # Or using directories storing the CRAM/BAM files
  nextflow run iarcbioinfo/facets-nf -r 2.0 \
   -profile singularity --ref hg38  \
   --dbsnp_vcf_ref snps.vcf.gz \
   --tumor_dir /path/tumor \
   --normal_dir /path/normal  
  
  #activate CRAM files mode
  nextflow run iarcbioinfo/facets-nf -r 2.0 \
   -profile singularity --ref hg38  \
   --dbsnp_vcf_ref snps.vcf.gz \
   --tumor_dir /path/tumor \
   --normal_dir /path/normal  \
   --cram true  
  ```

## Dependencies

1. This pipeline is based on [nextflow](https://www.nextflow.io). As we have several nextflow pipelines, we have centralized the common information in the [IARC-nf](https://github.com/IARCbioinfo/IARC-nf) repository. Please read it carefully as it contains essential information for the installation, basic usage and configuration of nextflow and our pipelines.
2. External software:
- [facets](https://github.com/mskcc/facets)

You can avoid installing all the external software by only installing Docker or singularity.
See the [IARC-nf](https://github.com/IARCbioinfo/IARC-nf) repository for more information.


## Input (mandatory)

  | Type      | Description   |
  |-----------|---------------|
  | --tumor_dir   | Folder containing tumor BAM/CRAM files  |
  | --normal_dir     | Folder containing normal BAM/CRAM files|
  OR
  | --cohort_dir    | Folder containing all BAM/CRAM files |  
  | --tn_file    | File containing the list of names of BAM files to be processed |
  
### Example of Tumor/Normal pairs file (--tn_file)
A text file tabular separated, with the following header:

```
tumor_id	sample	tumor	normal
sample1_T1	sample1	sample1_T.cram	sample1_N.cram
sample2_T1	sample2	sample2_T.cram	sample2_N.cram
sample3_T1	sample3	sample3_T.cram	sample3_N.cram
``` 


## Parameters

#### Minimal

| Name      | Example value | Description     |
|-----------|---------------|-----------------|
|  --tn_file|		         [file]|  File containing list of T/N bam/cram files to be processed (T.bam, N.bam)|
|      --ref|                [string] |Version of genome: hg19 or hg38 or hg18 [def:hg38]|
|--dbsnp_vcf_ref	|     [path]| Path to dbsnp vcf reference file (with name of ref file) |

SNP reference (vcf file) can be downloaded from:

* hg19: `wget ftp://ftp.ncbi.nlm.nih.gov/snp/organisms/human_9606_b150_GRCh37p13/VCF/00-common_all.vcf.gz`

* hg38: `wget ftp://ftp.ncbi.nlm.nih.gov/snp/organisms/human_9606_b150_GRCh38p7/VCF/00-common_all.vcf.gz`

#### Optional

| Name      | type | Description     |
|-----------|---------------|-----------------|
|     --analysis_type |  [string] | Type of analysis: genome or exome, def: genome |
|      --snp_nbhd	|         [number]	| By default 1000 for genome and 250 for exome |
|      --cval_preproc	|    [number]	| By default 35 for genome, 25 for exome|
|      --cval_proc1	   |    [number]	| By default 150 for genome, 75 for exome |
|      --cval_proc2	   |    [number]	| By default 300 for genome, 150 for exome |
|     --min_read_count	|    [number]	| By default 20 for genome, 35 for exome |
|      --m_cval         |    [bool]  |  Use multiple cval values (500,1000,1500) to study the number of segments [def:true] |
|**SNP-pileup options** |||
|  --min-map-quality	 |  [number]	| Minimum read mapping quality [def:15]|
|      --min-base-quality |  [number]	| Minimum base quality [def:20] |
|      --pseudo-snps      | [number]	| window for pseudo-snps [def:100]|
|**Execution options**|||
|  --snppileup_bin	|     [path]		| Path to snppileup software (default: snp-pileup) |
|      -profile |            [str]  |   Configuration profile to use (Available: singularity, docker)|
|**Outputs**|||
|      --output_folder   |     [folder]  |  Folder name for output files (default: ./result) |
|**input is CRAM**|||
|      --cram       |  [bool]   |      the input are CRAM files [def:false]|
|**Pairs in separate directories**|||
|      --tumor_dir  |   [directory] |      Directory containing tumor bam/cram files|
|      --normal_dir |   [directory] |      Directory containing normal bam/cram files|
|      --cohort_dir  |  [directory] |      Directory containing all bam/cram files |
|**Files suffixes**|||
|      --suffix_tumor	|     [string] |		 tumor file name's specific suffix (by default _T)|
|      --suffix_normal |	     [string] |		 normal file name's specific suffix (by default _N) |
|**Visualization**|||
|--facets_plot| [bool] | Facets will generate a PDF output (def:true)|





## Output

```
results
├── facets
│   ├── LNEN047_TU.def_cval300_CNV.pdf #Facet plot for cval=300 (default for genome).
│   ├── LNEN047_TU.def_cval300_CNV_spider.pdf # Spider plot (QC).
│   ├── LNEN047_TU.def_cval300_CNV.txt # CNV segments.
│   ├── LNEN047_TU.def_cval300_stats.txt # Ploidy and Purity.
│   ├── LNEN047_TU.R_sessionInfo.txt # R sesion information.
│   ├── ... 
├── facets_stats_default_summary.txt #Summary of ploidy and purity for all samples
└── nf-pipeline_info #nexflow info directory
    ├── facets_dag.html
    ├── facets_report.html
    ├── facets_timeline.html
    ├── facets_trace.txt
    └── run_parameters_report.txt #custom file providing info for software versions
```

## Common errors

### Facets
In case of low coverage you may get the following error during facets process:
  ```
  Loading required package: pctGCdata
  Error in fit.cpt.tree(genomdat, cval = cval, hscl = hscl, delta = delta) :
  NA/NaN/Inf in foreign function call (arg 9)
  Calls: preProcSample -> segsnps -> fit.cpt.tree
  ```
=> We advise then to decrease the parameter: min_read_count

### Singularity
The first time that the container is built from the docker image, the TMPDIR  should be defined in a non parallel file-system, you can set this like:

```
export TMPDIR=/tmp
```

## Contributions

  | Name      | Email | Description     |
  |-----------|---------------|-----------------|
  | Matthieu Foll*    |            follm@iarc.fr | Developer to contact for support (link to specific gitter chatroom) |
  | Catherine Voegele    |            voegelec@iarc.fr | Developer |
  | Nicolas Alcala    |            alcalan@fellows.iarc.fr | Developer |
  | Alex Di Genova | digenovaa@fellows.iarc.fr| Developer |
