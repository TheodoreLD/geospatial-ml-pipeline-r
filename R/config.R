# R/config.R
# Centralized project paths

library(here)

dir.create(here("data", "raw"), recursive = TRUE, showWarnings = FALSE)
dir.create(here("data", "processed"), recursive = TRUE, showWarnings = FALSE)
dir.create(here("outputs"), recursive = TRUE, showWarnings = FALSE)

paths <- list(
  data_raw = here("data", "raw"),
  data_processed = here("data", "processed"),
  outputs = here("outputs")
)