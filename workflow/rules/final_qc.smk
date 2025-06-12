rule apply_hwe_filter:
    """
    Apply Hardy-Weinberg equilibrium filter to variants.
    """
    input: 
        expand("results/sample_qc/gt.lifted.snv_filtered.sample_filtered.{ext}", ext=FORMATS)
    output:
        expand("results/final_qc/final_genotypes.{ext}", ext=FORMATS)
    log:
        "logs/final_qc/hwe_filter.log"
    params:
        hwe = PLINK_PARAMS["hwe"],
        plink = RESOURCES["plink"]
    shell:
        """
        {params.plink} --bfile results/sample_qc/gt.lifted.snv_filtered.sample_filtered \
            --hwe {params.hwe} \
            --make-bed \
            --out results/final_qc/final_genotypes \
            2> {log}
        """ 

rule generate_qc_summary:
    """
    Generate a summary of samples and variants removed at each QC step.
    """
    input:
        initial_gt = expand("results/initial_qc/gt.initial_qc.{ext}", ext=FORMATS),
        variant_filtered_gt = expand("results/variant_qc/gt.lifted.snv_filtered.{ext}", ext=FORMATS),
        sample_filtered_gt = expand("results/sample_qc/gt.lifted.snv_filtered.sample_filtered.{ext}", ext=FORMATS),
        final_gt = expand("results/final_qc/final_genotypes.{ext}", ext=FORMATS),
        to_remove = "results/sample_qc/to_keep_unrelated.txt",
        indel_variants = "results/variant_qc/indel_variants.txt",
        strand_mismatch_variants = "results/variant_qc/strand_mismatch_variants.txt",
        unmapped_variants = "results/variant_qc/unmapped_variants.bed"
    output:
        "results/final_qc/qc_summary.txt"
    log:
        "logs/final_qc/generate_summary.log"
    script:
        "../scripts/generate_qc_summary.py" 