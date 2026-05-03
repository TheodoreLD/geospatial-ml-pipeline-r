# =============================================================================
# Species Name Standardization
# =============================================================================

# -----------------------------------------------------------------------------
# 1. Load Required Packages
# -----------------------------------------------------------------------------
library(TNRS)      # Taxonomic Name Resolution Service
library(readxl)    # Reading Excel files
library(dplyr)     # Data wrangling

# -----------------------------------------------------------------------------
# 2. Load and Prepare Species List
# -----------------------------------------------------------------------------
# Define the input file path
file_path <- "/Spiny_trunk_species.xlsx"

# Read Excel file
df_raw <- read_excel(file_path)

# Select and rename the species column, add unique ID
df_species <- df_raw %>%
  mutate(ID = row_number()) %>%
  select(ID, taxon = Species)

# -----------------------------------------------------------------------------
# 3. Resolve Names Using TNRS
# -----------------------------------------------------------------------------
tnrs_result <- TNRS(
  taxonomic_names = df_species,
  sources         = c("wfo", "wcvp"),  # Preferred sources
  classification  = "wfo",
  matches         = "best",
  mode            = "resolve"
)

# -----------------------------------------------------------------------------
# 4. Flag Non-Accepted Names
# -----------------------------------------------------------------------------
tnrs_result <- tnrs_result %>%
  mutate(Name_Accepted = ifelse(Taxonomic_status != "Accepted", "No", "Yes"))

table(result$Name_Accepted)

# -----------------------------------------------------------------------------
# 5. Summary Report
# -----------------------------------------------------------------------------
cat("Summary of Accepted vs. Non-Accepted Names:\n")
print(table(tnrs_result$Name_Accepted))

