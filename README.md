# Geospatial Machine Learning Pipeline in R

> End-to-end geospatial machine learning pipeline integrating remote sensing, biodiversity, environmental predictors, and machine learning.

This repository demonstrates a reproducible geospatial machine learning workflow in R. The pipeline operates on large-scale global raster datasets and integrates heterogeneous data sources with different spatial resolutions, formats, and semantic structures.

The project is designed as a technical portfolio piece, showcasing skills in data engineering, spatial data processing, feature engineering, statistical modeling, and machine learning on complex datasets.

---

## Technical Overview

This project implements an end-to-end geospatial data science pipeline involving:

- multi-source data integration  
- raster and vector spatial processing  
- species name standardization  
- spatial feature engineering  
- construction of model-ready datasets  
- gradient boosting models with CatBoost  
- monotonic and unconstrained model comparison  
- spatial cross-validation  
- bootstrap-based model evaluation  
- interpretable machine learning outputs  

The pipeline processes large-scale global raster datasets and uses memory-efficient spatial operations with `terra`.

---

## Data and Feature Engineering

The workflow integrates multiple data types:

- raster data: climate, vegetation productivity, canopy height  
- species distribution datasets: plants and mammals  
- remote sensing-derived environmental variables  
- mammal trait and distribution data  
- derived metrics: herbivory pressure, consumption, richness indices  

Feature construction includes:

- spatial harmonization to a common grid  
- raster stacking and alignment  
- extraction of predictors per grid cell  
- construction of relative richness metrics  
- integration of environmental, vegetation, and biotic predictors  
- conversion of spatial rasters into model-ready tabular data  

---

## Machine Learning Task

**Target variable:** relative trunk spine richness  

Predictors include:

- climate seasonality  
- vegetation structure  
- vegetation productivity  
- herbivory pressure  
- mammal richness  
- modeled plant consumption  

The main multivariate model evaluates climate, vegetation, and herbivory-related predictors together. Additional univariate models evaluate mammal clade richness under constrained and unconstrained assumptions.

---

## Modeling Workflow

The modeling workflow includes:

- train/test split  
- spatial cross-validation with `blockCV` to account for spatial autocorrelation and prevent overly optimistic model performance  
- randomized hyperparameter tuning  
- CatBoost regression  
- bootstrap-based evaluation  
- RMSE and R² metrics  
- partial dependence plots  
- saved predictions, metrics, plots, and model objects  

---

## Constrained and Unconstrained Modeling

The project implements monotonic CatBoost models for univariate analyses of mammal clade richness.

Monotonic constraints enforce that predictions follow a consistent directional relationship with predictors. This supports domain-informed machine learning, reduces implausible model behavior, and improves interpretability.

Models are compared with and without constraints:

- unconstrained models capture full response shapes  
- monotonic models enforce directional relationships  
- predictor effects are evaluated using partial dependence curves  
- uncertainty is estimated with bootstrap intervals  
- predictor importance is summarized using standardized slopes  

---

## Example Outputs

The pipeline generates:

- `outputs/holdout_predictions.csv` — model predictions and residuals  
- `outputs/observed_vs_predicted.png` — model performance visualization  
- `outputs/pdp_*.png` — partial dependence plots  
- trained CatBoost models  
- performance summaries  
- processed model-ready datasets  

Raw data and outputs are excluded from version control.

---

## Repository Structure
