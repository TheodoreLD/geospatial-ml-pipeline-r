# Geospatial Machine Learning Pipeline in R

> End-to-end geospatial machine learning pipeline integrating remote sensing, biodiversity, and environmental data.

This repository demonstrates a reproducible geospatial machine learning workflow in R. The pipeline operates on large-scale global raster datasets and integrates heterogeneous data sources with different spatial resolutions and formats.

The project is designed as a **technical portfolio piece**, showcasing skills in data engineering, spatial data processing, feature engineering, statistical modeling, and machine learning on complex datasets.

---

## Technical Overview

This project implements an end-to-end pipeline including:

- multi-source data integration
- raster and vector spatial processing
- species name standardization
- spatial feature engineering
- construction of model-ready datasets
- gradient boosting models (CatBoost)
- spatial cross-validation
- bootstrap-based model evaluation
- interpretable machine learning outputs

---

## Data and Feature Engineering

The pipeline integrates multiple large-scale datasets with different structures:

### Data types

- Raster data (GeoTIFF): climate, vegetation productivity, canopy height
- Species distribution datasets (plants and mammals)
- Remote sensing–derived environmental variables
- Derived ecological metrics (herbivory pressure, richness indices)

### Feature construction

- Spatial harmonization to a common grid
- Raster stacking and alignment
- Derived predictors:
  - climate seasonality indices (dry/cold)
  - vegetation productivity (VPI)
  - vegetation structure (height)
  - herbivory pressure (consumption, mammal richness)

### Target variable

```text
relative trunk spine richness