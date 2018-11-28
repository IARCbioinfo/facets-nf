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

params.snppileup_path = null

params.help = null
params.tumor_bam_folder = null
params.normal_bam_folder = null
params.suffix_tumor = "_T"
params.suffix_normal = "_N"
params.tn_file = null
params.analysis_type = "genome"
params.snp_nbhd = null
params.cval_preproc = null
params.cval_proc1 = null
params.cval_proc2 = null
params.min_read_count = null
if (params.analysis_type == 'genome' ) {
			snp_nbhd = 1000   
			cval_preproc = 35
			cval_proc1 = 300
			cval_proc2 = 150
			min_read_count = 20
			}
if (params.analysis_type == 'exome') {
			snp_nbhd = 250   
			cval_preproc = 25
			cval_proc1 = 150
			cval_proc2 = 75
			min_read_count = 35
			}

params.ref = null
params.dbsnp_vcf_ref = null
params.min_map_quality = 15
params.min_base_quality = 20
params.pseudo_snps =100
params.output_pdf = false
params.facets_stats_out = 'facets_stats_summary.txt'
params.plot_file_out = 'png'
params.output_folder = 'out_facets'

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
    log.info ""
    log.info "--snppileup_path	     PATH		 Path to snppileup software"
    log.info "--tumor_bam_folder     FOLDER              Folder containing tumor bam files"
    log.info "--normal_bam_folder    FOLDER              Folder containing tumor bam files"    
    log.info "--ref                  STRING              Version of genome: hg19 or hg38 or hg18 or mm9 or mm10"
    log.info "--dbsnp_vcf_ref	     PATH		 Path to dbsnp vcf reference file"

    log.info "Optional arguments:"
    log.info "--analysis_type        STRING              Type of analysis: exome or genome"
    log.info "--suffix_tumor	     STRING		 tumor file name's specific suffix (by default _T)"
    log.info "--suffix_normal	     STRING		 normal file name's specific suffix (by default _N)"
    log.info "--min-map-quality	     NUMBER		 "
    log.info "--min-base-quality     NUMBER		 "
    log.info "--pseudo-snps          NUMBER		 "
    log.info "--facets_stats_out     FILE                Name of stats summary file"
    log.info "--plot_file_out        FILE TYPE           Plot output in png or pdf"
    log.info "--out_folder           FOLDER              Folder name for output files"
    log.info ""
    log.info "Flags:"
    log.info "--output_pdf           Program will generate a PDF output (takes longer)"
    log.info ""
    exit 0
} 

//Check the params
assert (params.snppileup_path != true) && (params.snppileup_path != null) : "please specify --snppileup_path"
assert (params.tumor_bam_folder != true) && (params.tumor_bam_folder != null) : "please specify --tumor_bam_folder"
assert (params.normal_bam_folder != true) && (params.normal_bam_folder != null) : "please specify --normal_bam_folder"
assert (params.analysis_type != true) && (params.analysis_type != null) : "please specify --analysis_type (exome or genome)"
assert (params.ref != true) && (params.ref != null) : "please specify --ref (hg19 or hg38)"
assert (params.dbsnp_vcf_ref != true) && (params.dbsnp_vcf_ref != null) : "please specify --dbsnp_vcf_ref (path to ref)"
//assert (params.snp_nbhd != null) : "please specify --snp_nbhd"
//assert (params.cval_preproc != null) : "please specify --cval_preproc"
//assert (params.cval_proc1 != null) : "please specify --cval_proc1"
//assert (params.cval_proc2 != null) : "please specify --cval_proc2"
//assert (params.min_read_count != null) : "please specify --min_read_count"


if (params.tn_file) {
    // FOR INPUT AS A TAB DELIMITED FILE
    tn_bambai = Channel.fromPath(params.tn_file).splitCsv(header: true, sep: '\t', strip: true).map{row -> [ file(params.bam_folder + "/" + row.tumor), file(params.bam_folder + "/" + row.tumor+'.bai') ,file(params.bam_folder + "/" + row.normal), file(params.bam_folder + "/" + row.normal+'.bai') ]}
} else {

//Build pairs of bams with their corresponding bais
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
}

process snppileup {
// Input folder with pairs of bam => Output: pairX.csv.gz

    input:
    file tn from tn_bambai

    output:
    set val(tumor_normal_tag), file("${tumor_normal_tag}.csv.gz") into snppileup4pair

    shell:
    tumor_normal_tag = tn[0].baseName.replace(params.suffix_tumor,"")  
    '''
    !{params.snppileup_path}/snp-pileup --gzip --min-map-quality !{params.min_map_quality} --min-base-quality !{params.min_base_quality} --pseudo-snps !{params.pseudo_snps} --min-read-counts !${min_read_count} !{params.dbsnp_vcf_ref}  !{tumor_normal_tag}!{params.suffix_normal}.bam !{tumor_normal_tag}!{params.suffix_tumor}.bam
    '''
}

process facets {
// Input: pairX.csv.gz => Outputs: pairX_stats.txt (to aggregate into 1 file), CNV.txt, CNV.png (or pdf) , CNV_spider.pdf

    tag { tumor_normal_tag }
    
    publishDir params.out_folder+'/all_facets_stats/', mode: 'move'
    
    input:
    set val(tumor_normal_tag), file("${tumor_normal_tag}.csv.gz") from snppileup4pair

    output:
	   file("${tumor_normal_tag}_stats.txt") into stats_summary
	   file("${tumor_normal_tag}_CNV.txt")
	   file("${tumor_normal_tag}_CNV_spider.txt")
	   if (params.output_pdf) {
	   file("${tumor_normal_tag}_CNV.png")
	   }
	   else { 
	   file("${tumor_normal_tag}_CNV.pdf")
	   }


    shell:
	
	if (params.output_pdf)
    	'''
   	 facets.r !${tumor_normal_tag}.csv.gz !{params.ref} !${snp_nbhd} !${cval_preproc} !${cval_proc1} !${cval_proc2} !${min_read_count}
    	'''
    	else
    	'''
    	facets.r !${tumor_normal_tag}.csv.gz !{params.ref} !${snp_nbhd} !${cval_preproc} !${cval_proc1} !${cval_proc2} !${min_read_count} PDF
    	'''    
}

    stats_summary.collectFile(name: params.stats_out, storeDir: params.out_folder, seed: 'Sample \t purity \t ploidy \t dipLogR \t loglik')
