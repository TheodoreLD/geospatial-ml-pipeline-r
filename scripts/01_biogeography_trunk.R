# =============================================================================
# ABSOLUTE SPECIES RICHNESS & RELATIVE SPECIES RICHNESS & BIOME & ECOREGION
# =============================================================================

# -----------------------------------------------------------------------------
# 1. PACKAGE & DIRECTORY
# -----------------------------------------------------------------------------
# Load required packages
library(terra)           # raster/vector operations
library(sf)              # spatial vector handling (shapefiles, transformations)
library(rnaturalearth)   # country borders
library(dplyr)           # data manipulation (joins, summaries)
library(ggplot2)         # plotting
library(viridis)         # color scales
library(readr)           # reading/writing CSVs


# Define project directories
project_dir <- ""
paths <- list(
  range_sub = file.path(project_dir, "Data", "Range_spiny_species", "SpeciesPrickly"),
  #Select "SpeciesTotal", "SpeciesThorny" or "SpeciesPrickly"
  predictions  = file.path(project_dir, "Data", "Map_global_plant_richness", "sr_Ensemble_Prediction_7774_LongLat.RData"),
  ecoregions = file.path(project_dir, "Data", "Ecoregion", "Ecoregions2017.shp"),
  rasters   = file.path(project_dir, "output", "Biogeography", "rasters"),
  plots     = file.path(project_dir, "output", "Biogeography", "plots"),
  tables     = file.path(project_dir, "output", "Biogeography", "tables")
)

# -----------------------------------------------------------------------------
# 2. ABSOLUTE RICHNESS
# -----------------------------------------------------------------------------
# Prepare template raster (0.1° WGS84)
template <- rast(ext(-180, 180, -90, 90), res = 0.1, crs = "EPSG:4326")
values(template) <- 0

# List species GeoPackages
range_out <- paths$range_sub
gpkg_list <- list.files(range_out, "\\.gpkg$", full.names = TRUE)

# Initialize richness raster
richness <- template

# Compute species richness raster
for (gpkg in gpkg_list) {
  v <- vect(gpkg)
  r <- rasterize(v, template, background = 0, touches = TRUE)
  r[r > 0] <- 1
  richness <- richness + r
}

# Save richness raster
dir.create(paths$rasters, recursive = TRUE, showWarnings = FALSE)
rich_path <- file.path(paths$rasters, "Absolute_Richness_Prickly.tif")
#Select: Absolute_Richness_Thorny.tif; Absolute_Richness_Prickly.tif; Absolute_Richness_Tot.tif
writeRaster(richness, rich_path, overwrite = TRUE)

# Plot species richness
plot(richness, main = "Species Richness")

# Export map
df <- as.data.frame(richness, xy = TRUE) %>%
  setNames(c("lon", "lat", "richness")) %>%
  filter(richness > 0)
world <- ne_countries(scale = "medium", returnclass = "sf")

p <- ggplot() + 
  geom_tile(data = df, aes(lon, lat, fill = richness)) +
  scale_fill_viridis_c(name = "Richness") +
  geom_sf(data = world, fill = NA, color = "black", size = 0.3) +
  coord_sf() +
  labs(title = "Species Richness", x = "Longitude", y = "Latitude") +
  theme_minimal()
p

if (!dir.exists(paths$plots)) dir.create(paths$plots, recursive = TRUE)
plot_path <- file.path(paths$plots, "Absolute_Richness_Prickly.png")
#Select: Absolute_Richness_Thorny.png; Absolute_Richness_Prickly.png; Absolute_Richness_Tot.png
ggsave(plot_path, p, width = 10, height = 6, dpi = 300)

# -----------------------------------------------------------------------------
# 3. RELATIVE RICHNESS
# -----------------------------------------------------------------------------
richness   <- rast(file.path(paths$rasters, "Absolute_Richness_Prickly.tif"))
#Select: Absolute_Richness_Thorny.tif; Absolute_Richness_Prickly.tif; Absolute_Richness_Tot.tif

# Load global richness prediction 
load(paths$predictions)

# Convert to terra vector
nat_vect <- if (inherits(predictions_grid, "sf")) {
  vect(predictions_grid)
} else {
  vect(predictions_grid)
}

# Rasterize and align to absolute species-richness grid
nat_rast    <- rasterize(nat_vect,      template, field = "value", fun = "mean")
nat_aligned <- resample(nat_rast,      richness,  method = "bilinear")

# Mask zeros and compute proportional richness
richness[richness == 0] <- NA
prop_rich <- richness / nat_aligned
prop_rich[is.nan(prop_rich)] <- NA
prop_rich[prop_rich == 0]   <- NA

# Save proportional richness raster
prop_path <- file.path(paths$rasters, "Relative_Richness_Prickly.tif")
#Select: Relative_Richness_Thorny.tif; Relative_Richness_Prickly.tif; Relative_Richness_Tot.tif
writeRaster(prop_rich, prop_path, overwrite = TRUE)

# Prepare data frame for ggplot
df_prop <- as.data.frame(prop_rich, xy = TRUE) %>%
  setNames(c("x", "y", "richness")) %>%
  filter(!is.na(richness))

# Country borders
countries <- ne_countries(scale = "medium", returnclass = "sf")

# Plot
p_prop <- ggplot() +
  geom_tile(data = df_prop, aes(x = x, y = y, fill = richness)) +
  geom_sf(data = countries, fill = NA, color = "black", size = 0.2) +
  scale_fill_viridis(name = "Prop. Richness", option = "D") +
  theme_minimal() +
  labs(title = "Proportional Richness of Spiny‑Trunk Species") +
  theme(
    axis.title   = element_blank(),
    axis.text    = element_blank(),
    axis.ticks   = element_blank(),
    panel.grid   = element_blank()
  )
p_prop

plot_path <- file.path(paths$plots, "Relative_Richness_Prickly.png")
#Select: Relative_Richness_Thorny.png; Relative_Richness_Prickly.png; Relative_Richness_Tot.png
ggsave(plot_path, p_prop, width = 10, height = 6, dpi = 300)

# -----------------------------------------------------------------------------
# 4. SUMMARY BY BIOME & ECOREGION
# -----------------------------------------------------------------------------

prop   <- rast(file.path(paths$rasters, "Relative_Richness_Prickly.tif"))
#Select: Relative_Richness_Thorny.tif; Relative_Richness_Prickly.tif; Relative_Richness_Tot.tif
plot(prop, main = "Proportional Richness")

# Read the ecoregions shapefile
eco <- st_read(
  paths$ecoregions,
  quiet = TRUE
) %>%
  st_make_valid() %>%
  st_transform(crs(prop))   # match CRS of raster

eco_vect <- vect(eco)

# Extract raster values into data frame
vals_df <- terra::extract(prop, eco_vect, df = TRUE)
names(vals_df)[2] <- "value"

# attach ECO_NAME & BIOME_NAME by polygon ID
eco_meta <- eco %>%
  st_drop_geometry() %>%
  mutate(ID = row_number()) %>%
  select(ID, ECO_NAME, BIOME_NAME)

vals_df <- vals_df %>%
  left_join(eco_meta, by = "ID") %>%
  filter(!is.na(value), !is.na(BIOME_NAME), !is.na(ECO_NAME))

# -----------------------------------------------------------------------------
# PART A: BIOME ANALYSIS
# -----------------------------------------------------------------------------

vals_biome <- vals_df %>% select(value, BIOME_NAME)

bio_stats <- vals_biome %>%
  group_by(BIOME_NAME) %>%
  summarise(
    mean_val   = mean(value, na.rm = TRUE),
    median_val = median(value, na.rm = TRUE),
    n_cells    = n()
  ) %>%
  ungroup()

p_biome <- ggplot(vals_biome, aes(x = value)) +
  geom_density(fill = "steelblue", alpha = 0.4) +
  geom_vline(data = bio_stats, aes(xintercept = mean_val),
             color = "red",    linetype = "dashed", linewidth = 0.7) +
  geom_vline(data = bio_stats, aes(xintercept = median_val),
             color = "darkblue", linetype = "dotdash", linewidth = 0.7) +
  facet_wrap(~ BIOME_NAME, scales = "free_y", ncol = 3) +
  labs(
    title = "Density of Relative Richness by Biome",
    x     = "Relative Richness",
    y     = "Density"
  ) +
  theme_minimal() +
  theme(
    strip.text  = element_text(size = 8),
    axis.text   = element_text(size = 6),
    plot.title  = element_text(hjust = 0.5)
  )
p_biome

write_csv(bio_stats, file.path(paths$tables, "biome_summary_Prickly.csv"))
#Select: biome_summary_Thorny.csv; biome_summary_Prickly.csv; biome_summary_Tot.csv
ggsave(file.path(paths$plots, "biome_density_Prickly.png"), p_biome, width = 12, height = 10, dpi = 300)
#Select: biome_density_Thorny.png; biome_density_Prickly.png; biome_density_Tot.png

# -----------------------------------------------------------------------------
# PART B: ECOREGION ANALYSIS
# -----------------------------------------------------------------------------
ecoregion_summary <- vals_df %>%
  group_by(ID, ECO_NAME) %>%
  summarise(
    mean_prop = mean(value, na.rm = TRUE),
    sd_prop   = sd(value,   na.rm = TRUE),
    n_cells   = n()
  ) %>%
  mutate(
    se      = sd_prop / sqrt(n_cells),
    ci_low  = mean_prop - 1.96 * se,
    ci_high = mean_prop + 1.96 * se
  ) %>%
  ungroup()

top30_eco <- ecoregion_summary %>%
  arrange(desc(mean_prop)) %>%
  slice_head(n = 30)

p_ecoregion <- ggplot(top30_eco, aes(x = mean_prop, y = reorder(ECO_NAME, mean_prop))) +
  geom_point(size = 2) +
  geom_errorbarh(aes(xmin = ci_low, xmax = ci_high),
                 height = 0.3, linewidth = 0.7) +
  labs(
    title = "Top 30 Ecoregions by Mean Relative Richness",
    x     = "Mean Relative Richness",
    y     = "Ecoregion"
  ) +
  theme_minimal() +
  theme(
    axis.text.y = element_text(size = 6),
    plot.title  = element_text(hjust = 0.5)
  )
p_ecoregion

write_csv(ecoregion_summary, file.path(paths$tables, "ecoregion_summary_Prickly.csv"))
#Select: ecoregion_summary_Thorny.csv; ecoregion_summary_Prickly.csv; ecoregion_summary_Tot.csv
ggsave(file.path(paths$plots, "top30_ecoregions_Prickly.png"),
       p_ecoregion, width = 8, height = 10, dpi = 300)
#Select: top30_ecoregions_Thorny.png; top30_ecoregions_Prickly.png; top30_ecoregions_Tot.png
