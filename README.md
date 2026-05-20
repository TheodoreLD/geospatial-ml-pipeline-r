# Geospatial Machine Learning Pipeline in R

> Reproducible geospatial machine-learning workflow for modelling the global distribution, ecological associations, and evolutionary drivers of spiny-trunk woody plants.

This repository implements an end-to-end geospatial data science pipeline in R.

It integrates biodiversity data, global raster layers, mammal distribution data, environmental predictors, spatial feature engineering, gradient-boosted machine learning, spatial cross-validation, bootstrap uncertainty estimation, and interpretable model outputs.

The project is designed as a technical portfolio piece demonstrating applied expertise in:

- geospatial data engineering,
- raster and vector spatial processing,
- biodiversity informatics,
- statistical modelling,
- machine learning,
- spatial cross-validation,
- uncertainty quantification,
- interpretable machine learning,
- reproducible scientific computing.

---

## Project Objective

The objective of this project is to model the global distribution and ecological drivers of woody plant species bearing trunk spines.

The analysis focuses on the relative richness of spiny-trunk species and evaluates its association with environmental gradients, vegetation structure, climate seasonality, herbivory pressure, and mammal clade richness.

The workflow combines ecological theory with computational modelling to test whether present-natural and historical mammal communities help explain the contemporary geography of trunk-spine defences.

---

## Technical Overview

The pipeline implements:

- multi-source data integration,
- species-name standardization,
- global raster processing,
- vector/raster spatial overlay,
- spatial harmonization to a common grid,
- construction of absolute and relative richness metrics,
- extraction of environmental and biotic predictors,
- generation of model-ready tabular data,
- CatBoost gradient-boosted regression,
- monotonic and unconstrained model comparison,
- spatial cross-validation using `blockCV`,
- bootstrap-based uncertainty estimation,
- partial dependence analysis,
- curated GitHub-ready figures and methodological documentation.

The workflow is implemented in R and uses memory-efficient spatial operations with `terra`.

---

## Data and Feature Engineering

The workflow integrates:

- woody plant species with confirmed trunk spines,
- plant range and distribution data,
- global woody plant richness estimates,
- mammal distribution and richness data,
- herbivory-pressure and consumption estimates,
- climate and vegetation predictors,
- biome and ecoregion boundaries,
- remote-sensing-derived vegetation structure.

Feature construction includes:

- spatial harmonization to a common global grid,
- raster stacking and alignment,
- extraction of predictors by grid cell,
- construction of absolute and relative richness layers,
- biome and ecoregion summarization,
- integration of environmental, vegetation, and herbivore-related predictors,
- conversion of geospatial layers into model-ready tabular data.

---

## Statistical Modelling Framework

The response variable is the relative richness of woody species with trunk spines.

For each spatial grid cell *i*, relative trunk-spine richness is defined as:

**yᵢ = Sᵢ / Wᵢ**

where **Sᵢ** is the richness of woody species with trunk spines in grid cell *i*, and **Wᵢ** is the estimated total woody plant richness in the same grid cell.

In the code, this response variable is stored as `trunkrichness`.

The project implements three complementary modelling components:

1. a multivariate environmental and herbivory model;
2. monotonic mammal-clade models;
3. unconstrained mammal-clade models.

Together, these models separate global prediction from ecological interpretation.

---

## Model 1: Multivariate Environmental and Herbivory Model

Model 1 evaluates whether global variation in relative trunk-spine richness can be explained by vegetation structure, seasonal vegetation dynamics, and mammalian herbivory pressure.

For each grid cell *i*, the predictor vector is:

**xᵢ = (VPIᵢ, ColdSeasonalityᵢ, DrySeasonalityᵢ, Heightᵢ, MammalRichnessᵢ, Consumptionᵢ)**

where:

- **VPIᵢ** represents vegetation productivity,
- **ColdSeasonalityᵢ** represents cold-season vegetation limitation,
- **DrySeasonalityᵢ** represents dry-season vegetation limitation,
- **Heightᵢ** represents vegetation structure,
- **MammalRichnessᵢ** represents the richness of large terrestrial herbivorous mammals,
- **Consumptionᵢ** represents modelled mammalian plant consumption.

The multivariate model is written as:

**yᵢ = f₁(xᵢ) + εᵢ**

where **f₁** is the nonlinear function estimated by CatBoost, and **εᵢ** is the residual error.

CatBoost estimates **f₁** as an additive ensemble of regression trees:

**f̂₁(x) = ηT₁(x) + ηT₂(x) + ... + ηTₘ(x)**

where **Tₘ** is the tree added at boosting iteration *m*, and **η** is the learning rate.

The model is trained to minimize squared prediction error:

**Loss = Σ(yᵢ − ŷᵢ)²**

Predictive performance is evaluated using RMSE and R²:

**RMSE = sqrt(mean((yᵢ − ŷᵢ)²))**

**R² = 1 − Σ(yᵢ − ŷᵢ)² / Σ(yᵢ − ȳ)²**

Spatial cross-validation is used instead of random cross-validation because neighbouring grid cells are spatially autocorrelated. The model is therefore evaluated on spatially withheld blocks rather than randomly withheld points.

After tuning, bootstrap resampling is used to estimate uncertainty in model performance.

---

## Model 2: Monotonic Mammal-Clade Models

Model 2 evaluates whether the richness of individual mammal clades is positively associated with relative trunk-spine richness.

For each mammal clade and geographic region, the monotonic model is written as:

**yᵢ = f⁺(zᵢ) + εᵢ**

where **zᵢ** is the richness of a given mammal clade in grid cell *i*, and **f⁺** is a nonlinear CatBoost function constrained to be non-decreasing.

The monotonic constraint means:

**as zᵢ increases, f⁺(zᵢ) is not allowed to decrease.**

In ecological terms, this model tests whether higher mammal clade richness is associated with equal or higher predicted relative trunk-spine richness.

The strength of the positive association is summarized using a standardized slope. The mammal clade richness predictor is first standardized:

**zᵢ* = (zᵢ − mean(z)) / sd(z)**

The modelled positive association is then summarized as:

**ŷᵢ = α + βzᵢ***

where larger positive values of **β** indicate stronger positive association between mammal clade richness and relative trunk-spine richness.

This model is hypothesis-driven: it tests whether a mammal clade is a plausible positive ecological or evolutionary correlate of trunk-spine richness.

---

## Model 3: Unconstrained Mammal-Clade Models

Model 3 uses the same response and predictor structure as Model 2, but removes the monotonic constraint.

For each mammal clade and geographic region, the unconstrained model is written as:

**yᵢ = g(zᵢ) + εᵢ**

where **g** is an unconstrained nonlinear CatBoost function.

Unlike Model 2, this model allows the relationship between mammal clade richness and trunk-spine richness to be:

- increasing,
- decreasing,
- saturating,
- threshold-like,
- unimodal,
- or otherwise non-monotonic.

Model 2 and Model 3 therefore answer complementary questions.

Model 2 asks:

**Does a mammal clade show a positive directional association with trunk-spine richness?**

Model 3 asks:

**What is the empirical shape of the relationship without imposing a directional biological assumption?**

---

## Model Interpretation

The modelling framework separates prediction, interpretation, and hypothesis testing.

Model 1 asks whether environmental conditions, vegetation structure, and mammalian herbivory pressure jointly explain global variation in relative trunk-spine richness.

Model 2 asks which mammal clades show positive associations with relative trunk-spine richness under a biologically constrained monotonic assumption.

Model 3 explores the unconstrained shape of each mammal-clade relationship.

Partial dependence plots are used to visualize modelled predictor effects, while bootstrap resampling is used to estimate uncertainty around model performance and predictor-response relationships.

---

## Results Snapshot

Selected lightweight outputs are included in `docs/figures/` so that the project can be inspected directly from GitHub without requiring users to run the full geospatial pipeline.

### Absolute richness of spiny-trunk woody species

![Absolute richness of spiny-trunk woody species](docs/figures/01_absolute_richness.png)

### Relative richness across biomes and ecoregions

![Relative richness across biomes and ecoregions](docs/figures/02_relative_richness_biome_ecoregion.png)

### Environmental and herbivory model

![Environmental model](docs/figures/03_environmental_model.png)

### Mammal-clade association model

![Mammal clade model](docs/figures/04_mammal_clade_model.png)

---

## Repository Structure

```text
.
├── R/
│   └── config.R
├── scripts/
│   ├── 00_standardization.R
│   ├── 01_biogeography_trunk.R
│   ├── 02_mammal_ecoregions.R
│   ├── 03_data_preparation_models.R
│   └── 04_catboost_models.R
├── docs/
│   ├── figures/
│   │   ├── 01_absolute_richness.png
│   │   ├── 02_relative_richness_biome_ecoregion.png
│   │   ├── 03_environmental_model.png
│   │   └── 04_mammal_clade_model.png
│   ├── methods/
│   │   └── mathematical_framework.md
│   └── tables/
├── outputs/
│   └── ignored generated outputs
├── data/
│   └── ignored raw and intermediate data
├── renv.lock
├── requirements.R
├── run_pipeline.R
└── README.md
```

---

## Reproducibility

The project uses `renv` for dependency management.

To restore the R environment:

```r
renv::restore()
```

To run the full pipeline:

```r
source("run_pipeline.R")
```

Raw data and heavy geospatial outputs are excluded from version control. Curated figures and methodological documentation are included in `docs/`.

---

## Example Outputs

The pipeline generates:

- absolute richness maps,
- relative richness maps,
- biome and ecoregion summaries,
- model-ready predictor tables,
- CatBoost model outputs,
- spatial cross-validation results,
- bootstrap performance summaries,
- partial dependence plots,
- constrained and unconstrained mammal-clade model diagnostics.

Only selected lightweight outputs are tracked in GitHub.

---
