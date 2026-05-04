# Geospatial Machine Learning Pipeline in R

> End-to-end geospatial machine learning pipeline integrating remote sensing, biodiversity, and environmental data.

This repository demonstrates a reproducible geospatial machine learning workflow in R. The pipeline operates on large-scale global raster datasets and integrates heterogeneous data sources with different spatial resolutions and formats.

The project is designed as a technical portfolio piece, showcasing skills in data engineering, spatial data processing, feature engineering, statistical modeling, and machine learning on complex datasets.

## Technical Overview

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

- Raster data: climate, vegetation productivity, canopy height
- Species distribution datasets: plants and mammals
- Remote sensing-derived environmental variables
- Derived metrics: herbivory pressure, richness indices
- Spatial harmonization to a common grid
- Raster stacking and alignment

## Machine Learning Task

Target variable: relative trunk spine richness.

Predictors include climate seasonality, vegetation structure, vegetation productivity, herbivory pressure, mammal richness, and consumption.

## Modeling Workflow

- Train/test split
- Spatial cross-validation with blockCV to account for spatial autocorrelation
- Randomized hyperparameter tuning
- Bootstrap evaluation
- RMSE and R2 metrics
- Partial dependence plots
- Model output persistence

## Constrained and Unconstrained Modeling

The project implements monotonic CatBoost models for univariate analyses of mammal clade richness.

Monotonic constraints enforce that predictions follow a consistent directional relationship with predictors. This supports domain-informed machine learning, reduces implausible model behavior, and improves interpretability.

Models are compared with and without constraints. Predictor effects are evaluated using partial dependence curves, bootstrap uncertainty intervals, and standardized slopes of predictor-response relationships.

## Example Outputs

- outputs/holdout_predictions.csv: model predictions and residuals
- outputs/observed_vs_predicted.png: model performance visualization
- outputs/pdp_*.png: partial dependence plots
- trained CatBoost models and performance summaries

## Repository Structure

- README.md
- requirements.R
- renv.lock
- run_pipeline.R
- R/config.R
- scripts/00_standardization.R
- scripts/01_biogeography_trunk.R
- scripts/02_mammal_ecoregions.R
- scripts/03_data_preparation_models.R
- scripts/04_catboost_models.R
- data/raw/
- data/processed/
- outputs/

Raw data and outputs are excluded from version control.

## Run the Pipeline

In R:

source('requirements.R')
source('run_pipeline.R')

From PowerShell:

& 'C:\Program Files\R\R-4.5.2\bin\Rscript.exe' -e "source('requirements.R'); source('run_pipeline.R')"

## Reproducibility

In R:

renv::restore()

Note: catboost may require manual installation depending on system configuration.

## Technical Skills Demonstrated

- R programming
- geospatial data engineering
- raster and vector data processing
- remote sensing data integration
- multi-source data harmonization
- feature engineering
- machine learning with CatBoost
- spatial cross-validation
- bootstrap uncertainty estimation
- model interpretability
- reproducible workflows with renv
- Git/GitHub version control
