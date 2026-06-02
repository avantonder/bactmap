//
// Perform short read mapping and variant calling
//

include { FASTQ_ALIGN_BWAMEM2                         } from '../fastq_align_bwamem2/main'
include { FASTQ_ALIGN_BOWTIE2                         } from '../../nf-core/fastq_align_bowtie2/main'
include { BAM_VARIANT_CALLING_SORT_FREEBAYES_BCFTOOLS } from '../../local/bam_variant_calling_sort_freebayes_bcftools/main'
include { BCFTOOLS_FILTER                             } from '../../../modules/nf-core/bcftools/filter/main'
include { BCFTOOLS_NORM                               } from '../../../modules/nf-core/bcftools/norm/main'
include { BCFTOOLS_STATS                              } from '../../../modules/nf-core/bcftools/stats/main'
include { CONSENSUS_BCFTOOLS                          } from '../consensus_bcftools/main'
include { SEQTK_COMP                                  } from '../../../modules/nf-core/seqtk/comp/main.nf'

workflow SHORTREAD_MAPPING {

    take:
    ch_reads  // channel: [ val(meta), [ reads ] ]
    ch_fasta // channel: [meta, ref]
    ch_index // channel: [meta, ref index]
    ch_faidx // channel: [meta, ref fai]

    main:
    ch_multiqc_files = channel.empty()

    // Combine fasta and fai into a single channel for subworkflows that need both
    ch_fasta_fai = ch_fasta.join( ch_faidx ) // channel: [ val(meta), path(fasta), path(fai) ]

    if (params.shortread_mapping_tool == 'bowtie2') {
        FASTQ_ALIGN_BOWTIE2 (
            ch_reads,
            ch_index,
            false,
            false,
            ch_fasta_fai
        )
        ch_bam           = FASTQ_ALIGN_BOWTIE2.out.bam
        ch_bam_index     = FASTQ_ALIGN_BOWTIE2.out.index
        ch_multiqc_files = ch_multiqc_files.mix( FASTQ_ALIGN_BOWTIE2.out.stats )
    } else {
        FASTQ_ALIGN_BWAMEM2 (
            ch_reads,
            ch_index,
            ch_fasta_fai,
            false
        )
        ch_bam           = FASTQ_ALIGN_BWAMEM2.out.bam
        ch_bam_index     = FASTQ_ALIGN_BWAMEM2.out.bai
        ch_multiqc_files = ch_multiqc_files.mix( FASTQ_ALIGN_BWAMEM2.out.stats )
    }

    freebayes_input = ch_bam  // channel: [ val(meta), path(bam) ]
        .join( ch_bam_index ) // channel: [ val(meta), path(bam), path(bam_index)]
            .map{
                meta, bam, bai -> [ meta, bam, bai, [], [], [] ]
            }

    BAM_VARIANT_CALLING_SORT_FREEBAYES_BCFTOOLS (freebayes_input,
                        ch_fasta_fai.first(),
                        [ [:], [] ],
                        [ [:], [] ],
                        [ [:], [] ]
    )

    ch_bcftool_filter_input = BAM_VARIANT_CALLING_SORT_FREEBAYES_BCFTOOLS.out.vcf
        .join(BAM_VARIANT_CALLING_SORT_FREEBAYES_BCFTOOLS.out.index)

    BCFTOOLS_FILTER ( ch_bcftool_filter_input )

    ch_bcftool_norm_input = BCFTOOLS_FILTER.out.vcf.join(BCFTOOLS_FILTER.out.index)
    BCFTOOLS_NORM ( ch_bcftool_norm_input, ch_fasta )

    ch_bcftool_stats_input = BCFTOOLS_NORM.out.vcf.join(BCFTOOLS_NORM.out.index)

    BCFTOOLS_STATS ( ch_bcftool_stats_input, [ [:], [] ], [ [:], [] ], [ [:], [] ], [ [:], [] ], [ [:], [] ] )
    ch_multiqc_files = ch_multiqc_files.mix( BCFTOOLS_STATS.out.stats )

    CONSENSUS_BCFTOOLS ( ch_bam, BCFTOOLS_NORM.out.vcf, BCFTOOLS_NORM.out.index, ch_fasta )

    SEQTK_COMP( CONSENSUS_BCFTOOLS.out.consensus )

    emit:
    bam         = ch_bam                           // channel: [ val(meta), [ bam ] ]
    bai         = ch_index                         // channel: [ val(meta), [ bai ] ]
    vcf         = BCFTOOLS_NORM.out.vcf            // channel: [meta, vcf]
    index       = BCFTOOLS_NORM.out.index          // channel: [ val(meta), path(index) ]
    stats       = BCFTOOLS_STATS.out.stats         // channel: [meta, stats]
    consensus   = CONSENSUS_BCFTOOLS.out.consensus // channel: [ val(meta), path(consensus) ]
    seqtk_stats = SEQTK_COMP.out.seqtk_stats       // channel: [meta, stats]
    mqc         = ch_multiqc_files                 // channel: [ val(meta), [ multiqc files ] ]
}
