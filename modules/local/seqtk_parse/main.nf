process SEQTK_PARSE {
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
        ? 'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/c0/c03d8fbb44376692e10bb9e56be2577fc35446c193637735de9fed182e6b58df/data'
        : 'community.wave.seqera.io/library/pandas:2.3.1--139e2fa6c1f18206' }"

    input:
    path tsv

    output:
    path "mapping_summary.tsv", emit: tsv
    tuple val("${task.process}"), val('python'), eval("python --version | sed 's/Python //g'"), topic: versions

    when:
    task.ext.when == null || task.ext.when

    script: // This script is bundled with the pipeline in nf-core/bactmap/bin/
    """
    seqtk_parser.py
    """

    stub:
    """
    touch mapping_summary.tsv
    """
}
