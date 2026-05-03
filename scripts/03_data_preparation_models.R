# =============================================================================
# PREDICTOR STACK PREPARATION FOR GRADIENT BOOSTING
# =============================================================================

# Load required packages
library(terra)    # raster I/O & geoprocessing
library(dplyr)    # data manipulation
library(readr)    # CSV import

# Define project directory and paths
project_dir <- ""
paths <- list(
  trunk_richness   = file.path(project_dir, "output", "Biogeography", "rasters", "Relative_Richness_Tot.tif"),
  env_preds_dir    = file.path(project_dir, "Data", "Map_environmental_predictors"),
  phylacine_traits = file.path(project_dir, "Data", "Range_mammals", "Traits", "Trait_data.csv"),
  phylacine_ranges = file.path(project_dir, "Data", "Range_mammals", "Ranges", "Present_natural"),
  consumption_rds  = file.path(project_dir, "Data", "Map_mammal_consumption", "Map.rds"),
  model_out_dir    = file.path(project_dir, "output", "Raster_model")
)

# 1. Load trunk richness raster
loaded_raster <- rast(paths$trunk_richness)
names(loaded_raster) <- "trunkrichness"

# 2. Load Environmental Predictors
vpi_stack  <- rast(file.path(paths$env_preds_dir, "vpi_stack.nc"))
cold_stack <- rast(file.path(paths$env_preds_dir, "cold_stack.nc"))
dry_stack  <- rast(file.path(paths$env_preds_dir, "dry_stack.nc"))
height_nc  <- rast(file.path(paths$env_preds_dir, "height.nc"))

# 3. Alignment helper
align_to_template <- function(x, template, method) {
  project(x, template, method = method)
}

# 4. Align and collapse climate/elevation
vpi_mean  <- mean(align_to_template(vpi_stack,  loaded_raster, "bilinear"), na.rm = TRUE)
cold_mean <- mean(align_to_template(cold_stack, loaded_raster, "bilinear"), na.rm = TRUE)
dry_mean  <- mean(align_to_template(dry_stack,  loaded_raster, "bilinear"), na.rm = TRUE)
height_aligned <- align_to_template(height_nc, loaded_raster, "bilinear")

# 5. Build mammal richness from PHYLACINE
traits_data <- read_csv(paths$phylacine_traits, show_col_types = FALSE)
LargeMammals <- traits_data %>%
  filter(Mass.g > 5000, Terrestrial == 1, Diet.Plant > 0,
         !Order.1.2 %in% c("Carnivora","Dasyuromorphia"))
range_paths <- file.path(paths$phylacine_ranges,
                         paste0(LargeMammals$Binomial.1.2, ".tif"))
valid <- file.exists(range_paths)
MammalRC <- rast(range_paths[valid])
mammal_richness <- sum(MammalRC, na.rm = TRUE)
mammal_aligned  <- align_to_template(mammal_richness, loaded_raster, "bilinear")

# 6. Load & align consumption raster
rds_list       <- readRDS(paths$consumption_rds)
pn_consumption <- rast(rds_list[["pn.consumption.maps"]][[1]])
consumption_aligned <- align_to_template(pn_consumption, loaded_raster, "bilinear")

# 7. Assemble predictor stack
predictor_stack <- c(
  loaded_raster,
  vpi_mean,
  cold_mean,
  dry_mean,
  height_aligned,
  mammal_aligned,
  consumption_aligned
)
names(predictor_stack) <- c(
  "trunkrichness", "vpi_mean", "cold_mean", "dry_mean",
  "height", "mammal_richness", "consumption"
)

# 8. Convert to data.frame for modeling
df_model <- as.data.frame(predictor_stack, xy = TRUE) %>%
  rename(longitude = x, latitude = y) %>%
  filter(!is.na(trunkrichness))

# 9. Quick checks
print(predictor_stack)
plot(predictor_stack$mammal_richness, main = "Mammal Richness")

# 10. Save each layer as PDF
for (lay in names(predictor_stack)) {
  pdf(file.path(paths$model_out_dir, paste0(lay, ".pdf")), width = 7, height = 5)
  plot(predictor_stack[[lay]], main = lay, xlab = "Longitude", ylab = "Latitude")
  dev.off()
}

# 11. Write stack to disk
writeRaster(predictor_stack,
            file.path(paths$model_out_dir, "predictor_target_stack.tif"),
            overwrite = TRUE)
saveRDS(predictor_stack,
        file = file.path(paths$model_out_dir, "predictor_target_stack.rds"))

# =============================================================================
# CLADE RICHNESS STACK PREPARATION FOR MODELING
# =============================================================================

library(terra)
library(dplyr)
library(readr)

# Project directories (adapt these as needed)
project_dir   <- ""
traits_csv    <- file.path(project_dir, "Data", "Range_mammals", "Traits", "Trait_data.csv")
ranges_dir    <- file.path(project_dir, "Data", "Range_mammals", "Ranges", "Present_natural")
plots_dir     <- file.path(project_dir, "output", "Raster_model")
template_rast <- rast(file.path(project_dir, "output", "Biogeography", "rasters", "Relative_Richness_Tot.tif"))

# Filter traits as before
traits_data  <- read_csv(traits_csv)
LargeMammals <- traits_data %>%
  filter(
    Mass.g     > 5000,
    Terrestrial == 1,
    Diet.Plant > 0,
    !Order.1.2 %in% c("Carnivora", "Dasyuromorphia")
  ) %>%
  mutate(species_name = gsub("_", " ", Binomial.1.2))

clades <- unique(LargeMammals$Order.1.2)
all_tifs <- list.files(ranges_dir, "\\.tif$", full.names = TRUE, recursive = TRUE)
clade_layers <- vector("list", length(clades))
names(clade_layers) <- clades

for (cl in clades) {
  spp <- LargeMammals %>% filter(Order.1.2 == cl) %>% pull(species_name)
  r_cl <- template_rast
  values(r_cl) <- 0L
  for (sp in spp) {
    fname <- paste0(gsub(" ", "_", sp), ".tif")
    hit   <- grep(paste0("^", fname, "$"), basename(all_tifs), value = TRUE, ignore.case = TRUE)
    if (length(hit) == 0) next
    tif_path <- file.path(ranges_dir, hit[1])
    r_sp     <- rast(tif_path)
    r_ll     <- project(r_sp, template_rast, method = "near")
    v_bin    <- ifelse(is.na(values(r_ll)), 0L, ifelse(values(r_ll) > 0, 1L, 0L))
    r_bin    <- setValues(template_rast, v_bin)
    r_cl <- r_cl + r_bin
    rm(r_sp, r_ll, r_bin); gc()
  }
  names(r_cl) <- cl
  clade_layers[[cl]] <- r_cl
  writeRaster(r_cl, file.path(plots_dir, paste0("Richness_", cl, ".tif")), overwrite = TRUE)
}

clade_stack <- rast(clade_layers)
clade_stack[clade_stack == 0] <- NA

# Optional: plot all panels
terra::plot(
  clade_stack,
  main   = names(clade_stack),
  col    = viridis::viridis(100),
  layout = c(3, 4),
  na.col = "lightblue"
)

# SAVE: Multi-band TIFF and RDS
writeRaster(clade_stack,
            file.path(plots_dir, "Mammal_clade_richness_stack.tif"),
            overwrite = TRUE)
saveRDS(clade_stack,
        file = file.path(plots_dir, "Mammal_clade_richness_stack.rds"))

# Save each clade richness map as PDF and/or PNG
for (cl in names(clade_stack)) {
  # PDF version
  pdf(file.path(plots_dir, paste0("Clade_Richness_", cl, ".pdf")), width = 7, height = 5)
  plot(clade_stack[[cl]], main = paste("Clade Richness:", cl),
       col = viridis(100), xlab = "Longitude", ylab = "Latitude", 
       axes = FALSE, box = FALSE)
  dev.off()
}
