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

## Machine Learning Task

Target variable: relative trunk spine richness.

Predictors include:

- climate seasonality
- vegetation structure
- vegetation productivity
- herbivory pressure
- mammal richness and consumption metrics

## Skills Demonstrated

- R programming
- geospatial data engineering
- raster and vector data processing
- satellite-derived environmental variables
- biodiversity and trait data integration
- feature engineering
- machine learning with CatBoost
- spatial cross-validation
- bootstrap uncertainty estimation
- model interpretation
- reproducible workflow design
- Git/GitHub version control
- dependency management with renv

## Run the Pipeline

```r
source("requirements.R")
source("run_pipeline.R")
git status
