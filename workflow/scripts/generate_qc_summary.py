#!/usr/bin/env python3

import sys
import pandas as pd
import numpy as np
from pathlib import Path

def count_samples(fam_file):
    """Count number of samples in a FAM file."""
    return sum(1 for _ in open(fam_file))

def count_variants(bim_file):
    """Count number of variants in a BIM file."""
    return sum(1 for _ in open(bim_file))

def count_variants_to_remove(variant_files):
    """Count number of variants in removal files."""
    total = 0
    for file in variant_files:
        if file.endswith('.bed'):
            # For BED files, count number of lines
            total += sum(1 for _ in open(file))
        else:
            # For text files, count number of lines
            total += sum(1 for _ in open(file))
    return total

def main():
    # Get input files
    initial_fam = snakemake.input.initial_gt[2]  # .fam file
    variant_filtered_fam = snakemake.input.variant_filtered_gt[2]
    sample_filtered_fam = snakemake.input.sample_filtered_gt[2]
    final_fam = snakemake.input.final_gt[2]
    
    initial_bim = snakemake.input.initial_gt[1]  # .bim file
    variant_filtered_bim = snakemake.input.variant_filtered_gt[1]
    sample_filtered_bim = snakemake.input.sample_filtered_gt[1]
    final_bim = snakemake.input.final_gt[1]
    
    # Count samples at each step
    initial_samples = count_samples(initial_fam)
    after_variant_qc_samples = count_samples(variant_filtered_fam)
    after_sample_qc_samples = count_samples(sample_filtered_fam)
    final_samples = count_samples(final_fam)
    
    # Count variants at each step
    initial_variants = count_variants(initial_bim)
    after_variant_qc_variants = count_variants(variant_filtered_bim)
    after_sample_qc_variants = count_variants(sample_filtered_bim)
    final_variants = count_variants(final_bim)
    
    # Count variants removed in variant QC
    variant_qc_removed = count_variants_to_remove([
        snakemake.input.indel_variants,
        snakemake.input.strand_mismatch_variants,
        snakemake.input.unmapped_variants
    ])
    
    # Count samples removed in sample QC
    sample_qc_removed = sum(1 for _ in open(snakemake.input.to_remove))
    
    # Generate summary
    summary = f"""QC Summary Statistics
===================

Initial QC:
- Initial samples: {initial_samples}
- Initial variants: {initial_variants}

Variant QC:
- Variants removed: {variant_qc_removed}
- Remaining variants: {after_variant_qc_variants}
- Remaining samples: {after_variant_qc_samples}

Sample QC:
- Samples removed: {sample_qc_removed}
- Remaining samples: {after_sample_qc_samples}
- Remaining variants: {after_sample_qc_variants}

Final QC (after HWE filter):
- Final samples: {final_samples}
- Final variants: {final_variants}

Total Removed:
- Samples: {initial_samples - final_samples} ({((initial_samples - final_samples) / initial_samples * 100):.2f}%)
- Variants: {initial_variants - final_variants} ({((initial_variants - final_variants) / initial_variants * 100):.2f}%)
"""
    
    # Write summary to output file
    with open(snakemake.output[0], 'w') as f:
        f.write(summary)

if __name__ == "__main__":
    main() 