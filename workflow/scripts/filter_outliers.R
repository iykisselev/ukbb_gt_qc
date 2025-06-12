#!/usr/bin/env Rscript

# Script to identify and filter out problematic samples based on quality metrics
# Filters out:
# - Non-Caucasian samples
# - Sex-mismatched samples
# - Samples with heterozygosity-missingness issues

# Load required packages
suppressPackageStartupMessages({
    library(logging)
    library(dplyr)
})

# Setup logging
logging::basicConfig(level = "INFO")
logger <- logging::getLogger()

# Get input/output files from snakemake
qc_file <- snakemake@input[[1]]
output_file <- snakemake@output[[1]]
log_file <- snakemake@log[[1]]

# Setup file logging
logging::addHandler(logging::writeToFile, file = log_file)

# Read input file
logger$info("Reading QC file: %s", qc_file)
qc <- tryCatch({
    read.csv(qc_file)
}, error = function(e) {
    logger$error("Failed to read QC file: %s", e$message)
    stop(e)
})

# Log initial sample count
logger$info("Processing %d samples", nrow(qc))

# Identify problematic samples
to_exclude <- qc |>
    filter(p22006 != "Caucasian" | 
           p22001 != p31 | 
           p22027 == "Yes") |>
    pull(eid) |>
    unique()

# Log filtering results
logger$info("Identified %d samples to exclude", length(to_exclude))
logger$info("Breakdown of exclusions:")
logger$info("- Non-Caucasian: %d", sum(qc$p22006 != "Caucasian"))
logger$info("- Sex-mismatched: %d", sum(qc$p22001 != qc$p31))
logger$info("- Heterozygosity-missingness issues: %d", sum(qc$p22027 == "Yes"))

# Write results
write.table(to_exclude, output_file,
            row.names = FALSE, col.names = FALSE, 
            quote = FALSE, sep = "\t")