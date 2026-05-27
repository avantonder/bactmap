process ALIGNPSEUDOGENOMES {
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
        ? 'https://depot.galaxyproject.org/singularity/biopython:1.78'
        : 'quay.io/biocontainers/biopython:1.78' }"

    input:
    path pseudogenomes
    tuple val(ref_meta), path(fasta)

    output:
    path("aligned_pseudogenomes.fas"), emit: aligned_pseudogenomes
    path "low_quality_pseudogenomes.tsv", emit: low_quality_metrics
    tuple val("${task.process}"), val('python'), eval("python --version | sed 's/Python //g'"), topic: versions

    script: // This script is bundled with the pipeline, in nf-core/bactmap/bin/
    """
    touch low_quality_pseudogenomes.tsv
    touch aligned_pseudogenomes.fas
    for pseudogenome in ${pseudogenomes}
    do
        fraction_non_GATC_bases=\$(calculate_fraction_of_non_GATC_bases.py -f \$pseudogenome | tr -d '\\n')
        if awk 'BEGIN { exit !(\$fraction_non_GATC_bases < ${params.non_GATC_threshold}) }'; then
            cat \$pseudogenome >> aligned_pseudogenomes.fas
        else
            echo "\$pseudogenome\t\$fraction_non_GATC_bases" >> low_quality_pseudogenomes.tsv
        fi
    done
    multi2single_sequence.py -r ${fasta} -o final_reference.fas
    cat final_reference.fas >> aligned_pseudogenomes.fas
    """

    stub:
    """
    touch aligned_pseudogenomes.fas
    """
}
