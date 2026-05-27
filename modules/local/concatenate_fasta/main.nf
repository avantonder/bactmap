process CONCATENATE_FASTA {
    tag "$meta.id"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
        ? 'https://depot.galaxyproject.org/singularity/biopython:1.78'
        : 'quay.io/biocontainers/biopython:1.78' }"

    input:
    tuple val(meta), path(fasta)

    output:
    tuple val(meta), path("*.fa"), emit: fasta
    tuple val("${task.process}"), val('python'), eval("python --version | sed 's/Python //g'"), topic: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    multi2single_sequence.py -r ${fasta} -o ${prefix}.fa
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.fa
    """
}
