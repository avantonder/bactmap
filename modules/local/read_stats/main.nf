process READ_STATS {
    label 'process_low'
    tag "$meta.id"

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
        ? 'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/c0/c03d8fbb44376692e10bb9e56be2577fc35446c193637735de9fed182e6b58df/data'
        : 'community.wave.seqera.io/library/pandas:2.3.1--139e2fa6c1f18206' }"

    input:
    tuple val(meta), path(pre_json), path(post_json)

    output:
    tuple val(meta), path("*.read_stats.csv"), emit: csv
    tuple val("${task.process}"), val('python'), eval("python --version | sed 's/Python //g'"), topic: versions

    script: // This script is bundled with the pipeline in nf-core/bactmap/bin/
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    read_stats.py
    mv read_stats.csv ${prefix}.read_stats.csv
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.read_stats.csv
    """
}
