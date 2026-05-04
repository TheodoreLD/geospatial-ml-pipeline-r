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
  "rnaturalearth"
)

installed <- rownames(installed.packages())

to_install <- setdiff(required_packages, installed)

if (length(to_install) > 0) {
  install.packages(to_install, repos = "https://cloud.r-project.org")
}

cat("Base packages installed\n")

# CatBoost must be installed manually
cat("IMPORTANT: Install CatBoost manually:\n")
cat("https://catboost.ai/docs/en/installation/r-installation\n")