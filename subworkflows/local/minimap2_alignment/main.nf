include { MINIMAP2_INDEX      } from '../../../modules/nf-core/minimap2/index/main'
include { MINIMAP2_ALIGN      } from '../../../modules/nf-core/minimap2/align/main'

workflow MINIMAP2_ALIGNMENT {

    take:

    ch_ref   // channel: [meta, ref]
    ch_fasta // channel: [meta2, fasta/fastq]

    main:

    MINIMAP2_INDEX ( ch_ref )

    MINIMAP2_ALIGN ( ch_fasta, MINIMAP2_INDEX.out.index, params.bam_format, params.bam_index_extension, params.cigar_paf_format, params.cigar_bam )

    if (params.bam_format) {
        minimap_out = MINIMAP2_ALIGN.out.bam
    } else {
        minimap_out = MINIMAP2_ALIGN.out.paf
    }

    if (params.bam_index_extension) {
        minimap_index = MINIMAP2_ALIGN.out.index
    } else {
        minimap_index = []
    }
    emit:
    minimap_align = minimap_out       // channel: [ val(meta), [ bam ] ]
    minimap_index = minimap_index     // channel: [ val(meta), [ index ] ]
}

