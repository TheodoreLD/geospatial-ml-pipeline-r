
# README – Global dataset of spiny-trunk species, associated predictors used in gradient boosting models, and scripts

**Source:** *In prep.* Global ecology and evolutionary drivers of spiny-trunk trees (2025).

---

## Contents

- **Spiny-trunk species list:** `Spiny_trunk_species.xlsx`
- **Raster maps of absolute and relative richness** for all species and by syndromes:
  - `Absolute_Richness_Total.tif`, `Relative_Richness_Total.tif`
  - `Absolute_Richness_Prickly.tif`, `Relative_Richness_Prickly.tif`
  - `Absolute_Richness_Thorny.tif`, `Relative_Richness_Thorny.tif`
- **Mammal clade richness stack:** `Mammal_clade_richness_stack.tif`  
- **Environmental and herbivory metric predictors + target variable stack:** `Predictors_target_stack.tif`
- **Analysis scripts**

---

## Spiny-trunk Species File

`Spiny_trunk_species.xlsx`

| Column             | Description                                                                 |
|--------------------|-----------------------------------------------------------------------------|
| `Species`          | Scientific name                                                             |
| `Family`           | Plant family                                                                |
| `Syndrome`         | Trunk defense type: *prickly* or *thorny* (according to Lefebvre et al., 2022)|
| `Range`            | Presence/absence of species distribution (in Boonman et al., 2024)          |
| `Native`           | Native continent of origin (according to Plants of the World Online)        |
| `Source / Picture` | References confirming trunk spines (e.g., floras, images, herbarium sheets) |

---

## Raster Layer Descriptions

From `Predictors_target_stack.tif`

| Layer             | Description                                                                                          |
|-------------------|------------------------------------------------------------------------------------------------------|
| `cold_mean`       | Cold-season deciduousness index (derived from Higgins et al., 2016)                                  |
| `dry_mean`        | Dry-season deciduousness index (derived from Higgins et al., 2016)                                   |
| `height`          | Vegetation height (Simard et al., 2011 via Higgins et al., 2016)                                     |
| `vpi`             | Vegetation Productivity Index (Higgins et al., 2016)                                                 |
| `consumption`     | Present-natural mammal consumption (Pedersen et al., 2023)                                           |
| `mammal_richness` | Present-natural large terrestrial herbivorous mammal richness (Faurby et al., 2020)                  |
| `trunkrichness`   | Relative richness of spiny-trunk species (target variable)                                           |

---

## Analysis Pipeline Overview

1. **Species name standardization:** Harmonization of species names  
2. **Calculation of richness metrics:**
   - Absolute and relative richness of spiny-trunk species
   - Relative richness by biome and ecoregion  
3. **Mammal species extraction by ecoregion:**  
   - Focused on regions with highest trunk spine richness per continent  
4. **Data preparation for modeling:**
   - Environmental predictors
   - Herbivory metrics
   - Mammal clade richness  
5. **Machine learning models:**
   - Multivariate model using vegetation structure and herbivory metrics
   - Univariate monotonic and unconstrained models using clade-level herbivory predictors

---

Original data:
- Range distribution of trees: Boonman, C. C. F., Serra-Diaz, J. M., Hoeks, S., Guo, W.-Y., Enquist, B. J., Maitner, B., … Svenning, J.-C. (2024). More than 17,000 tree species are at risk from rap-id global change. Nature Communications, 15(1), 166. https://doi.org/10.1038/s41467-023-44321-9.

- Global plant richness: Cai, L., Kreft, H., Taylor, A., Denelle, P., Schrader, J., Essl, F., … Weigelt, P. (2023). Global models and predictions of plant diversity based on advanced machine learning techniques. New Phytologist, 237(4), 1432–1445. https://doi.org/10.1111/nph.18533.

- Biome and ecoregion classification: Dinerstein, E., Olson, D., Joshi, A., Vynne, C., Burgess, N. D., Wikramanayake, E., … Saleem, M. (2017). An Ecoregion-Based Approach to Protecting Half the Terrestrial Realm. BioScience, 67(6), 534–545. https://doi.org/10.1093/biosci/bix014.

- Mammal range distribution and trait: Faurby, S., Pedersen, R. Ø., Davis, M., Schowanek, S. D., Jarvie, S., Antonelli, A., & Svenning, J.-C. (2020). MegaPast2Future/PHYLACINE_1.2: PHYLACINE Ver-sion 1.2.1 (Version v1.2.1) [Computer software]. Zenodo. https://doi.org/10.5281/ZENODO.3690867.

- Rasters of vegetation characteristics: Higgins, S. I., Buitenwerf, R., & Moncrieff, G. R. (2016). Defining functional biomes and monitoring their change globally. Global Change Biology, 22(11), 3583–3593. https://doi.org/10.1111/gcb.13367. 




