args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args, value = TRUE)
repo <- if (length(file_arg)) {
  dirname(dirname(normalizePath(sub("^--file=", "", file_arg))))
} else {
  getwd()
}

person <- read.csv(file.path(repo, "data", "pslm_person_subset.csv"),
                   stringsAsFactors = FALSE)
hh <- read.csv(file.path(repo, "data", "pslm_hh_subset.csv"),
               stringsAsFactors = FALSE)
d <- merge(person, hh[, c("hhid", "hhweight", "prov_code", "urban_rural")],
           by = "hhid")
d <- d[d$prov_code == 1 & d$urban_rural == 1, ]

l <- d[!is.na(d$literate) & d$age >= 10 & d$age <= 64, ]
l$band <- 10 + 5 * floor((l$age - 10) / 5)
l$mid <- l$band + 2

agg <- aggregate(
  cbind(n = rep(1, nrow(l)), w = l$hhweight, wx = l$hhweight * l$literate),
  by = list(band = l$band, sex = l$sex),
  FUN = sum
)
agg$rate <- 100 * agg$wx / agg$w
agg$mid <- agg$band + 2
agg$thin <- agg$n < 30
agg$sex_label <- ifelse(agg$sex == 1, "Men", "Women")
agg$fill_col <- ifelse(
  agg$thin, "white",
  ifelse(agg$sex == 1, "#0072B2", "#D55E00")
)

sex_cols <- c("1" = "#0072B2", "2" = "#D55E00")
ends <- do.call(rbind, lapply(split(agg, agg$sex), function(z) {
  z[which.max(z$band), ]
}))

wide <- reshape(agg[, c("band", "sex", "rate")],
                idvar = "band", timevar = "sex", direction = "wide")
wide$gap <- wide$rate.1 - wide$rate.2
best <- wide[which.max(abs(wide$gap)), ]
best_mid <- best$band + 2
best_f <- best$rate.2
best_m <- best$rate.1

caption_text <- paste(
  "Source: PSLM 2019-20 person and household files.",
  "Sample: persons aged 10-64 with non-missing literacy in KP rural (variant 4).",
  "Weighted by hhweight. Hollow markers would mark an age-sex cell with fewer",
  "than 30 unweighted persons; every cell here has at least 30."
)
caption_text <- paste(strwrap(caption_text, width = 115), collapse = "\n")

p <- ggplot2::ggplot(agg, ggplot2::aes(x = mid, y = rate, group = sex)) +
  ggplot2::geom_line(ggplot2::aes(colour = factor(sex)), linewidth = 0.9) +
  ggplot2::geom_point(ggplot2::aes(colour = factor(sex), fill = fill_col),
                      shape = 21, size = 2.9, stroke = 0.8) +
  ggplot2::scale_colour_manual(values = sex_cols) +
  ggplot2::scale_fill_identity() +
  ggplot2::geom_text(
    data = ends,
    ggplot2::aes(x = mid + 1.3, y = rate, label = sex_label,
                 colour = factor(sex)),
    hjust = 0, vjust = 0.5, size = 4.1, fontface = "bold",
    show.legend = FALSE
  ) +
  ggplot2::annotate(
    "segment", x = best_mid + 0.15, xend = best_mid + 0.15,
    y = best_f, yend = best_m, colour = "grey25", linewidth = 0.6,
    arrow = grid::arrow(ends = "both", length = grid::unit(0.08, "in"))
  ) +
  ggplot2::annotate(
    "text", x = best_mid + 0.9, y = (best_f + best_m) / 2,
    label = sprintf("Largest gap:\nages %d-%d\n(%.1f pp)",
                    best$band, best$band + 4, abs(best$gap)),
    hjust = 0, vjust = 0.5, size = 3.3, colour = "grey15",
    fontface = "italic"
  ) +
  ggplot2::scale_x_continuous(
    limits = c(9, 68),
    breaks = seq(12, 62, by = 5),
    labels = paste0(seq(10, 60, by = 5), "-", seq(14, 64, by = 5))
  ) +
  ggplot2::scale_y_continuous(
    limits = c(0, 100),
    breaks = seq(0, 100, by = 20),
    labels = paste0(seq(0, 100, by = 20), "%"),
    expand = c(0, 0)
  ) +
  ggplot2::labs(
    title = "Literacy falls with age, and the gender gap peaks at ages 45-49",
    x = "Age band (years)",
    y = "Weighted literacy rate (%)",
    caption = caption_text
  ) +
  ggplot2::theme_minimal(base_size = 12) +
  ggplot2::theme(
    legend.position = "none",
    panel.grid.minor = ggplot2::element_blank(),
    plot.title = ggplot2::element_text(face = "bold", size = 13),
    plot.caption = ggplot2::element_text(hjust = 0, size = 8.3,
                                         colour = "grey35"),
    axis.title = ggplot2::element_text(colour = "grey20")
  )

ggplot2::ggsave(file.path(repo, "figures", "literacy.svg"), p,
                width = 10, height = 6.5, device = svglite::svglite)

out <- agg[order(agg$band, agg$sex), c("band", "sex", "n", "rate")]
cat("Variant 4: Khyber Pakhtunkhwa, rural\n")
cat("Literacy sample:", nrow(l), "persons\n\n")
cat(sprintf("%-7s %-6s %8s %10s\n", "band", "sex", "N", "weighted%"))
for (i in seq_len(nrow(out))) {
  cat(sprintf("%-7s %-6s %8d %10.1f\n",
              paste0(out$band[i], "-", out$band[i] + 4),
              ifelse(out$sex[i] == 1, "Men", "Women"),
              out$n[i], out$rate[i]))
}
cat("\n")
cat("Women 15-19:", sprintf("%.1f", agg$rate[agg$band == 15 & agg$sex == 2]), "\n")
cat("Men 15-19:", sprintf("%.1f", agg$rate[agg$band == 15 & agg$sex == 1]), "\n")
cat("Women 55-59:", sprintf("%.1f", agg$rate[agg$band == 55 & agg$sex == 2]), "\n")
cat("Men 55-59:", sprintf("%.1f", agg$rate[agg$band == 55 & agg$sex == 1]), "\n")
cat("Largest gap: ages", best$band, "-", best$band + 4,
    "=", sprintf("%.1f", abs(best$gap)), "pp\n")
cat("Thin cells:", sum(agg$thin), "\n")

