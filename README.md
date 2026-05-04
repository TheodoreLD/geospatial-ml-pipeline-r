# Geospatial Machine Learning Pipeline in R

This repository demonstrates a reproducible geospatial machine learning workflow in R.

The project integrates heterogeneous global datasets, including raster layers, satellite-derived vegetation variables, biodiversity data, mammal trait/distribution data, and derived environmental predictors. The goal of this repository is to showcase technical skills in data engineering, spatial data processing, feature engineering, statistical modeling, and machine learning on complex datasets.

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

## Data and Feature Engineering

The pipeline integrates multiple data types:

- Raster data (GeoTIFF): climate, vegetation productivity, canopy height
- Species distribution datasets (plants and mammals)
- Remote sensing–derived variables
- Derived ecological metrics (herbivory pressure, richness indices)

All datasets are harmonized into a common spatial grid, enabling large-scale feature engineering.

## Machine Learning Task

Target variable: relative trunk spine richness.

Predictors include:

- climate seasonality (dry/cold indices)
- vegetation structure (height)
- vegetation productivity (VPI)
- herbivory pressure (consumption)
- mammal richness

## Modeling Workflow

- Train/test split
- Spatial cross-validation (blockCV)
- Hyperparameter tuning
- Bootstrap-based evaluation
- RMSE and R² metrics
- Partial dependence plots

## Constrained and Unconstrained Modeling

In addition to standard gradient boosting models, this project implements **monotonic CatBoost models** for univariate analyses of mammal clade richness.

### Motivation

Monotonic constraints enforce that model predictions follow a consistent directional relationship with predictors (e.g., increasing herbivory pressure should not decrease predicted response if theory suggests a positive relationship).

This approach allows:

- integration of domain knowledge into machine learning
- prevention of biologically implausible model behavior
- improved interpretability of predictor-response relationships

### Implementation

- Monotonic constraints are applied in CatBoost using the `monotone_constraints` parameter
- Models are trained with and without constraints for comparison

### Evaluation

Model performance and behavior are assessed using:

- Bootstrap resampling (100 iterations)
- Out-of-bag prediction for performance estimation
- R² metrics with confidence intervals
- Slope estimation of standardized partial dependence curves

### Predictor Importance

Instead of relying solely on feature importance scores, predictor effects are evaluated using:

- Partial dependence curves (PDPs)
- Bootstrap-derived confidence intervals
- Standardized slopes of predictor-response relationships

This provides a more robust interpretation of predictor influence, particularly under monotonic constraints.

## Outputs

The pipeline generates:

- model predictions (`outputs/`)
- performance metrics
- diagnostic plots
- trained CatBoost models

## Skills Demonstrated

- R programming
- geospatial data engineering
- raster and vector processing
- remote sensing data integration
- feature engineering
- machine learning (CatBoost)
- spatial cross-validation
- statistical evaluation
- reproducible workflows (`renv`)
- Git/GitHub workflow

## Run the Pipeline

```r
source("requirements.R")
source("run_pipeline.R")