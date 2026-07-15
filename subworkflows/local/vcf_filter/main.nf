//
// Perform post-processing of VCF files
//

include { BCFTOOLS_VIEW as BCFTOOLS_VIEW_NON_ALT         } from '../../../modules/nf-core/bcftools/view/main'
include { BCFTOOLS_NORM                                  } from '../../../modules/nf-core/bcftools/norm/main'
include { BCFTOOLS_FILTER as BCFTOOLS_FILTER_LONG_INDELS } from '../../../modules/nf-core/bcftools/filter/main'
include { BCFTOOLS_PLUGINFILLTAGS                        } from '../../../modules/nf-core/bcftools/pluginfilltags/main'
include { BCFTOOLS_VIEW as BCFTOOLS_VIEW_POST_NORM       } from '../../../modules/nf-core/bcftools/view/main'
include { BCFTOOLS_SORT                                  } from '../../../modules/nf-core/bcftools/sort/main'
include { BCFTOOLS_FILTER as BCFTOOLS_FILTER_LOW_QUALITY } from '../../../modules/nf-core/bcftools/filter/main'
include { BCFTOOLS_FILTER as BCFTOOLS_FILTER_LOW_DEPTH   } from '../../../modules/nf-core/bcftools/filter/main'
include { BCFTOOLS_FILTER as BCFTOOLS_FILTER_MIXED_SITE  } from '../../../modules/nf-core/bcftools/filter/main'
include { BCFTOOLS_VIEW as BCFTOOLS_VIEW_FINAL       } from '../../../modules/nf-core/bcftools/view/main'

workflow VCF_FILTER {

    take:
    ch_vcf   // channel: [meta, vcf]
    ch_index // channel: [meta, vcf index]
    ch_fasta // channel: [meta, ref]

    main:
    // Combine vcf and index into a single channel for subworkflows that need both
    ch_vcf_index = ch_vcf.join( ch_index ) // channel: [ val(meta), path(vcf), path(index) ]

    // Remove non-ALT alleles from the VCF file before normalization
    BCFTOOLS_VIEW_NON_ALT ( ch_vcf_index, [], [], [] )

    // Normalize the VCF file using the reference genome
    ch_norm_input = BCFTOOLS_VIEW_NON_ALT.out.vcf.join(BCFTOOLS_VIEW_NON_ALT.out.index)
    BCFTOOLS_NORM ( ch_norm_input, ch_fasta )

    // Remove long indels and unobserved variants from the VCF file
    ch_filter_long_indels_input = BCFTOOLS_NORM.out.vcf.join(BCFTOOLS_NORM.out.index)
    BCFTOOLS_FILTER_LONG_INDELS ( ch_filter_long_indels_input )

    // Recompute TYPE from REF/ALT
    ch_pluginfilltags_input = BCFTOOLS_FILTER_LONG_INDELS.out.vcf.join(BCFTOOLS_FILTER_LONG_INDELS.out.index)
    BCFTOOLS_PLUGINFILLTAGS ( ch_pluginfilltags_input, [], [], [] )

    // Sort the VCF file
    BCFTOOLS_SORT ( BCFTOOLS_PLUGINFILLTAGS.out.vcf )

    // Filter the VCF file after normalization
    ch_post_norm_input = BCFTOOLS_SORT.out.vcf.join(BCFTOOLS_SORT.out.index)
    BCFTOOLS_VIEW_POST_NORM ( ch_post_norm_input, [], [], [] )

    // Filter the VCF file for low quality variants
    ch_low_quality_input = BCFTOOLS_VIEW_POST_NORM.out.vcf.join(BCFTOOLS_VIEW_POST_NORM.out.index)
    BCFTOOLS_FILTER_LOW_QUALITY ( ch_low_quality_input )

    // Filter the VCF file for low depth variants
    ch_low_depth_input = BCFTOOLS_FILTER_LOW_QUALITY.out.vcf.join(BCFTOOLS_FILTER_LOW_QUALITY.out.index)
    BCFTOOLS_FILTER_LOW_DEPTH ( ch_low_depth_input )

    // Filter the VCF file for mixed site variants
    ch_mixed_site_input = BCFTOOLS_FILTER_LOW_DEPTH.out.vcf.join(BCFTOOLS_FILTER_LOW_DEPTH.out.index)
    BCFTOOLS_FILTER_MIXED_SITE ( ch_mixed_site_input )

    // Create final VCF file
    ch_final_input = BCFTOOLS_FILTER_MIXED_SITE.out.vcf.join(BCFTOOLS_FILTER_MIXED_SITE.out.index)
    BCFTOOLS_VIEW_FINAL ( ch_final_input, [], [], [] )

    emit:
    vcf     = BCFTOOLS_VIEW_FINAL.out.vcf             // channel: [meta, vcf]
    index   = BCFTOOLS_VIEW_FINAL.out.index           // channel: [ val(meta), path(index) ]
}
