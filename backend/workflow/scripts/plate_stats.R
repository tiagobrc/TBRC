args <- commandArgs(trailingOnly = TRUE)

if (length(args) < 2) {
  stop("Usage: Rscript plate_stats.R <input_prefix> <output_dir>", call. = FALSE)
}

suppressPackageStartupMessages({
  library(dplyr)
  library(ggplot2)
})

has_ggplate <- requireNamespace("ggplate", quietly = TRUE)
has_platetools <- requireNamespace("platetools", quietly = TRUE)

input_prefix <- args[1]
output_dir <- args[2]
counts_file <- paste0(input_prefix, "BC.stats.txt")
quality_file <- paste0(input_prefix, "collapsed.stats.txt")

if (!file.exists(counts_file) || !file.exists(quality_file)) {
  stop("Plate QC inputs not found. Expected BC.stats.txt and collapsed.stats.txt.", call. = FALSE)
}

dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

plate_levels <- sprintf("plate_%s", 1:12)
complete_wells <- if (has_platetools) {
  rep(platetools::num_to_well(1:96), 12)
} else {
  well_rows <- rep(LETTERS[1:8], each = 12)
  well_cols <- rep(1:12, times = 8)
  rep(paste0(well_rows, well_cols), 12)
}
complete_plate_id <- rep(plate_levels, each = 96)
plate_layout <- data.frame(
  plate_id = complete_plate_id,
  well = complete_wells,
  plate_well_id = paste0(complete_plate_id, "_", complete_wells),
  stringsAsFactors = FALSE
)

parse_count_table <- function(path) {
  df_counts <- read.table(path, sep = "\t", header = FALSE, stringsAsFactors = FALSE)
  colnames(df_counts) <- c("barcode", "count", "wells")

  df_counts$well_token <- gsub("^results.*(P[0-9]{2}[A-Za-z]{1,10}[0-9]{0,2})\\..*fasta", "\\1", df_counts$wells)
  df_counts$plate_id <- gsub("P([0-9]{1,2}).*", "plate_\\1", gsub("P0", "P", df_counts$well_token))
  df_counts$well <- gsub("P[0-9]{1,2}", "", df_counts$well_token)
  df_counts$plate_well_id <- paste0(df_counts$plate_id, "_", df_counts$well)

  df_counts
}

parse_quality_table <- function(path) {
  df_quality <- read.table(path, fill = TRUE, sep = "\t", header = TRUE, stringsAsFactors = FALSE)
  colnames(df_quality) <- gsub("^.*P[0]{0,1}([0-9]{1,2})([A-Z][0-9]{1,2})", "plate_\\1_\\2", colnames(df_quality))

  df_quality_pct <- apply(df_quality, MARGIN = 2, FUN = function(x) {
    sum(x[1:3], na.rm = TRUE) / sum(x, na.rm = TRUE)
  })

  data.frame(
    score = as.numeric(df_quality_pct),
    plate_id = gsub("_[A-Z].*", "", names(df_quality_pct)),
    well = gsub("^.*_", "", names(df_quality_pct)),
    plate_well_id = paste0(gsub("_[A-Z].*", "", names(df_quality_pct)), "_", gsub("^.*_", "", names(df_quality_pct))),
    stringsAsFactors = FALSE
  )
}

demux_counts <- parse_count_table(counts_file)
quality_scores <- parse_quality_table(quality_file)

demux_unmatched <- demux_counts[grep("unmatched", demux_counts$well, ignore.case = TRUE), c("barcode", "count", "well_token")]
demux_plates <- left_join(plate_layout, demux_counts[, c("count", "plate_well_id")], by = "plate_well_id")
quality_plates <- left_join(plate_layout, quality_scores[, c("score", "plate_well_id")], by = "plate_well_id")

demux_plates$plate_id <- factor(demux_plates$plate_id, levels = plate_levels)
quality_plates$plate_id <- factor(quality_plates$plate_id, levels = plate_levels)

write.table(demux_plates, file = file.path(output_dir, "plate_demultiplexed.tsv"), sep = "\t", quote = FALSE, row.names = FALSE)
write.table(quality_plates, file = file.path(output_dir, "plate_quality.tsv"), sep = "\t", quote = FALSE, row.names = FALSE)
write.table(demux_unmatched, file = file.path(output_dir, "plate_unmatched.tsv"), sep = "\t", quote = FALSE, row.names = FALSE)

plot_plate_series <- function(data, value_col, label_col = NULL, title_prefix, file_prefix, colour_scale) {
  pdf(file.path(output_dir, paste0(file_prefix, ".pdf")), width = 8.5, height = 6.5)

  for (current_plate in plate_levels) {
    plate_data <- data[data$plate_id == current_plate, , drop = FALSE]

    if (has_ggplate) {
      if (is.null(label_col)) {
        plate_plot <- ggplate::plate_plot(
          data = plate_data,
          position = well,
          value = !!rlang::sym(value_col),
          plate_size = 96,
          plate_type = "round",
          colour = colour_scale,
          title = paste(title_prefix, current_plate),
          show_legend = TRUE,
          silent = TRUE
        )
      } else {
        plate_plot <- ggplate::plate_plot(
          data = plate_data,
          position = well,
          value = !!rlang::sym(value_col),
          label = !!rlang::sym(label_col),
          plate_size = 96,
          plate_type = "round",
          colour = colour_scale,
          title = paste(title_prefix, current_plate),
          show_legend = TRUE,
          silent = TRUE
        )
      }
      print(plate_plot)
      ggsave(
        filename = file.path(output_dir, paste0(file_prefix, ".", current_plate, ".png")),
        plot = plate_plot,
        width = 8.5,
        height = 6.5,
        dpi = 180
      )
    } else if (has_platetools) {
      fallback_plot <- platetools::raw_grid(
        data = plate_data[[value_col]],
        well = plate_data$well,
        plate = 96
      ) +
        ggtitle(paste(title_prefix, current_plate))
      print(fallback_plot)
      ggsave(
        filename = file.path(output_dir, paste0(file_prefix, ".", current_plate, ".png")),
        plot = fallback_plot,
        width = 8.5,
        height = 6.5,
        dpi = 180
      )
    }
  }

  dev.off()
}

if (has_ggplate || has_platetools) {
  demux_palette <- c("#edf4ea", "#b9cfb5", "#8fad8d", "#5f7965", "#35523c")
  quality_palette <- c("#b94b55", "#e6c75b", "#8fad8d", "#35523c")

  plot_plate_series(
    data = demux_plates,
    value_col = "count",
    label_col = "count",
    title_prefix = "Demultiplexed sequences",
    file_prefix = "plate_demultiplexed",
    colour_scale = demux_palette
  )

  plot_plate_series(
    data = quality_plates,
    value_col = "score",
    label_col = "score",
    title_prefix = "Collapsed quality score",
    file_prefix = "plate_quality",
    colour_scale = quality_palette
  )
}
