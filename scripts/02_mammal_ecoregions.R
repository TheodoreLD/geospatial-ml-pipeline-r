# =============================================================================
# MAMMAL ECOREGION SPECIES PRESENCE ANALYSIS
# =============================================================================

# Load required packages
library(sf)        # spatial vector handling
library(terra)     # raster operations
library(dplyr)     # data manipulation
library(purrr)     # functional programming (map)
library(readr)     # CSV I/O
library(tidyr)     # data tidying

# Define project directory and paths
project_dir <- ""
paths <- list(
  traits       = file.path(project_dir, "Data", "Range_mammals", "Traits", "Trait_data.csv"),
  ranges_nat   = file.path(project_dir, "Data", "Range_mammals", "Ranges", "Present_natural"),
  ecoregions   = file.path(project_dir, "Data", "Ecoregion", "Ecoregions2017.shp"),
  outputs      = file.path(project_dir, "output", "Ecoregion_mammal")
)

# -----------------------------------------------------------------------------
# 1. LOAD & FILTER MAMMAL TRAIT DATA
# -----------------------------------------------------------------------------
traits <- read_csv(paths$traits, show_col_types = FALSE) %>%
  filter(
    Mass.g      > 5000,
    Terrestrial == 1,
    Diet.Plant  > 0,
    !Order.1.2 %in% c("Carnivora", "Dasyuromorphia")
  ) %>%
  mutate(
    raster_path = file.path(paths$ranges_nat, paste0(Binomial.1.2, ".tif"))
  ) %>%
  filter(file.exists(raster_path))

# -----------------------------------------------------------------------------
# 2. READ & FILTER WWF ECOREGIONS
# -----------------------------------------------------------------------------
eco <- st_read(
  paths$ecoregions,
  quiet = TRUE
) %>%
  st_make_valid()

target_ecos <- c(
  "Beni savanna",
  "Cross-Niger transition forests",
  "Tonle Sap freshwater swamp forests"
)

selected_ecos <- eco %>%
  filter(ECO_NAME %in% target_ecos)

# -----------------------------------------------------------------------------
# 3. REPROJECT TO MATCH SPECIES RASTERS
# -----------------------------------------------------------------------------
ref_rast      <- rast(traits$raster_path[1])
selected_ecos <- st_transform(selected_ecos, crs = crs(ref_rast))
eco_vect      <- vect(selected_ecos)

# -----------------------------------------------------------------------------
# 4. HELPER: SPECIES PRESENCE TEST
# -----------------------------------------------------------------------------
present_in_poly <- function(r_path, poly_sf) {
  r_vals <- terra::extract(rast(r_path), vect(poly_sf))[[2]]
  any(r_vals == 1, na.rm = TRUE)
}

# -----------------------------------------------------------------------------
# 5. BUILD SPECIES LIST PER ECOREGION
# -----------------------------------------------------------------------------
ecoregion_species <- selected_ecos %>%
  dplyr::select(ECO_NAME, geometry) %>%
  mutate(
    species = map(
      geometry,
      ~ {
        flags <- map_lgl(traits$raster_path,
                         present_in_poly,
                         poly_sf = .x)
        traits$Binomial.1.2[flags]
      }
    )
  ) %>%
  st_set_geometry(NULL)

# -----------------------------------------------------------------------------
# 6. UNNEST & SAVE FULL SPECIES LIST
# -----------------------------------------------------------------------------
ecoregion_unnested <- ecoregion_species %>%
  unnest(cols = species) %>%
  rename(
    Ecoregion = ECO_NAME,
    Species   = species
  )

write_csv(
  ecoregion_unnested,
  file.path(paths$outputs, "ecoregion_mammals.csv")
)

# -----------------------------------------------------------------------------
# 7. COMPUTE & SAVE ORDER COUNTS PER REGION
# -----------------------------------------------------------------------------
region_order_counts <- ecoregion_unnested %>%
  distinct(Ecoregion, Species) %>%
  left_join(
    traits %>% dplyr::select(Binomial.1.2, Order.1.2),
    by = c("Species" = "Binomial.1.2")
  ) %>%
  count(Ecoregion, Order.1.2, name = "SpeciesCount") %>%
  arrange(Ecoregion, desc(SpeciesCount))

write_csv(
  region_order_counts,
  file.path(paths$outputs, "ecoregion_order_counts.csv")
)



