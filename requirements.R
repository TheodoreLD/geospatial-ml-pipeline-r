# requirements.R
# Install required packages for the project

required_packages <- c(
  "here",
  "terra",
  "dplyr",
  "readr",
  "ggplot2",
  "sf",
  "blockCV",
  "purrr",
  "tidyr",
  "viridis",
  "rnaturalearth",
  "data.table"
)

installed <- rownames(installed.packages())
to_install <- setdiff(required_packages, installed)

if (length(to_install) > 0) {
  install.packages(to_install, repos = "https://cloud.r-project.org")
}

cat("Base project packages installed.\n")
cat("IMPORTANT: CatBoost must be installed manually if unavailable through your R setup.\n")
cat("See: https://catboost.ai/docs/en/installation/r-installation\n")