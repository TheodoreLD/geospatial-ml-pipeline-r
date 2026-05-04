# Geospatial Machine Learning Pipeline in R

This repository demonstrates an end-to-end data science workflow for geospatial analysis and machine learning in R.
It is designed as a structured, reproducible pipeline showcasing data preprocessing, feature engineering, and model development on large spatial datasets.

---

## Overview

The project implements a modular pipeline to analyze global patterns of spiny-trunk species richness and its environmental and biotic drivers.

Key components include:

* Data standardization and cleaning
* Spatial data processing (raster + vector)
* Feature engineering from ecological predictors
* Machine learning modeling (gradient boosting / CatBoost)
* Structured pipeline orchestration

---

## Repository Structure

```text
.
├── README.md
├── run_pipeline.R
├── requirements.R
├── scripts/
│   ├── 00_standardization.R
│   ├── 01_biogeography_trunk.R
│   ├── 02_mammal_ecoregions.R
│   ├── 03_data_preparation_models.R
│   └── 04_catboost_models.R
└── outputs/
```

---

## Setup

Install required R packages:

```r
source("requirements.R")
```

---

## Run the Pipeline

Execute the full workflow:

```r
source("run_pipeline.R")
```

---

## Pipeline Description

The analysis is organized as a sequential workflow:

### 0. Species Name Standardization

* Harmonization of taxonomic names across datasets

### 1. Richness Metrics Computation

* Absolute and relative richness of spiny-trunk species
* Aggregation by biome and ecoregion

### 2. Mammal Ecoregion Extraction

* Identification of ecoregions with highest relative trunk spine richness
* Stratification by continent

### 3. Data Preparation for Modeling

* Extraction of environmental predictors
* Integration of herbivory metrics
* Formatting of model-ready datasets

### 4. Machine Learning Models

Target variable: relative trunk spine richness

* Multivariate model:

  * Vegetation structure
  * Herbivory pressure

* Univariate models:

  * Monotonic model using mammal clade richness
  * Unconstrained model using mammal clade richness

---

## Data Description

The full dataset includes:

* Spiny-trunk species list (`.xlsx`)
* Raster layers of species richness (absolute and relative)
* Mammal clade richness layers
* Environmental predictor stacks

Example predictors:

| Variable          | Description                     |
| ----------------- | ------------------------------- |
| `cold_mean`       | Cold-season deciduousness index |
| `dry_mean`        | Dry-season deciduousness index  |
| `height`          | Vegetation height               |
| `vpi`             | Vegetation Productivity Index   |
| `consumption`     | Mammal herbivory pressure       |
| `mammal_richness` | Herbivorous mammal richness     |
| `trunkrichness`   | Target variable                 |

---

## Skills Demonstrated

* R programming for data science
* Geospatial data processing (`terra`, `sf`)
* Large-scale raster data handling
* Data cleaning and harmonization
* Feature engineering
* Machine learning (gradient boosting / CatBoost)
* Pipeline design and modular scripting
* Reproducible workflows

---

## Notes

* Raw data and large files are excluded from this repository
* The project structure is designed to be scalable and portable
* This repository focuses on workflow design and computational implementation

---

## References (Data Sources)

* Boonman et al. (2024) – Tree species distribution
* Cai et al. (2023) – Global plant diversity models
* Dinerstein et al. (2017) – Ecoregion classification
* Faurby et al. (2020) – Mammal distribution and traits
* Higgins et al. (2016) – Vegetation functional data

---
