include { BWAMEM2_MEM             } from '../../../modules/nf-core/bwamem2/mem/main'
include { BAM_SORT_STATS_SAMTOOLS } from '../../nf-core/bam_sort_stats_samtools/main'

workflow FASTQ_ALIGN_BWAMEM2 {

    take:
    ch_reads          // channel: [ val(meta), [ reads ] ]
    ch_index          // channel: [meta, ref index]
    ch_fasta_fai      // channel: [meta, fasta, fai]
    sort_bam          // value: true

    main:

    // Extract [meta, fasta] for BWAMEM2_MEM which only needs the fasta
    ch_fasta = ch_fasta_fai.map { meta, fasta, _fai -> [ meta, fasta ] }

    //
    // Map reads with BWA 2 mem
    //
    BWAMEM2_MEM ( ch_reads, ch_index, ch_fasta, sort_bam )

    //
    // Sort, index BAM file and run samtools stats, flagstat and idxstats
    //
    BAM_SORT_STATS_SAMTOOLS ( BWAMEM2_MEM.out.bam, ch_fasta_fai )

    emit:
    bam_orig         = BWAMEM2_MEM.out.bam                  // channel: [ val(meta), aligned ]
    bam              = BAM_SORT_STATS_SAMTOOLS.out.bam      // channel: [ val(meta), [ bam ] ]
    bai              = BAM_SORT_STATS_SAMTOOLS.out.bai      // channel: [ val(meta), [ bai ] ]
    csi              = BAM_SORT_STATS_SAMTOOLS.out.csi      // channel: [ val(meta), [ csi ] ]
    stats            = BAM_SORT_STATS_SAMTOOLS.out.stats    // channel: [ val(meta), [ stats ] ]
    flagstat         = BAM_SORT_STATS_SAMTOOLS.out.flagstat // channel: [ val(meta), [ flagstat ] ]
    idxstats         = BAM_SORT_STATS_SAMTOOLS.out.idxstats // channel: [ val(meta), [ idxstats ] ]
}
