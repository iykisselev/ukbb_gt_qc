#!/usr/bin/env Rscript

# Get input/output files from snakemake
input_file <- snakemake@input[["qc_file"]]
output_file <- snakemake@output[[1]]

# Read QC data
qc_df <- read.table(input_file, header = TRUE, stringsAsFactors = FALSE)

# Find columns ending with 'qc'
qc_columns <- grep("qc$", colnames(qc_df), value = TRUE)
if (length(qc_columns) == 0) {
    stop("No columns ending with 'qc' found in the QC data.")
}

# Create long format data
result <- data.frame()
for (col in qc_columns) {
    batch_name <- sub("_qc$", "", col)
    temp_df <- data.frame(
        rs_id = qc_df$rs_id,
        batch = batch_name,
        failed = qc_df[[col]]
    )
    result <- rbind(result, temp_df)
}

# Filter and select columns
result <- result[result$failed != 1, c("rs_id", "batch")]

# Write output
write.table(
    result,
    output_file,
    sep = "\t",
    col.names = FALSE,
    row.names = FALSE,
    quote = FALSE
) 