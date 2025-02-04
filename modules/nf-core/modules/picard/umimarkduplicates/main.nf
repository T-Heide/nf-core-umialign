process PICARD_UMIMARKDUPLICATES {
    tag "$meta.id"
    label 'process_medium'

    conda (params.enable_conda ? "bioconda::picard=2.26.10" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/picard:2.26.10--hdfd78af_0' :
        'quay.io/biocontainers/picard:2.26.10--hdfd78af_0' }"

    input:
    tuple val(meta), path(bam)

    output:
    tuple val(meta), path("*umi_aware_md.bam")        , emit: bam
    tuple val(meta), path("*.bai")                    , optional:true, emit: bai
    tuple val(meta), path("*umi.metrics")             , emit: umi_metrics
    tuple val(meta), path("*duplicate.metrics")       , emit: md_metrics
    path  "versions.yml"                              , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def avail_mem = 3
    if (!task.memory) {
        log.info '[Picard MarkDuplicates] Available memory not known - defaulting to 3GB. Specify process memory requirements to change this.'
    } else {
        avail_mem = task.memory.giga
    }
    """
    [ ! -d "./tmpdir" ] && mkdir ./tmpdir || echo "./tmpdir exists"

    picard \\
        -Xmx${avail_mem}g \\
        UmiAwareMarkDuplicatesWithMateCigar \\
        TMP_DIR=./tmpdir \\
        INPUT=$bam \\
        $args \\
        OUTPUT=${prefix}_umi_aware_md.bam \\
        ASSUME_SORT_ORDER=coordinate \\
        METRICS_FILE=${prefix}_duplicate.metrics \\
        UMI_METRICS_FILE=${prefix}_umi.metrics \\
        CREATE_INDEX=true

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        picard: \$(echo \$(picard UmiAwareMarkDuplicatesWithMateCigar --version 2>&1) | grep -o 'Version:.*' | cut -f2- -d:)
    END_VERSIONS
    """
    stub:
        def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def avail_mem = 3
    if (!task.memory) {
        log.info '[Picard MarkDuplicates] Available memory not known - defaulting to 3GB. Specify process memory requirements to change this.'
    } else {
        avail_mem = task.memory.giga
    }
    """
    touch ${prefix}_umi_aware_md.bam
    touch ${prefix}_umi_aware_md.bai
    touch ${prefix}_duplicate.metrics
    touch ${prefix}_umi.metrics
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        picard: 2.26.10 
    END_VERSIONS
    """

}
