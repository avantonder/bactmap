include { FREEBAYES                                  } from '../../../modules/nf-core/freebayes/main'
include { BCFTOOLS_INDEX as BCFTOOLS_INDEX_SHORTREAD } from '../../../modules/nf-core/bcftools/index/main'


workflow BAM_VARIANT_CALLING_SORT_FREEBAYES_BCFTOOLS {

    take:
    ch_input        // channel: [mandatory] [ val(meta), path(input1), path(index1), path(input2), path(index2), path(bed) ]
    ch_fasta_fai    // channel: [mandatory] [ val(meta2), path(fasta), path(fai) ]
    ch_samples      // channel: [optional]  [ path(samples) ]
    ch_populations  // channel: [optional]  [ path(populations ]
    ch_cnv          // channel: [optional]  [ path(cnv) ]

    main:

    // Variant calling
    FREEBAYES ( ch_input, ch_fasta_fai.map{ meta, fasta, fai -> [ meta, fasta ] }, ch_fasta_fai.map{ meta, fasta, fai -> [ meta, fai ] }, ch_samples, ch_populations, ch_cnv )

    // Index VCF files
    BCFTOOLS_INDEX_SHORTREAD ( FREEBAYES.out.vcf )

    emit:
    vcf      = FREEBAYES.out.vcf                  // channel: [ val(meta), path(vcf) ]
    index    = BCFTOOLS_INDEX_SHORTREAD.out.index // channel: [ val(meta), path(index) ]
}
