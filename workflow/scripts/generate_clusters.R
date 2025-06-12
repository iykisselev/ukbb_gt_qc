#!/usr/bin/env Rscript

# Get input/output files from snakemake
fam_file <- snakemake@input[["fam"]]
batch_file <- snakemake@input[["batch_file"]]
output_file <- snakemake@output[[1]]

# Read the fam file
fam <- read.table(fam_file, header = FALSE)

# Read the batch file
batch_fam <- read.csv(batch_file, header = TRUE)

# Check for minimum required columns
if (ncol(fam) < 6) {
    stop("Fam file must contain at least 6 columns.")
}

# Merge fam and batch data
merged_data <- merge(
    fam,
    batch_fam,
    by.x = "V2",
    by.y = "eid",
    all.x = TRUE
)

# Select and reorder columns
result <- merged_data[, c("V1", "V2", "p22000")]

# Write output
write.table(
    result,
    output_file,
    sep = "\t",
    col.names = FALSE,
    row.names = FALSE,
    quote = FALSE
) 