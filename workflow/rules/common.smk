# Common resources and parameters
RESOURCES = {
    "plink": config["tools"]["plink"],
    "liftOver": config["tools"]["liftOver"]
}

FORMATS = ["bed", "bim", "fam", "nosex"]

# Common parameters for PLINK
PLINK_PARAMS = {
    "maf": config["variant_qc"]["maf_threshold"],
    "geno": config["variant_qc"]["missing_rate_threshold"],
    "hwe": config["variant_qc"]["hwe_threshold"]
} 