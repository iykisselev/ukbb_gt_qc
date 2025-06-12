rule find_indels_and_strand_mismatch:
    """
    Identify indels and strand mismatch variants for removal.
    """
    input: 
        "results/initial_qc/gt.initial_qc.bim"
    output:
        indel_variants = "results/variant_qc/indel_variants.txt",
        strand_mismatch_variants = "results/variant_qc/strand_mismatch_variants.txt"
    log:
        "logs/variant_qc/identify_variants.log"
    script: 
        "../scripts/identify_variants_to_remove.R"

rule convert_bim_to_bed:
    """
    Convert BIM file to BED format for liftover.
    """
    input: 
        "results/initial_qc/gt.initial_qc.bim"
    output: 
        temp("results/variant_qc/bim_to_bed.bed")
    log:
        "logs/variant_qc/convert_to_bed.log"
    shell:
        """
        awk 'OFS="\t" {{print "chr"$1, $4-1, $4, $2}}' {input} > {output} 2> {log}
        """    

rule convert_chr_names:
    """
    Convert chromosome names to standard format.
    """
    input: 
        "results/variant_qc/bim_to_bed.bed"
    output: 
        temp("results/variant_qc/chr_names_converted.bed")
    log:
        "logs/variant_qc/convert_chr_names.log"
    shell:
        """
        awk '{{
            if ($1 == "chr23") $1 = "chrX"
            else if ($1 == "chr24") $1 = "chrY"
            else if ($1 == "chr26") $1 = "chrM"
            print
            }}' {input} | \
            sed 's/ /\t/g' > {output} 2> {log}
        """

rule liftover_variants:
    """
    Perform liftover of variants to target genome build.
    """
    input: 
        bed = "results/variant_qc/chr_names_converted.bed",
        chain = config["chain"]
    output: 
        lifted_variants = "results/variant_qc/lifted_variants.bed",
        unmapped_variants = "results/variant_qc/unmapped_variants.bed"
    log:
        "logs/variant_qc/liftover.log"
    params:
        liftOver = RESOURCES["liftOver"]
    shell:
        """
        {params.liftOver} {input.bed} \
            {input.chain} \
            {output.lifted_variants} \
            {output.unmapped_variants} \
            2> {log}
        """

rule apply_variant_filters:
    """
    Apply variant-level quality filters including MAF, MAC, and missing rate.
    """
    input:
        genotypes = expand("results/initial_qc/gt.initial_qc.{ext}", ext=FORMATS),
        indel_variants = "results/variant_qc/indel_variants.txt",
        strand_mismatch_variants = "results/variant_qc/strand_mismatch_variants.txt",
        unmapped_variants = "results/variant_qc/unmapped_variants.bed"
    output:
        temp(expand("results/variant_qc/gt.lifted.snv_filtered.{ext}", ext=FORMATS))
    log:
        "logs/variant_qc/apply_filters.log"
    params:
        plink = RESOURCES["plink"],
        maf = PLINK_PARAMS["maf"],
        geno = PLINK_PARAMS["geno"]
    shell:
        """
        # Generate a list of variants to exclude
        cat {input.indel_variants} \
            {input.strand_mismatch_variants} \
            <(cut -f4 {input.unmapped_variants}) | \
            sort | \
            uniq > results/variant_qc/to_exclude.txt
        
        {params.plink} --bfile results/initial_qc/gt.initial_qc \
            --exclude results/variant_qc/to_exclude.txt \
            --chr 1-22 \
            --maf {params.maf} \
            --geno {params.geno} \
            --make-bed \
            --out results/variant_qc/gt.lifted.snv_filtered \
            2> {log}
        """ 