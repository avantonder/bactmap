process BCFTOOLS_CONSENSUS {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
        ? 'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/0b/0b4d52ca9a56d07be3f78a12af654e5116f5112908dba277e6796fd9dfb83fe5/data'
        : 'community.wave.seqera.io/library/bcftools_htslib:1.23.1--9f08ec665533d64a'}"

    input:
    tuple val(meta), path(vcf), path(tbi), path(mask)
    tuple val(ref_meta), path(fasta)

    output:
    tuple val(meta), path('*.fa'), emit: fasta
    tuple val("${task.process}"), val('bcftools'), eval("bcftools --version | sed '1!d; s/^.*bcftools //'"), topic: versions, emit: versions_bcftools

    when:
    task.ext.when == null || task.ext.when

    /*
    * nf-core bcftools consensus does not have an option to output only SNPs, but for our purposes
    * we only want to use the SNPs to create the consensus sequence. therefore we first filter the
    * VCF to keep only the SNPs, and then we create the consensus sequence using bcftools consensus.
    * We also added an option to mask low coverage regions with N.
    */

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def masking = mask ? "-m $mask" : ""
    """
    bcftools view -v snps $vcf -Oz -o ${prefix}.snps.vcf.gz

    bcftools index ${prefix}.snps.vcf.gz

    cat ${fasta} \\
        | bcftools \\
            consensus \\
            ${prefix}.snps.vcf.gz \\
            ${args} \\
            ${masking} \\
            --mask-with "N" \\
            > ${prefix}.fa
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.fa
    """
}
