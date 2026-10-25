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

students <- d[!is.na(d$ed_total) & d$ed_total > 0, ]
n_students <- nrow(students)
keep <- students$ed_total >= 100 & students$ed_total <= 1000000
n_excluded <- sum(!keep)
s <- students[keep, ]

wmean <- function(x, w) sum(w * x) / sum(w)
wquantile <- function(x, w, p) {
  o <- order(x)
  x <- x[o]
  w <- w[o]
  cw <- cumsum(w) / sum(w)
  x[which(cw >= p - 1e-12)[1]]
}

w_med <- wquantile(s$ed_total, s$hhweight, 0.50)
u_med <- median(s$ed_total)
w_p10 <- wquantile(s$ed_total, s$hhweight, 0.10)
w_p90 <- wquantile(s$ed_total, s$hhweight, 0.90)

logx <- log10(s$ed_total)
breaks <- seq(2, 6, by = 0.1)

bin_id <- findInterval(logx, breaks, rightmost.closed = TRUE)
bin_id[bin_id == 41] <- 40

w_bin <- sapply(1:40, function(b) sum(s$hhweight[bin_id == b]))

bins <- data.frame(
  xmin = breaks[1:40],
  xmax = breaks[2:41],
  density = w_bin / sum(s$hhweight) / 0.1
)

fmt_rs <- function(x) format(round(x), big.mark = ",", scientific = FALSE)
ymax <- max(bins$density)

p <- ggplot2::ggplot(bins, ggplot2::aes(xmin = xmin, xmax = xmax,
                                        ymin = 0, ymax = density)) +
  ggplot2::geom_rect(fill = "#4C72B0", colour = "white",
                     linewidth = 0.15) +
  ggplot2::geom_vline(xintercept = log10(w_med), linetype = "dashed",
                      colour = "#C0392B", linewidth = 0.8) +
  ggplot2::geom_vline(xintercept = log10(w_p90), linetype = "dashed",
                      colour = "#C0392B", linewidth = 0.8) +
  ggplot2::annotate("label", x = log10(w_med), y = ymax * 0.93,
                    label = paste0("Median\nRs ", fmt_rs(w_med)),
                    hjust = 1.08, vjust = 1, size = 3.4, fill = "white",
                    linewidth = 0, colour = "#7B241C") +
  ggplot2::annotate("label", x = log10(w_p90), y = ymax * 0.93,
                    label = paste0("90th percentile\nRs ", fmt_rs(w_p90)),
                    hjust = -0.08, vjust = 1, size = 3.4, fill = "white",
                    linewidth = 0, colour = "#7B241C") +
  ggplot2::scale_x_continuous(
    breaks = 2:6,
    labels = c("Rs 100", "Rs 1,000", "Rs 10,000", "Rs 100,000",
               "Rs 1,000,000"),
    limits = c(2, 6), expand = c(0, 0)
  ) +
  ggplot2::scale_y_continuous(expand = ggplot2::expansion(mult = c(0, 0.18))) +
  ggplot2::labs(
    title = "The top tenth of students spend ten times what the bottom tenth spend",
    x = "Annual education spending per student (rupees)",
    y = "Density per log10 unit",
    caption = paste(
      "Source: PSLM 2019-20 person and household files.",
      "Sample: students with ed_total > 0 in KP rural (variant 4).",
      "Weighted by hhweight.",
      sprintf("Excludes %d students outside Rs 100-Rs 1,000,000; log10 bins 0.1 wide.",
              n_excluded)
    )
  ) +
  ggplot2::theme_minimal(base_size = 12) +
  ggplot2::theme(
    panel.grid.minor = ggplot2::element_blank(),
    plot.title = ggplot2::element_text(face = "bold", size = 13),
    plot.caption = ggplot2::element_text(hjust = 0, size = 8.5,
                                         colour = "grey35"),
    axis.title = ggplot2::element_text(colour = "grey20"),
    axis.text.x = ggplot2::element_text(size = 9.5)
  )

ggplot2::ggsave(file.path(repo, "figures", "distribution.svg"), p,
                width = 10, height = 6.5, device = svglite::svglite)

cat("Variant 4: Khyber Pakhtunkhwa, rural\n")
cat("Students (ed_total > 0):", n_students, "\n")
cat("Excluded outside Rs 100-1,000,000:", n_excluded, "\n")
cat("Weighted median:", round(w_med), "\n")
cat("Unweighted median:", round(u_med), "\n")
cat("Weighted p10:", round(w_p10), "\n")
cat("Weighted p90:", round(w_p90), "\n")
cat("p90/p10 ratio:", sprintf("%.2f", w_p90 / w_p10), "\n")
cat("Weighted mean:", sprintf("%.2f", wmean(s$ed_total, s$hhweight)), "\n")

