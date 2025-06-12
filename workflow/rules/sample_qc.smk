rule find_outliers:
    """
    Identify sample outliers based on quality metrics.
    """
    input:
        config["samples"]["ukbb_qc"]
    output:
        temp("results/sample_qc/to_remove.txt")
    log:
        "logs/sample_qc/find_outliers.log"
    script: 
        "../scripts/filter_outliers.R"

rule filter_relatedness:
    """
    Filter samples based on relatedness information.
    """
    input:
        outlier_list = "results/sample_qc/to_remove.txt",
        rel_file = config["samples"]["kinship_info"],
        qc_file = config["samples"]["ukbb_qc"]
    output:
        temp("results/sample_qc/to_keep_unrelated.txt")
    log:
        "logs/sample_qc/filter_relatedness.log"
    script: 
        "../scripts/filter_relatedness.R"

rule filter_samples:
    """
    Remove excluded samples from the dataset.
    """
    input:
        genotypes = expand("results/variant_qc/gt.lifted.snv_filtered.{ext}", ext=FORMATS),
        to_keep = "results/sample_qc/to_keep_unrelated.txt"
    output:
        temp(expand("results/sample_qc/gt.lifted.snv_filtered.sample_filtered.{ext}", ext=FORMATS))
    log:
        "logs/sample_qc/filter_samples.log"
    params:
        plink = RESOURCES["plink"]
    shell:
        """
        {params.plink} --bfile results/variant_qc/gt.lifted.snv_filtered \
            --keep {input.to_keep} \
            --make-bed \
            --out results/sample_qc/gt.lifted.snv_filtered.sample_filtered \
            2> {log}
        """ 