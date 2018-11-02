#! /usr/bin/env nextflow

// Copyright (C) 2017 IARC/WHO

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

// requires: snp-pileup

params.snppileup_dir = ##############FOLDER_TO_SNP_PILEUP

params.help = null
params.tumor_bam_folder = null
params.normal_bam_folder = null
params.suffix_tumor = "_T"
params.suffix_normal = "_N"
params.analysis_type = null
params.ref = null
params.dbsnp_vcf_ref = ################# human_9606_b150_GRCh38p7.vcf.gz
params.coverage = null
params.segmentation = null
params.facets_stats_out = 'facets_stats_summary.txt'
params.plot_file_out = 'png'
params.output_folder = .


log.info ""
log.info "--------------------------------------------------------"
log.info "  <PROGRAM_NAME> <VERSION>: <SHORT DESCRIPTION>         "
log.info "--------------------------------------------------------"
log.info "Copyright (C) IARC/WHO"
log.info "This program comes with ABSOLUTELY NO WARRANTY; for details see LICENSE"
log.info "This is free software, and you are welcome to redistribute it"
log.info "under certain conditions; see LICENSE for details."
log.info "--------------------------------------------------------"
log.info ""

if (params.help) {
    log.info "--------------------------------------------------------"
    log.info "  USAGE                                                 "
    log.info "--------------------------------------------------------"
    log.info ""
    log.info "-------------------FACETS-------------------------------"
    log.info ""
    log.info "nextflow run iarcbioinfo/facets-nf [-with-docker] [OPTIONS]"
    log.info ""
    log.info "Mandatory arguments:"
    log.info "
    log.info "--tumor_bam_folder     FOLDER              Folder containing tumor bam files"
    log.info "--normal_bam_folder    FOLDER              Folder containing tumor bam files"    
    log.info "--analysis_type        STRING              Type of analysis: exome or genome"
    log.info "--ref                  STRING              Version of genome: hg19 or hg38"
    log.info "--coverage             NUMBER              Normal bams coverage"   
    log.info "--segmentation         NUMBER              Segmentation: number between 1 and 4"
    log.info ""
    log.info "Optional arguments:"
    log.info "--facets_stats_out     FILE                Name of stats summary file
    log.info "--plot_file_out        FILE TYPE           Plot output in png or pdf"
    log.info "--out_folder           FOLDER              Folder name for output files
    log.info ""
    log.info "Flags:"
    log.info "--<FLAG>                                                    <DESCRIPTION>"
    log.info ""
    exit 0
} 

#Check the params
assert (params.tumor_bam_folder != true) && (params.tumor_bam_folder != null) : "please specify --tumor_bam_folder"
assert (params.normal_bam_folder != true) && (params.normal_bam_folder != null) : "please specify --normal_bam_folder"
assert (params.analysis_type != true) && (params.analysis_type != null) : "please specify --analysis_type option (exome or genome)"
assert (params.ref != true) && (params.ref != null) : "please specify --ref option (hg19 or hg38)"

#Build pairs of bams with their corresponding bais
    try { assert file(params.tumor_bam_folder).exists() : "\n WARNING : input tumor BAM folder not located in execution directory" } catch (AssertionError e) { println e.getMessage() }
	assert file(params.tumor_bam_folder).listFiles().findAll { it.name ==~ /.*bam/ }.size() > 0 : "tumor BAM folder contains no BAM"
	try { assert file(params.normal_bam_folder).exists() : "\n WARNING : input normal BAM folder not located in execution directory" } catch (AssertionError e) { println e.getMessage() }
	assert file(params.normal_bam_folder).listFiles().findAll { it.name ==~ /.*bam/ }.size() > 0 : "normal BAM folder contains no BAM"

	// FOR TUMOR 
	// recovering of bam files
	tumor_bams = Channel.fromPath( params.tumor_bam_folder+'/*'+params.suffix_tumor+'.bam' )
		    .ifEmpty { error "Cannot find any bam file in: ${params.tumor_bam_folder}" }
		    .map {  path -> [ path.name.replace("${params.suffix_tumor}.bam",""), path ] }

	// recovering of bai files
	tumor_bais = Channel.fromPath( params.tumor_bam_folder+'/*'+params.suffix_tumor+'.bam.bai' )
		    .ifEmpty { error "Cannot find any bai file in: ${params.tumor_bam_folder}" }
		    .map {  path -> [ path.name.replace("${params.suffix_tumor}.bam.bai",""), path ] }

	// building bam-bai pairs
	tumor_bam_bai = tumor_bams
		    .phase(tumor_bais)
		    .map { tumor_bam, tumor_bai -> [ tumor_bam[0], tumor_bam[1], tumor_bai[1] ] }

	// FOR NORMAL 
	// recovering of bam files
	normal_bams = Channel.fromPath( params.normal_bam_folder+'/*'+params.suffix_normal+'.bam' )
		    .ifEmpty { error "Cannot find any bam file in: ${params.normal_bam_folder}" }
		    .map {  path -> [ path.name.replace("${params.suffix_normal}.bam",""), path ] }

	// recovering of bai files
	normal_bais = Channel.fromPath( params.normal_bam_folder+'/*'+params.suffix_normal+'.bam.bai' )
		    .ifEmpty { error "Cannot find any bai file in: ${params.normal_bam_folder}" }
		    .map {  path -> [ path.name.replace("${params.suffix_normal}.bam.bai",""), path ] }

	// building bam-bai pairs
	normal_bam_bai = normal_bams
		    .phase(normal_bais)
		    .map { normal_bam, normal_bai -> [ normal_bam[0], normal_bam[1], normal_bai[1] ] }

	// building 4-uplets corresponding to {tumor_bam, tumor_bai, normal_bam, normal_bai}
	tn_bambai = tumor_bam_bai
		.phase(normal_bam_bai)
		.map {tumor_bb, normal_bb -> [ tumor_bb[1], tumor_bb[2], normal_bb[1], normal_bb[2] ] }    
	// here each element X of tn_bambai channel is a 4-uplet. X[0] is the tumor bam, X[1] the tumor bai, X[2] the normal bam and X[3] the normal bai.


process snppileup {
# Input folder with pairs of bam => Output: pairX.csv.gz

	tag { tumor_normal_tag }
    
    input:
    file tn from tn_bambai

    output:
    set val(tumor_normal_tag), file("${tumor_normal_tag}.csv.gz") into snppileup4pair

    shell:
    tumor_normal_tag = tn[0].baseName.replace(params.suffix_tumor,"")
    '''
    !{params.snppileup_dir}/snp-pileup --gzip --min-map-quality 15 --min-base-quality 20 --pseudo-snps 100 --min-read-counts 20,0 ~/!{params.dbsnp_vcf_ref}  !{tumor_normal_tag}!{params.suffix_normal}.bam !{tumor_normal_tag}!{params.suffix_tumor}.bam
    '''
}

process facets {
# Input: pairX.csv.gz => Outputs: pairX_stats.txt (to aggregate into 1 file), CNV.txt, CNV.png (or pdf) , CNV_spider.pdf

	tag { tumor_normal_tag }
    
    publishDir params.out_folder+'/all_facets_stats/', mode: 'move'
    
    input:
    file("${tumor_normal_tag}.csv.gz from snppileup4pair

    output:
	   file("${tumor_normal_tag}_stats.txt")
	   stdout stats_summary
       ##CNV.txt + CNV.png + CNV_Spider.pdf

    shell:
    tumor_normal_tag = tn[0].baseName.replace(params.suffix_tumor,"")
    '''
    facets.r !${tumor_normal_tag}.csv.gz !{params.analysis_type} 10000 100 1000 300 20
    '''
}

	stats_summary.collectFile(name: params.stats_out, storeDir: params.out_folder, seed: 'MyHeader')
