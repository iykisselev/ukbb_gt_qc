# UK Biobank Genotype QC Workflow

This workflow performs quality control on UK Biobank genotype data, including variant and sample filtering, liftover, and relatedness analysis.

## Overview

The workflow performs the following steps:
1. Initial QC
   - Set genotypes that failed UKBB batch QC to missing
2. Variant QC
   - Identify and remove indels
   - Identify potential strand mismatches
   - Perform genome build liftover
   - Apply variant-level filters (MAF, MAC, missingness rate)
3. Sample QC
   - Identify and remove outliers based on ancestry, missingness and heterozygosity
   - Filter related samples
4. Final QC
   - Apply Hardy-Weinberg equilibrium filter

## Requirements

- Python 3.9+
- R 4.0+
- PLINK 1.9+
- liftOver

## Input Files

### Marker QC File
This file contains quality control and genotyping information ([UK Biobank Resource 1955](https://biobank.ndph.ox.ac.uk/ukb/ukb/auxdata/ukb_snp_qc.txt)) 

### Sample QC File (`ukbb_sample_qc.csv`)
This file should contain the UK Biobank's quality control metrics for each sample. Required columns:
- `eid`: Sample ID
- `p22001`: Genetic sex
- `p31`: Reported sex
- `p22006`: Genetic ancestry
- `p22005`: Sample missingness rate
- `p22027`: Heterozygosity-missingness status ("Yes" indicates outliers)
- `p22021`: Relatedness status

### Kinship Information File (`kinship_info.csv`)
This should contain relatedness information from UK Biobank. Required columns:
- `eid`: Sample ID
- `p22011_*`: Columns containing IDs of pairs formed by related samples

### Genotype Files
- `.bed`: Binary genotype file
- `.bim`: Variant information file (chromosome, variant ID, genetic position, genomic position, allele 1, allele 2)
- `.fam`: Sample information file (family ID, sample ID, within-family ID of father, within-family ID of mother, sex, phenotype)

### Chain File
- UCSC chain file for genome build conversion (e.g., hg19ToHg38.over.chain)

## Installation

1. Clone the repository:
```bash
git clone https://github.com/iykisselev/ukbb_gt_qc
cd ukbb_gt_qc
```

2. Make the run script executable:
```bash
chmod +x run_local.sh
```

## Configuration

1. Modify the `config.yaml` file in the workflow directory by supplying paths to plink and liftOver executables, genotype and QC files, and specifying filtering criteria (MAF, missingness rate, HWE threshold).
2. Generate a machine-specific `config.yaml` file in the profiles directory or use the provided config file for execution.

## Usage

1. Run the workflow:
```bash
./run_local.sh
```

2. To run with a specific number of cores:
```bash
./run_local.sh --cores 8
```

## Output

The workflow generates the following outputs in the `results` directory:

```
results/
├── initial_qc/
│   └── gt.initial_qc.log
├── variant_qc/
│   ├── indel_variants.txt
│   ├── strand_mismatch_variants.txt
│   ├── to_exclude.txt
│   ├── lifted_variants.bed
│   ├── unmapped_variants.bed
│   └── gt.lifted.snv_filtered.log
├── sample_qc/
│   └── gt.lifted.snv_filtered.sample_filtered.log
└── final_qc/
    ├── qc_summary.txt
    └── final_genotypes.{bed,bim,fam,log}
```

Execution log files are stored in the `logs` directory, organized by QC stage.

## License

This project is licensed under the MIT License
