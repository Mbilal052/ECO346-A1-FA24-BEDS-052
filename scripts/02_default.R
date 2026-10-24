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

literacy <- d[!is.na(d$literate) & d$age >= 10 & d$age <= 64, ]

p <- ggplot2::ggplot(literacy, ggplot2::aes(x = age, y = literate)) +
  ggplot2::geom_point()

ggplot2::ggsave(file.path(repo, "figures", "default.svg"), p,
                width = 7, height = 5, device = svglite::svglite)

cat("Default scatterplot saved: figures/default.svg\n")
cat("Observations:", nrow(literacy), "\n")

