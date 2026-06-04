//
// Perform long read mapping and variant calling
//

include { MINIMAP2_ALIGNMENT      } from '../minimap2_alignment/main'
include { BAM_SORT_STATS_SAMTOOLS } from '../../nf-core/bam_sort_stats_samtools/main'
include { CLAIR3                  } from '../../../modules/nf-core/clair3/main'
include { BCFTOOLS_SORT           } from '../../../modules/nf-core/bcftools/sort/main'
include { BCFTOOLS_INDEX          } from '../../../modules/nf-core/bcftools/index/main'
include { BCFTOOLS_VIEW           } from '../../../modules/nf-core/bcftools/view/main'
include { BCFTOOLS_NORM           } from '../../../modules/nf-core/bcftools/norm/main'
include { BCFTOOLS_STATS          } from '../../../modules/nf-core/bcftools/stats/main'
include { CONSENSUS_BCFTOOLS      } from '../consensus_bcftools/main'
include { SEQTK_COMP              } from '../../../modules/nf-core/seqtk/comp/main.nf'

workflow LONGREAD_MAPPING {

    take:
    ch_fasta // channel: [meta, ref]
    ch_faidx // channel: [meta, ref index]
    ch_reads // channel: [meta2, fasta/fastq]

    main:
    ch_multiqc_files = channel.empty()

    // Combine fasta and fai into a single channel for subworkflows that need both
    ch_fasta_fai = ch_fasta.join( ch_faidx ) // channel: [ val(meta), path(fasta), path(fai) ]

    MINIMAP2_ALIGNMENT( ch_fasta, ch_reads )

    BAM_SORT_STATS_SAMTOOLS ( MINIMAP2_ALIGNMENT.out.minimap_align,  ch_fasta_fai )
    ch_multiqc_files = ch_multiqc_files.mix( BAM_SORT_STATS_SAMTOOLS.out.stats )

    ch_clair3_input = BAM_SORT_STATS_SAMTOOLS.out.bam
        .join(BAM_SORT_STATS_SAMTOOLS.out.index)
        .map {
            meta, bam, index ->
            [ meta, bam, index, [], params.clair3_model, params.clair3_platform ]
        }

    CLAIR3 (ch_clair3_input, ch_fasta, ch_faidx)

    BCFTOOLS_SORT ( CLAIR3.out.vcf )

    BCFTOOLS_INDEX ( BCFTOOLS_SORT.out.vcf )

    ch_bcftool_view_input = BCFTOOLS_SORT.out.vcf.join(BCFTOOLS_INDEX.out.index)
    BCFTOOLS_VIEW ( ch_bcftool_view_input, [], [], [] )

    ch_bcftool_norm_input = BCFTOOLS_VIEW.out.vcf.join(BCFTOOLS_VIEW.out.index)
    BCFTOOLS_NORM ( ch_bcftool_norm_input, ch_fasta )

    ch_bcftool_stats_input = BCFTOOLS_NORM.out.vcf.join(BCFTOOLS_NORM.out.index)

    BCFTOOLS_STATS ( ch_bcftool_stats_input, [ [:], [] ], [ [:], [] ], [ [:], [] ], [ [:], [] ], [ [:], [] ] )
    ch_multiqc_files = ch_multiqc_files.mix( BCFTOOLS_STATS.out.stats )

    CONSENSUS_BCFTOOLS ( BAM_SORT_STATS_SAMTOOLS.out.bam, BCFTOOLS_NORM.out.vcf, BCFTOOLS_NORM.out.index, ch_fasta )

    SEQTK_COMP( CONSENSUS_BCFTOOLS.out.consensus )

    emit:
    bam         = BAM_SORT_STATS_SAMTOOLS.out.bam   // channel: [ val(meta), [ bam ] ]
    index       = BAM_SORT_STATS_SAMTOOLS.out.index // channel: [ val(meta), [ index ] ]
    vcf         = BCFTOOLS_NORM.out.vcf             // channel: [meta, vcf]
    norm_index  = BCFTOOLS_NORM.out.index           // channel: [ val(meta), path(index) ]
    stats       = BCFTOOLS_STATS.out.stats          // channel: [meta, stats]
    consensus   = CONSENSUS_BCFTOOLS.out.consensus  // channel: [ val(meta), path(consensus) ]
    seqtk_stats = SEQTK_COMP.out.seqtk_stats        // channel: [meta, stats]
    mqc         = ch_multiqc_files                  // channel: [ val(meta), [ multiqc files ] ]
}

