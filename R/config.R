# R/config.R
# Centralized project paths

library(here)

create_project_dirs <- function() {
  dir.create(here('data', 'raw'), recursive = TRUE, showWarnings = FALSE)
  dir.create(here('data', 'processed'), recursive = TRUE, showWarnings = FALSE)
  dir.create(here('outputs'), recursive = TRUE, showWarnings = FALSE)
  dir.create(here('outputs', 'model1'), recursive = TRUE, showWarnings = FALSE)
  dir.create(here('outputs', 'model2'), recursive = TRUE, showWarnings = FALSE)
  dir.create(here('outputs', 'model3'), recursive = TRUE, showWarnings = FALSE)
  dir.create(here('outputs', 'raster_model'), recursive = TRUE, showWarnings = FALSE)
}

require_file <- function(path, description = 'required file') {
  if (!file.exists(path)) {
    stop(sprintf('Missing %s: %s', description, path), call. = FALSE)
  }
  path
}

paths <- list(
  data_raw = here('data', 'raw'),
  data_processed = here('data', 'processed'),
  outputs = here('outputs'),
  model1 = here('outputs', 'model1'),
  model2 = here('outputs', 'model2'),
  model3 = here('outputs', 'model3'),
  raster_model = here('outputs', 'raster_model')
)
