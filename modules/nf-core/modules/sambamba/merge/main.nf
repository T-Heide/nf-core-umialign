process SAMBAMBA_MERGE {
    tag "$meta.id"
    label 'process_medium'

    conda (params.enable_conda ? "bioconda::sambamba=0.8.1" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/sambamba:0.8.1--hadffe2f_1' :
        'quay.io/biocontainers/sambamba:0.8.1--hadffe2f_1' }"

    input:
    tuple val(meta), path(bam)

    output:
    tuple val(meta), path("*merged.bam"), emit: bam
    path  "versions.yml"                , emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    if ("$bam" == "${prefix}.bam") error "Input and output names are the same, use \"task.ext.prefix\" to disambiguate!"
    """
    sambamba merge  \
        $bam \
        --tmpdir=./temp \
        --nthreads=${task.cpus}
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        sambamba: \$( echo \$(sambamba --version 2>&1 | sed 's/^.*sambamba //; s/ by.*//') 
    END_VERSIONS
    """
    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    if ("$bam" == "${prefix}.bam") error "Input and output names are the same, use \"task.ext.prefix\" to disambiguate!"
    """
    touch ${prefix}.merged.bam
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        sambamba: 0.8.1 
    END_VERSIONS
    """
}
