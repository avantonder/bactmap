//
// Perform filtering
//

include { FILTLONG } from '../../../modules/nf-core/filtlong/main'
include { NANOQ    } from '../../../modules/nf-core/nanoq/main'

workflow LONGREAD_FILTERING {
    take:
    ch_reads // [ [ meta ], [ reads ] ]

    main:
    ch_multiqc_files = channel.empty()

    // fastp complexity filtering is activated via modules.conf in shortread_preprocessing
    if (params.longread_filter_tool == 'filtlong') {
        ch_filtered_reads = FILTLONG(ch_reads.map { meta, long_reads -> [meta, [], long_reads] }).reads
        ch_multiqc_files = ch_multiqc_files.mix(FILTLONG.out.log)
    }
    else if (params.longread_filter_tool == 'nanoq') {
        ch_filtered_reads = NANOQ(ch_reads, 'fastq.gz').reads
        ch_multiqc_files = ch_multiqc_files.mix(NANOQ.out.stats)
    }
    else {
        ch_filtered_reads = ch_reads
    }

    emit:
    reads    = ch_filtered_reads // channel: [ val(meta), [ reads ] ]
    mqc      = ch_multiqc_files
}
