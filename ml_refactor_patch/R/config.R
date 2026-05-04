# Project-wide configuration -------------------------------------------------
# Keep all paths relative to the repository root.

suppressPackageStartupMessages({
  library(here)
})

paths <- list(
  data = here("data"),
  data_raw = here("data", "raw"),
  data_processed = here("data", "processed"),
  outputs = here("outputs"),
  raster_model = here("outputs", "raster_model"),
  model_outputs = here("outputs", "models"),
  model1 = here("outputs", "models", "model1_global_drivers"),
  model2 = here("outputs", "models", "model2_univariate_monotonic"),
  model3 = here("outputs", "models", "model3_univariate_unconstrained")
)

create_project_dirs <- function() {
  invisible(lapply(paths, dir.create, recursive = TRUE, showWarnings = FALSE))
}

require_file <- function(path, label = path) {
  if (!file.exists(path)) {
    stop(sprintf("Missing required file: %s\nExpected at: %s", label, path), call. = FALSE)
  }
  path
}
