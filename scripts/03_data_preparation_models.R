# =============================================================================
# 03_data_preparation_models.R
# Prepare predictor and mammal clade richness stacks for downstream modeling.
# =============================================================================

suppressPackageStartupMessages({
  library(terra)
  library(dplyr)
  library(readr)
  library(viridis)
})

source("R/config.R")
create_project_dirs()

# ---- Input paths -------------------------------------------------------------
input_paths <- list(
  trunk_richness = here("outputs", "biogeography", "rasters", "Relative_Richness_Tot.tif"),
  env_preds_dir = here("data", "raw", "Map_environmental_predictors"),
  phylacine_traits = here("data", "raw", "Range_mammals", "Traits", "Trait_data.csv"),
  phylacine_ranges = here("data", "raw", "Range_mammals", "Ranges", "Present_natural"),
  consumption_rds = here("data", "raw", "Map_mammal_consumption", "Map.rds")
)

# ---- Helpers -----------------------------------------------------------------
align_to_template <- function(x, template, method = "bilinear") {
  terra::project(x, template, method = method)
}

plot_raster_to_pdf <- function(raster, path, title = names(raster)[1]) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  grDevices::pdf(path, width = 7, height = 5)
  on.exit(grDevices::dev.off(), add = TRUE)
  plot(raster, main = title, xlab = "Longitude", ylab = "Latitude")
}

load_large_herbivore_traits <- function(traits_csv) {
  readr::read_csv(traits_csv, show_col_types = FALSE) %>%
    filter(
      Mass.g > 5000,
      Terrestrial == 1,
      Diet.Plant > 0,
      !Order.1.2 %in% c("Carnivora", "Dasyuromorphia")
    ) %>%
    mutate(species_name = gsub("_", " ", Binomial.1.2))
}

build_mammal_richness <- function(large_mammals, ranges_dir, template) {
  range_paths <- file.path(ranges_dir, paste0(large_mammals$Binomial.1.2, ".tif"))
  valid_paths <- range_paths[file.exists(range_paths)]

  if (length(valid_paths) == 0) {
    stop("No mammal range rasters found. Check data/raw/Range_mammals/Ranges/Present_natural.", call. = FALSE)
  }

  mammal_stack <- terra::rast(valid_paths)
  mammal_richness <- terra::sum(mammal_stack, na.rm = TRUE)
  align_to_template(mammal_richness, template, method = "bilinear")
}

build_clade_richness_stack <- function(large_mammals, ranges_dir, template, output_dir) {
  clades <- sort(unique(large_mammals$Order.1.2))
  all_tifs <- list.files(ranges_dir, "\\.tif$", full.names = TRUE, recursive = TRUE)

  clade_layers <- vector("list", length(clades))
  names(clade_layers) <- clades

  for (clade in clades) {
    message("Building clade richness layer: ", clade)
    species <- large_mammals %>%
      filter(Order.1.2 == clade) %>%
      pull(species_name)

    clade_raster <- template
    values(clade_raster) <- 0L

    for (sp in species) {
      expected_file <- paste0(gsub(" ", "_", sp), ".tif")
      matches <- all_tifs[tolower(basename(all_tifs)) == tolower(expected_file)]
      if (length(matches) == 0) next

      species_raster <- terra::rast(matches[1])
      species_projected <- terra::project(species_raster, template, method = "near")
      species_binary <- terra::ifel(is.na(species_projected), 0L, terra::ifel(species_projected > 0, 1L, 0L))
      clade_raster <- clade_raster + species_binary
    }

    names(clade_raster) <- clade
    clade_layers[[clade]] <- clade_raster
    terra::writeRaster(clade_raster, file.path(output_dir, paste0("richness_", clade, ".tif")), overwrite = TRUE)
  }

  clade_stack <- terra::rast(clade_layers)
  clade_stack[clade_stack == 0] <- NA
  clade_stack
}

# ---- Main --------------------------------------------------------------------
message("Preparing predictor stack...")

trunk_richness <- terra::rast(require_file(input_paths$trunk_richness, "relative trunk richness raster"))
names(trunk_richness) <- "trunkrichness"

vpi_stack <- terra::rast(require_file(file.path(input_paths$env_preds_dir, "vpi_stack.nc"), "VPI stack"))
cold_stack <- terra::rast(require_file(file.path(input_paths$env_preds_dir, "cold_stack.nc"), "cold-season deciduousness stack"))
dry_stack <- terra::rast(require_file(file.path(input_paths$env_preds_dir, "dry_stack.nc"), "dry-season deciduousness stack"))
height_nc <- terra::rast(require_file(file.path(input_paths$env_preds_dir, "height.nc"), "vegetation height raster"))

vpi_mean <- mean(align_to_template(vpi_stack, trunk_richness), na.rm = TRUE)
cold_mean <- mean(align_to_template(cold_stack, trunk_richness), na.rm = TRUE)
dry_mean <- mean(align_to_template(dry_stack, trunk_richness), na.rm = TRUE)
height <- align_to_template(height_nc, trunk_richness)

large_mammals <- load_large_herbivore_traits(require_file(input_paths$phylacine_traits, "PHYLACINE traits"))
mammal_richness <- build_mammal_richness(large_mammals, input_paths$phylacine_ranges, trunk_richness)

consumption_list <- readRDS(require_file(input_paths$consumption_rds, "mammal consumption RDS"))
consumption <- terra::rast(consumption_list[["pn.consumption.maps"]][[1]])
consumption <- align_to_template(consumption, trunk_richness)

predictor_stack <- c(
  trunk_richness,
  vpi_mean,
  cold_mean,
  dry_mean,
  height,
  mammal_richness,
  consumption
)

names(predictor_stack) <- c(
  "trunkrichness",
  "vpi_mean",
  "cold_mean",
  "dry_mean",
  "height",
  "mammal_richness",
  "consumption"
)

terra::writeRaster(predictor_stack, file.path(paths$raster_model, "predictor_target_stack.tif"), overwrite = TRUE)
saveRDS(predictor_stack, file.path(paths$raster_model, "predictor_target_stack.rds"))

model_df <- as.data.frame(predictor_stack, xy = TRUE) %>%
  rename(longitude = x, latitude = y) %>%
  filter(!is.na(trunkrichness))
readr::write_csv(model_df, file.path(paths$raster_model, "predictor_target_table.csv"))

for (layer_name in names(predictor_stack)) {
  plot_raster_to_pdf(
    predictor_stack[[layer_name]],
    file.path(paths$raster_model, paste0(layer_name, ".pdf")),
    title = layer_name
  )
}

message("Preparing mammal clade richness stack...")

clade_stack <- build_clade_richness_stack(
  large_mammals = large_mammals,
  ranges_dir = input_paths$phylacine_ranges,
  template = trunk_richness,
  output_dir = paths$raster_model
)

terra::writeRaster(clade_stack, file.path(paths$raster_model, "mammal_clade_richness_stack.tif"), overwrite = TRUE)
saveRDS(clade_stack, file.path(paths$raster_model, "mammal_clade_richness_stack.rds"))

for (clade in names(clade_stack)) {
  plot_raster_to_pdf(
    clade_stack[[clade]],
    file.path(paths$raster_model, paste0("clade_richness_", clade, ".pdf")),
    title = paste("Clade richness:", clade)
  )
}

message("Data preparation completed successfully.")
