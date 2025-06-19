#!/usr/bin/env Rscript

# Load required packages
suppressPackageStartupMessages({
    library(igraph)
    library(logging)
})

# Setup logging
basicConfig(level = 'INFO')
addHandler(writeToFile, file = snakemake@log[[1]], level = 'INFO')
loginfo("Starting relatedness filtering")

# Get input/output files from snakemake
qc_file <- snakemake@input[["qc_file"]]
rel_file <- snakemake@input[["rel_file"]]
outlier_list <- snakemake@input[["outlier_list"]]
output_file <- snakemake@output[[1]]

loginfo("Reading input files")
# Read input files
qc <- read.csv(qc_file)
outliers <- read.table(outlier_list)
rel <- read.csv(rel_file)

# Remove outliers
loginfo("Removed %d outliers", sum(qc$eid %in% outliers$V1))
qc <- qc[!qc$eid %in% outliers$V1, ]

# Identify groups (unrelated, to prune)
unrelated_eid <- qc$eid[qc$p22021 == "No kinship found"]
to_prune <- qc$eid[qc$p22021 == "At least one relative identified"]
loginfo("Found %d unrelated samples and %d samples to prune", 
        length(unrelated_eid), length(to_prune))

# Prepare missingness data
df_miss <- data.frame(
    id = as.character(qc$eid),
    missingness = qc$p22005
)

# Build Pairwise Relationships
pair_df <- rel[rel$eid %in% to_prune, ]
pair_cols <- grep("^p22011", colnames(pair_df), value = TRUE)

# Reshape pair data
pair_df_long <- do.call(rbind, lapply(pair_cols, function(col) {
    data.frame(
        eid = pair_df$eid,
        pair_id = pair_df[[col]]
        )
}))

# Identify insufficiently related samples
na_counts <- tapply(pair_df_long$pair_id, pair_df_long$eid, function(x) sum(is.na(x)))
insufficiently_related <- names(na_counts)[na_counts == length(pair_cols)]
loginfo("Found %d insufficiently related samples", length(insufficiently_related))

# Filter out NA pairs
pair_df_long <- pair_df_long[!is.na(pair_df_long$pair_id), ]

# Construct Edge List
pair_counts <- table(pair_df_long$pair_id)
valid_pairs <- names(pair_counts)[pair_counts == 2]

edge_list <- do.call(rbind, lapply(valid_pairs, function(pid) {
    pair <- pair_df_long$eid[pair_df_long$pair_id == pid]
    data.frame(
        from = pair[1],
        to = pair[2])
}))

# If no edges, write out unrelated + insufficiently related
if (nrow(edge_list) == 0) {
    loginfo("No valid edges found, writing out unrelated and insufficiently related samples")
    lower_missingness_id <- sort(c(unrelated_eid, insufficiently_related))
    
    write.table(
        data.frame(lower_missingness_id, lower_missingness_id),
        file = output_file,
        sep = "\t",
        col.names = FALSE,
        row.names = FALSE,
        quote = FALSE
    )
    loginfo("Successfully wrote %d samples to output file", length(lower_missingness_id))
    quit(status = 0)
}

# Create graph
rel_graph <- igraph::graph_from_data_frame(edge_list, directed = FALSE)
all_subgraphs <- igraph::decompose(rel_graph)

# Split into small and big graphs
graph_sizes <- sapply(all_subgraphs, igraph::vcount)
small_graphs <- all_subgraphs[graph_sizes == 2]
big_graphs <- all_subgraphs[graph_sizes > 2]

# Process small graphs (2-vertex)
n_small_graphs <- length(small_graphs)
lower_missingness_id <- character(n_small_graphs)
missingness_vec <- setNames(df_miss$missingness, df_miss$id)

# Process all small graphs at once
vertex_ids_list <- lapply(small_graphs, function(sg) igraph::V(sg)$name)
vertex_miss_list <- lapply(vertex_ids_list, function(ids) missingness_vec[ids])
min_miss_idx <- sapply(vertex_miss_list, function(miss) which.min(miss))
lower_missingness_id <- mapply(function(ids, idx) ids[idx], vertex_ids_list, min_miss_idx)

# Helper function for big graphs
select_best_sublist <- function(ivs_list, df_miss) {
    if (length(ivs_list) == 0) return(NULL)
    
    # Filter out empty
    non_empty_idx <- sapply(ivs_list, length) > 0
    ivs_list <- ivs_list[non_empty_idx]
    if (length(ivs_list) == 0) return(NULL)
    
    # Get sizes
    sublist_sizes <- sapply(ivs_list, length)
    if (all(is.na(sublist_sizes))) return(NULL)
    
    # Find largest
    max_size <- max(sublist_sizes, na.rm = TRUE)
    candidates_idx <- which(sublist_sizes == max_size)
    if (length(candidates_idx) == 0) return(NULL)
    
    # If one candidate, return it
    if (length(candidates_idx) == 1) {
        return(unlist(sapply(ivs_list[candidates_idx], names)))
    }
    
    # Tie-break by missingness
    candidate_avg_miss <- sapply(candidates_idx, function(i) {
        v_names <- names(ivs_list[[i]])
        idx_miss <- match(v_names, df_miss$id)
        mean(df_miss$missingness[idx_miss], na.rm = TRUE)
    })
    
    best_idx <- if (all(is.na(candidate_avg_miss))) {
        candidates_idx[1]
    } else {
        candidates_idx[which.min(candidate_avg_miss)]
    }
    
    if (length(best_idx) == 0) return(NULL)
    return(unlist(sapply(ivs_list[best_idx], names)))
}

# Process big graphs
big_result <- lapply(big_graphs, function(g) {
    candidate_ivs <- igraph::largest_ivs(g)
    select_best_sublist(candidate_ivs, df_miss)
})

# Combine all results
lower_missingness_id <- sort(unique(c(
    lower_missingness_id,
    unlist(big_result),
    unrelated_eid,
    insufficiently_related
)))
loginfo("Final selection includes %d samples", length(lower_missingness_id))

# Write results
write.table(
    data.frame(lower_missingness_id, lower_missingness_id),
    file = output_file,
    sep = "\t",
    col.names = FALSE,
    row.names = FALSE,
    quote = FALSE
)
loginfo("Successfully wrote results to %s", output_file)
