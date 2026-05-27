//
// Process short raw reads with FastP
//

include { FASTP as FASTP_SINGLE } from '../../../modules/nf-core/fastp/main'
include { FASTP as FASTP_PAIRED } from '../../../modules/nf-core/fastp/main'

workflow SHORTREAD_FASTP {
    take:
    ch_reads       // [[meta], [reads]]
    ch_adapterlist

    main:
    ch_multiqc_files = channel.empty()

    ch_input_for_fastp = ch_reads.branch {
        single: it[0]['single_end'] == true
        paired: it[0]['single_end'] == false
    }

    ch_fastp_input_single = ch_input_for_fastp.single
        .map { meta, reads -> [meta, reads, [] ] }
    ch_fastp_input_paired = ch_input_for_fastp.paired
        .map { meta, reads -> [meta, reads, [] ] }

    FASTP_SINGLE(ch_fastp_input_single, false, false, false)
    // Last parameter here turns on merging of PE data
    FASTP_PAIRED(ch_fastp_input_paired, false, false, params.shortread_qc_mergepairs)

    //FASTP_SINGLE(ch_input_for_fastp.single, ch_adapterlist, false, false, false)
    // Last parameter here turns on merging of PE data
    //FASTP_PAIRED(ch_input_for_fastp.paired, ch_adapterlist, false, false, params.shortread_qc_mergepairs)

    if (params.shortread_qc_mergepairs) {
        ch_fastp_reads_prepped_pe = FASTP_PAIRED.out.reads_merged.map { meta, merged_reads ->
            [meta + [single_end: true], [merged_reads].flatten()]
        }

        ch_fastp_reads_prepped = ch_fastp_reads_prepped_pe.mix(FASTP_SINGLE.out.reads)
    }
    else {
        ch_fastp_reads_prepped = FASTP_PAIRED.out.reads.mix(FASTP_SINGLE.out.reads)
    }

    ch_processed_reads = ch_fastp_reads_prepped

    ch_multiqc_files = ch_multiqc_files.mix(FASTP_SINGLE.out.json)
    ch_multiqc_files = ch_multiqc_files.mix(FASTP_PAIRED.out.json)

    emit:
    reads    = ch_processed_reads // channel: [ val(meta), [ reads ] ]
    mqc      = ch_multiqc_files
}
