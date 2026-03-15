args <- commandArgs(trailingOnly = TRUE)

if (length(args) < 3) {
  stop("Usage: Rscript fasta_qc.R <input_fasta> <output_dir> <label>", call. = FALSE)
}

input_fasta <- args[1]
output_dir <- args[2]
label <- args[3]

read_fasta_lengths <- function(path) {
  if (!file.exists(path)) {
    stop(sprintf("FASTA file not found: %s", path), call. = FALSE)
  }

  lines <- readLines(path, warn = FALSE)
  if (!length(lines)) {
    return(integer())
  }

  header_idx <- grep("^>", lines)
  if (!length(header_idx)) {
    return(integer())
  }

  sequence_lengths <- integer(length(header_idx))
  for (i in seq_along(header_idx)) {
    start_idx <- header_idx[i] + 1
    end_idx <- if (i < length(header_idx)) header_idx[i + 1] - 1 else length(lines)
    sequence_lines <- lines[start_idx:end_idx]
    sequence_lines <- sequence_lines[nzchar(sequence_lines)]
    sequence_lengths[i] <- nchar(paste(sequence_lines, collapse = ""))
  }

  sequence_lengths
}

dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

lengths <- read_fasta_lengths(input_fasta)
safe_label <- gsub("[^A-Za-z0-9._-]+", "_", label)
tsv_path <- file.path(output_dir, paste0(safe_label, ".contig_lengths.tsv"))
png_path <- file.path(output_dir, paste0(safe_label, ".contig_lengths.png"))
pdf_path <- file.path(output_dir, paste0(safe_label, ".contig_lengths.pdf"))

summary_df <- data.frame(
  label = label,
  sequence_count = length(lengths),
  min_length = if (length(lengths)) min(lengths) else NA_integer_,
  median_length = if (length(lengths)) median(lengths) else NA_real_,
  mean_length = if (length(lengths)) mean(lengths) else NA_real_,
  max_length = if (length(lengths)) max(lengths) else NA_integer_
)

write.table(summary_df, file = tsv_path, sep = "\t", quote = FALSE, row.names = FALSE)

plot_lengths <- function(device_fn, path) {
  if (identical(device_fn, png)) {
    device_fn(path, width = 9, height = 5, units = "in", res = 180)
  } else {
    device_fn(path, width = 9, height = 5)
  }

  par(mar = c(4.5, 4.5, 3, 1))

  if (length(lengths)) {
    hist(
      lengths,
      breaks = 30,
      col = "#8fad8d",
      border = "#35523c",
      main = paste("Contig length distribution:", label),
      xlab = "Contig length (nt)",
      ylab = "Count"
    )
    grid()
    mtext(sprintf("n=%s | median=%.1f | mean=%.1f", length(lengths), median(lengths), mean(lengths)))
  } else {
    plot.new()
    title(main = paste("Contig length distribution:", label))
    text(0.5, 0.5, "No sequences found in FASTA")
  }

  invisible(dev.off())
}

plot_lengths(png, png_path)
plot_lengths(pdf, pdf_path)
