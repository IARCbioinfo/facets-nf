#!/usr/bin/env nextflow

//help function for the tool
def show_help() {
  log.info IARC_Header()
  log.info tool_header()
  log.info """

    Usage:

    The typical command for running the pipeline is as follows:

    nextflow run iarcbioinfo/facets-nf -profile singularity [OPTIONS]

    Mandatory arguments:
      --tn_file              [file]    File containing list of T/N bam/cram files to be processed (T.bam, N.bam)
                                         Optional column: pair_mode = matched|tumor_only
      --ref                  [string]  Version of genome: hg19 or hg38 or hg18 [def:hg38]
      --dbsnp_vcf_ref        [path]    Path to dbsnp vcf reference file (with name of ref file)

    Optional parameters:
      --analysis_type        [string]  Type of analysis: genome or exome, def: genome
      --tumor_only           [bool]    Run all directory-based pairs in tumor-only unmatched mode [def:false]

      --snp_nbhd             [number]  By default 1000 for genome and 250 for exome
      --cval_preproc         [number]  By default 35 for genome, 25 for exome
      --cval_proc1           [number]  By default 150 for genome, 75 for exome
      --cval_proc2           [number]  By default 300 for genome, 150 for exome
      --min_read_count       [number]  By default 20 for genome, 35 for exome
      --unmatched_het_thresh [number]  Heterozygous VAF threshold in tumor-only mode [def:0.1]

      --m_cval               [bool]    Use multiple cval values (500,1000,1500) to study the number of segments [def:true]

    SNP-pileup options:
      --min-map-quality      [number]  Minimum read mapping quality [def:15]
      --min-base-quality     [number]  Minimum base quality [def:20]
      --pseudo-snps          [number]  window for pseudo-snps [def:100]


      Execution options:
      --snppileup_bin        [path]    Path to snppileup software (default: snp-pileup)
      -profile               [str]     Configuration profile to use (Available: singularity, docker, kutral)

    Outputs:
      --output_folder        [folder]  Folder name for output files (default: ./facets)

    Get tumor/normal pairs directly from cram/bam files:

      --cram                 [bool]    the input are CRAM files [def:false]

      Pairs in separate directories:

      --tumor_dir            [directory] Directory containing tumor bam/cram files
      --normal_dir           [directory] Directory containing normal bam/cram files

      Pairs in the same directory:

      --cohort_dir           [directory] Directory containing all bam/cram files

      Files suffixes :

      --suffix_tumor         [string]  tumor file name's specific suffix (by default _T)
      --suffix_normal        [string]  normal file name's specific suffix (by default _N)


    Visualization :

      --facets_plot          [bool]    Facets will generate a PDF output (def:true)

      """.stripIndent()
}

//we compute the snp_pileup process using 1CPU with low memory
process snppileup {
  tag "${tumor_id}-snppileup"
  label 'load_snpp'

  input:
  tuple val(tumor_id), val(pair_mode), path(tumor), path(tumor_index), path(normal, stageAs: 'normal/*'), path(normal_index, stageAs: 'normal/*')
  path vcf

  output:
  tuple val(tumor_id), val(pair_mode), path("${tumor_id}.csv.gz"), emit: snppileup_result

  script:
  if (params.debug == false) {
    """
    ${params.snppileup_bin} \\
    --gzip \\
    --min-map-quality ${params.min_map_quality} \\
    --min-base-quality ${params.min_base_quality} \\
    --pseudo-snps ${params.pseudo_snps} \\
    --min-read-counts ${params.min_read_count} \\
     ${vcf} ${tumor_id}.csv.gz ${normal} ${tumor}
    """
  } else {
    """
    echo ${params.snppileup_bin} \\
    --gzip \\
    --min-map-quality ${params.min_map_quality} \\
    --min-base-quality ${params.min_base_quality} \\
    --pseudo-snps ${params.pseudo_snps} \\
    --min-read-counts ${params.min_read_count} \\
     ${vcf} ${tumor_id}.csv.gz ${normal} ${tumor}
    #we create the file to continue our process
    touch ${tumor_id}.csv.gz
    """
  }
}

//we run FACETs with the create file
process facets {
  tag "${tumor_id}-facets"
  label 'load_facets'

  publishDir "${params.output_folder}/facets", mode: 'copy'

  input:
  tuple val(tumor_id), val(pair_mode), path(snppileup_counts)

  output:
  path("${tumor_id}.def_cval${params.cval_proc2}_stats.txt"), emit: stats_summary
  path("${tumor_id}.def_cval${params.cval_proc2}_CNV.txt"), emit: cnv
  path("${tumor_id}.def_cval${params.cval_proc2}_CNV_spider.pdf"), emit: cnv_spider
  path("${tumor_id}.R_sessionInfo.txt"), emit: session_info
  path("${tumor_id}.def_cval${params.cval_proc2}_CNV.png"), optional: true, emit: cnv_png
  path("${tumor_id}.def_cval${params.cval_proc2}_CNV.pdf"), optional: true, emit: cnv_pdf
  //we rescue other optional files for diferent cval values
  path("${tumor_id}.cval500_stats.txt"), optional: true, emit: stats_summary_cval500
  path("${tumor_id}.cval1000_stats.txt"), optional: true, emit: stats_summary_cval1000
  path("${tumor_id}.cval1500_stats.txt"), optional: true, emit: stats_summary_cval1500
  path("${tumor_id}.cval*.pdf"), optional: true, emit: cval_pdf
  path("${tumor_id}.cval*_CNV.txt"), optional: true, emit: cval_cnv

  script:
  def plot = params.output_pdf ? 'PDF' : 'NOPDF'
  def mcval = params.m_cval ? 'MCVAL' : 'CVAL'
  def is_tumor_only = pair_mode == 'tumor_only'
  def facets_script = is_tumor_only ? "${baseDir}/bin/facets.tumor_only.cval.r" : "${baseDir}/bin/facets.cval.r"
  if (params.debug == false) {
    if (is_tumor_only) {
      """
      Rscript ${facets_script} \\
              ${snppileup_counts} \\
              ${params.ref} ${params.snp_nbhd} \\
              ${params.cval_preproc} ${params.cval_proc1} ${params.cval_proc2} ${params.min_read_count} \\
              ${params.unmatched_het_thresh} ${mcval} ${plot}
      """
    } else {
      """
      Rscript ${facets_script} \\
              ${snppileup_counts} \\
              ${params.ref} ${params.snp_nbhd} \\
              ${params.cval_preproc} ${params.cval_proc1} ${params.cval_proc2} ${params.min_read_count} \\
              ${mcval} ${plot}
      """
    }
  } else {
    if (is_tumor_only) {
      """
      echo Rscript ${facets_script} \\
              ${snppileup_counts} \\
              ${params.ref} ${params.snp_nbhd} \\
              ${params.cval_preproc} ${params.cval_proc1} ${params.cval_proc2} ${params.min_read_count} \\
              ${params.unmatched_het_thresh} ${mcval} ${plot}
      #we touch some dummy file
      touch ${tumor_id}.def_cval${params.cval_proc2}_stats.txt
      touch ${tumor_id}.def_cval${params.cval_proc2}_CNV.txt
      touch ${tumor_id}.def_cval${params.cval_proc2}_CNV_spider.pdf
      touch ${tumor_id}.R_sessionInfo.txt
      echo "${tumor_id}\t0.8\t2\t0.8\t0.7" > ${tumor_id}.def_cval${params.cval_proc2}_stats.txt
      echo "${tumor_id}\t0.8\t2\t0.8\t0.7" >> ${tumor_id}.def_cval${params.cval_proc2}_stats.txt
      """
    } else {
      """
      echo Rscript ${facets_script} \\
              ${snppileup_counts} \\
              ${params.ref} ${params.snp_nbhd} \\
              ${params.cval_preproc} ${params.cval_proc1} ${params.cval_proc2} ${params.min_read_count} \\
              ${mcval} ${plot}
      #we touch some dummy file
      touch ${tumor_id}.def_cval${params.cval_proc2}_stats.txt
      touch ${tumor_id}.def_cval${params.cval_proc2}_CNV.txt
      touch ${tumor_id}.def_cval${params.cval_proc2}_CNV_spider.pdf
      touch ${tumor_id}.R_sessionInfo.txt
      echo "${tumor_id}\t0.8\t2\t0.8\t0.7" > ${tumor_id}.def_cval${params.cval_proc2}_stats.txt
      echo "${tumor_id}\t0.8\t2\t0.8\t0.7" >> ${tumor_id}.def_cval${params.cval_proc2}_stats.txt
      """
    }
  }
}

workflow {
  if (params.help) {
    show_help()
    return
  }

  if (params.facets_plot != null) {
    params.output_pdf = params.facets_plot
  }

  //we display the header of the tool
  log.info IARC_Header()
  log.info tool_header()

  //Check mandatory parameters
  assert (params.ref != null) : 'please specify --ref (hg19 or hg38)'
  assert (params.dbsnp_vcf_ref != null) : 'please specify --dbsnp_vcf_ref (path to ref)'
  assert (params.tn_file != null || (params.tumor_dir != null && params.normal_dir != null)) : 'please specify --tn_file or --tumor_dir with --normal_dir (path to ref)'

  if (params.tn_file != null && params.cohort_dir == null) {
    println '--cohort_dir shold be specified when using the --tn_file variable'
    exit 1
  }

  //change default for exome
  if (params.analysis_type == 'exome') {
    params.min_read_count = 35
    params.snp_nbhd = 250
    params.cval_preproc = 25
    params.cval_proc1 = 75
    params.cval_proc2 = 150
  }

  def tn_pairs = params.tn_file ?
    parse_tn_file(params.tn_file, params.cohort_dir, params.cram, params.tumor_only) :
    build_tn_pairs_from_dir(params.tumor_dir, params.normal_dir, params.suffix_tumor, params.suffix_normal, params.cram, params.tumor_only)

  def ch_vcf = Channel.fromPath(params.dbsnp_vcf_ref)
    .ifEmpty { exit 1, "VCF file not found: ${params.dbsnp_vcf_ref}" }
    .first()

  print_params()

  snppileup(tn_pairs, ch_vcf)
  facets(snppileup.out.snppileup_result)

  //we store a summary of global variables
  facets.out.stats_summary.collectFile(
    name: 'facets_stats_default_summary.txt',
    storeDir: params.output_folder,
    seed: 'Sample \t purity \t ploidy \t dipLogR \t loglik',
    newLine: true,
    skip: 1
  )
  facets.out.stats_summary_cval500.collectFile(
    name: 'facets_stats_cval500_summary.txt',
    storeDir: params.output_folder,
    seed: 'Sample \t purity \t ploidy \t dipLogR \t loglik',
    newLine: true,
    skip: 1
  )
  facets.out.stats_summary_cval1000.collectFile(
    name: 'facets_stats_cval1000_summary.txt',
    storeDir: params.output_folder,
    seed: 'Sample \t purity \t ploidy \t dipLogR \t loglik',
    newLine: true,
    skip: 1
  )
  facets.out.stats_summary_cval1500.collectFile(
    name: 'facets_stats_cval1500_summary.txt',
    storeDir: params.output_folder,
    seed: 'Sample \t purity \t ploidy \t dipLogR \t loglik',
    newLine: true,
    skip: 1
  )
}

/*
*
* Functions to create channels from TSV or directories containing BAM/CRAM
*
*/

//funtion that return the tn_bambai channel from a set of paths
def build_tn_pairs_from_dir(tumor_dir, normal_dir, suffix_tumor, suffix_normal, is_cram, tumor_only) {
  //we parse the tumor file and the normal files
  def tumor_files = parse_files_dir(tumor_dir, suffix_tumor, is_cram)
  def pair_mode = tumor_only ? 'tumor_only' : 'matched'
  def tn_pairs = tumor_files
    .join(parse_files_dir(normal_dir, suffix_normal, is_cram))
    .map { tumor_id, tumor, tumor_index, normal, normal_index -> [tumor_id, pair_mode, tumor, tumor_index, normal, normal_index] }

  //we create the tumor normal pairs Channel with index and sample names
  return tn_pairs
}

//this function load a BAM/CRAM along with the index for each file
def parse_files_dir(dir, suffix, is_cram) {
  def regex = is_cram ? /.*\.cram$/ : /.*\.bam$/
  def file_ext = is_cram ? '.cram' : '.bam'
  def file_index = is_cram ? '.crai' : '.bai'

  def input_dir = file(dir)
  assert input_dir.exists() : "\n WARNING : input alignment folder not located in execution directory"
  assert (input_dir.listFiles()?.findAll { it.name ==~ regex } ?: []).size() > 0 : 'alignment folder contains no BAM/CRAM files'

  def alignments = Channel.fromPath("${dir}/*${suffix}${file_ext}")
    .ifEmpty { error "Cannot find any bam/cram file in: ${dir}" }
    .map { path -> [path.name.replace("${suffix}${file_ext}", ''), path] }

  // recovering of index files
  def alignments_index = Channel.fromPath("${dir}/*${suffix}${file_ext}${file_index}")
    .ifEmpty { error "Cannot find any index file in: ${dir}" }
    .map { path -> [path.name.replace("${suffix}${file_ext}${file_index}", ''), path] }

  def aln_index = alignments.join(alignments_index)

  return aln_index
}

//we read the pairs from tn_file
def parse_tn_file(tn_file, cohort_path, is_cram, tumor_only) {
  // [sample t[.bam,cram] t[.bai,crai] n[.bam,.cram] n[.bai,.crai]]
  def index_ext = is_cram ? '.crai' : '.bai'
  def tn_pairs = Channel.fromPath(tn_file)
    .splitCsv(header: true, sep: '\t', strip: true)
    .map { row ->
      def pair_mode = normalize_pair_mode(row.pair_mode ?: row.mode ?: 'matched')
      assert row.normal != null : "tn_file row for ${row.tumor_id} must include a normal file"
      [
        row.tumor_id,
        pair_mode,
        file("${cohort_path}/${row.tumor}"),
        file("${cohort_path}/${row.tumor}${index_ext}"),
        file("${cohort_path}/${row.normal}"),
        file("${cohort_path}/${row.normal}${index_ext}")
      ]
    }
    .ifEmpty { exit 1, "${tn_file} was empty - no tumor/normal supplied" }

  //we return the channel
  return tn_pairs
}

def normalize_pair_mode(mode) {
  def normalized = mode?.toString()?.trim()?.toLowerCase()?.replace('-', '_')
  if (normalized in ['matched', 'tumor_only']) {
    return normalized
  }
  if (normalized in ['tumoronly', 'tonly', 'unmatched']) {
    return 'tumor_only'
  }
  throw new IllegalArgumentException("Unsupported pair mode '${mode}'. Use 'matched' or 'tumor_only'.")
}

// print the calling parameter to the log and a log file
def print_params() {
  //software versions for v2.0
  def software_versions = [
    'snp-pileup': '0.5.14',
    'r-base'    : '4.0.3',
    'data.table': '1.13.2',
    'facets'    : '0.5.14',
    'pctGCdata' : '0.2.0'
  ]

  //we print the parameters
  log.info '\n'
  log.info '-\033[2m------------------Calling PARAMETERS--------------------\033[0m-'
  log.info params.collect { k, v -> "${k.padRight(18)}: $v" }.join('\n')
  log.info '-\033[2m--------------------------------------------------------\033[0m-'
  log.info '\n'
  log.info '-\033[2m------------------Software versions--------------------\033[0m-'
  log.info software_versions.collect { k, v -> "${k.padRight(18)}: $v" }.join('\n')
  log.info '-\033[2m--------------------------------------------------------\033[0m-'
  log.info '\n'

  //we print the parameters to a log file
  def output_d = new File("${params.output_folder}/nf-pipeline_info/")
  if (!output_d.exists()) {
    output_d.mkdirs()
  }
  def output_tf = new File(output_d, 'run_parameters_report.txt')
  def report_params = '------------------Calling PARAMETERS--------------------\n'
  report_params += params.collect { k, v -> "${k.padRight(18)}: $v" }.join('\n')
  report_params += '\n--------------------------------------------------------\n'
  report_params += '\n------------------NEXTFLOW Metadata--------------------\n'
  report_params += "nextflow version : ${nextflow.version}\n"
  report_params += "nextflow build   : ${nextflow.build}\n"
  report_params += 'Command line     : \n' + workflow.commandLine.split(' ').join(' \\\n')
  report_params += '\n--------------------------------------------------------\n'
  report_params += '-----------------Software versions--------------------\n'
  report_params += software_versions.collect { k, v -> "${k.padRight(18)}: $v" }.join('\n')
  report_params += '\n--------------------------------------------------------\n'

  output_tf.withWriter { w -> w << report_params }
}

//this use ANSI colors to make a short tool description
//useful url: http://www.lihaoyi.com/post/BuildyourownCommandLinewithANSIescapecodes.html
def tool_header() {
  return """
        F\u001b[31;1mA\u001b[32;1mC\u001b[33;1mE\u001b[0mT\u001b[33;1ms\u001b[31;1m : Somatic\u001b[32;1m Copy\u001b[33;1m Number\u001b[31;1m Variant\u001b[33;1m caller\u001b[32;1m (${workflow.manifest.version})
        """
}

//header for the IARC tools
// the logo was generated using the following page
// http://patorjk.com/software/taag  (ANSI logo generator)
def IARC_Header() {
  return """
#################################################################################
# ██╗ █████╗ ██████╗  ██████╗██████╗ ██╗ ██████╗ ██╗███╗   ██╗███████╗ ██████╗  #
# ██║██╔══██╗██╔══██╗██╔════╝██╔══██╗██║██╔═══██╗██║████╗  ██║██╔════╝██╔═══██╗ #
# ██║███████║██████╔╝██║     ██████╔╝██║██║   ██║██║██╔██╗ ██║█████╗  ██║   ██║ #
# ██║██╔══██║██╔══██╗██║     ██╔══██╗██║██║   ██║██║██║╚██╗██║██╔══╝  ██║   ██║ #
# ██║██║  ██║██║  ██║╚██████╗██████╔╝██║╚██████╔╝██║██║ ╚████║██║     ╚██████╔╝ #
# ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═════╝ ╚═╝ ╚═════╝ ╚═╝╚═╝  ╚═══╝╚═╝      ╚═════╝  #
# Nextflow pilelines for cancer genomics.########################################
"""
}
