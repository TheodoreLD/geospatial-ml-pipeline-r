# 00_standardization.R
# Purpose: Standardize species names

library(dplyr)
library(readr)
library(here)

# ---- FUNCTION ----
standardize_species_names <- function(input_path, output_path) {
  
  cat("Reading input data...\n")
  data <- read_csv(input_path)
  
  cat("Standardizing species names...\n")
  
  data_clean <- data %>%
    mutate(
      Species = trimws(Species),
      Species = tolower(Species)
    )
  
  # Add more cleaning rules here if needed
  
  cat("Writing cleaned data...\n")
  write_csv(data_clean, output_path)
  
  cat("Standardization complete\n")
  
  return(data_clean)
}

# ---- EXECUTION ----
input_file <- here("data", "raw", "species_raw.csv")
output_file <- here("data", "processed", "species_clean.csv")

if (file.exists(input_file)) {
  standardize_species_names(input_file, output_file)
} else {
  cat("Input file not found. Skipping step.\n")
}