rule generate_zero_cluster:
    """
    Generate zero cluster file for initial QC.
    """
    input:
        qc_file = config["gt"]["ukbb_qc"]
    output: 
        temp("results/initial_qc/zero_cluster.clst")
    log:
        "logs/initial_qc/zero_cluster.log"
    script: 
        "../scripts/generate_zero_cluster.R"

rule generate_clusters:
    """
    Generate cluster assignments for samples.
    """
    input:
        fam = config["gt"]["fam"],
        batch_file = config["samples"]["ukbb_qc"]
    output: 
        temp("results/initial_qc/clusters.clst")
    log:
        "logs/initial_qc/clusters.log"
    script: 
        "../scripts/generate_clusters.R"

rule set_failed_gt_missing:
    """
    Set failed genotypes to missing based on zero clusters and sample clusters.
    """
    input:
        genotypes = config["gt"]["bed"],
        zero_cluster = "results/initial_qc/zero_cluster.clst",
        clusters = "results/initial_qc/clusters.clst"
    output:
        temp(expand("results/initial_qc/gt.initial_qc.{ext}", ext=FORMATS))
    log:
        "logs/initial_qc/set_failed_gt_missing.log"
    params:
        bfile_in = lambda wildcards, input, output: input.genotypes.replace(".bed", ""),
        plink = RESOURCES["plink"]
    shell:
        """
        {params.plink} --bfile {params.bfile_in} \
            --zero-cluster {input.zero_cluster} \
            --within {input.clusters} \
            --make-bed \
            --out results/initial_qc/gt.initial_qc \
            2> {log}
        """ 