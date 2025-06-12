#!/usr/bin/env Rscript

# Script to identify problematic variants in genotype data.
# Identifies:
# - Indels (insertions/deletions)
# - Potential strand mismatches (A/T or G/C pairs)
suppressPackageStartupMessages({
library(logging)
library(dplyr)
})

# Setup logging
basicConfig(level = 'INFO')
addHandler(writeToFile, file = snakemake@log[[1]], level = 'INFO')

is_indel <- function(ref, alt) {
  nchar(ref) != nchar(alt)
}

is_strand_mismatch <- function(ref, alt) {
  # Check for A/T or G/C pairs
  (ref == "A" & alt == "T") | (ref == "T" & alt == "A") |
  (ref == "G" & alt == "C") | (ref == "C" & alt == "G")
}

read_bim_file <- function(file_path) {
  tryCatch({
    loginfo("Reading BIM file: %s", file_path)
    bim <- read.table(file_path, header = FALSE, col.names = c("chrom", "variant_id", "cm", "pos", "ref", "alt"))
    loginfo("Successfully read %d variants", nrow(bim))
    return(bim)
  }, error = function(e) {
    logerror("Failed to read BIM file: %s", e$message)
    stop(e)
  })
}

write_variants <- function(variants, output_file) {
  tryCatch({
    loginfo("Writing %d variants to %s", length(variants), output_file)
    write.table(variants, output_file, row.names = FALSE, col.names = FALSE, quote = FALSE, sep = "\t")
    loginfo("Successfully wrote variants")
  }, error = function(e) {
    logerror("Failed to write variants: %s", e$message)
    stop(e)
  })
}

main <- function() {
  # Get input/output files from snakemake
  input_file <- snakemake@input[[1]]
  indel_output <- snakemake@output$indel_variants
  strand_mismatch_output <- snakemake@output$strand_mismatch_variants

  tryCatch({
    # Read BIM file
    bim <- read_bim_file(input_file)

    # Identify indels
    loginfo("Identifying indels")
    indel_variants <- bim |>
      filter(is_indel(ref, alt)) |>
      pull(variant_id)
    loginfo("Found %d indels", length(indel_variants))

    # Identify potential strand mismatches
    loginfo("Identifying potential strand mismatches")
    strand_mismatch_variants <- bim |>
      filter(is_strand_mismatch(ref, alt)) |>
      pull(variant_id)
    loginfo("Found %d potential strand mismatches", length(strand_mismatch_variants))

    # Write results
    write_variants(indel_variants, indel_output)
    write_variants(strand_mismatch_variants, strand_mismatch_output)

  }, error = function(e) {
    logerror("Script failed: %s", e$message)
    stop(e)
  })
}

# Run main function
main() 