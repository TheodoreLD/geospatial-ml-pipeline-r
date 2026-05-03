# Install required packages

packages <- c(
  "tidyverse",
  "terra",
  "sf",
  "data.table",
  "catboost"
)

installed <- rownames(installed.packages())

for (p in packages) {
  if (!(p %in% installed)) {
    install.packages(p)
  }
}