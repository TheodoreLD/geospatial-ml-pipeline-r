# Geospatial Machine Learning Pipeline in R

This repository demonstrates a reproducible geospatial machine learning workflow in R.

The project integrates heterogeneous global datasets, including raster layers, satellite-derived vegetation variables, biodiversity data, mammal trait/distribution data, and derived environmental predictors. The goal of this repository is to showcase technical skills in data engineering, spatial data processing, feature engineering, statistical modeling, and machine learning on complex datasets.

---

## Technical Overview

This project implements an end-to-end geospatial data science pipeline involving:

- multi-source data integration
- raster and vector spatial processing
- species name standardization
- spatial feature engineering
- construction of model-ready datasets
- gradient boosting models with CatBoost
- spatial cross-validation
- bootstrap-based model evaluation
- interpretable machine learning outputs

The ecological question provides the case study, but the repository is primarily intended to demonstrate computational, statistical, and machine learning skills.

---

## Data Sources and Data Types

The workflow combines datasets with different origins, structures, and spatial resolutions.

### Main data types

- Raster data (`.tif`, GeoTIFF)
- Tabular data (`.csv`, `.xlsx`)
- Spatial vector data
- Species distribution data
- Satellite-derived vegetation products
- Derived environmental and biotic predictors

### Examples of integrated variables

| Category | Variables / Data |
|---|---|
| Climate seasonality | dry-season deciduousness, cold-season deciduousness |
| Vegetation structure | canopy height, vegetation productivity |
| Herbivory pressure | mammal richness, modeled plant consumption |
| Biodiversity metrics | absolute richness, relative richness, clade richness |
| Spatial units | global grid cells, biomes, ecoregions |

---

## Machine Learning Task

The target variable is:

```text
relative trunk spine richness