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
- plant range/distribution data,
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

Let \(i = 1, \dots, n\) index spatial grid cells.

The response variable is the relative richness of woody species with trunk spines:

\[
y_i \in \mathbb{R}_{\geq 0}.
\]

In the code, this response is stored as `trunkrichness`.

Let

\[
\mathbf{y}
=
(y_1,\dots,y_n)^\top
\in \mathbb{R}^{n}
\]

denote the response vector, and let

\[
\mathbf{X}
=
[x_{ij}]
\in \mathbb{R}^{n \times p}
\]

denote the multivariate predictor matrix.

The general supervised-learning problem is written as

\[
y_i = f(\mathbf{x}_i) + \varepsilon_i,
\qquad
i = 1,\dots,n,
\]

where

\[
\mathbf{x}_i^\top
\]

is the \(i\)-th row of \(\mathbf{X}\), \(f\) is an unknown nonlinear response function, and \(\varepsilon_i\) is a residual term representing unexplained ecological variation, spatial mismatch, measurement uncertainty, and unresolved historical processes.

---

## Model 1: Multivariate Environmental and Herbivory Model

The first model estimates the nonlinear relationship between relative spiny-trunk richness and a multivariate set of environmental, vegetation-structure, and herbivory-related predictors.

The predictor matrix for Model 1 is

\[
\mathbf{X}^{(1)}
=
\begin{bmatrix}
x^{(1)}_{11} & x^{(1)}_{12} & \cdots & x^{(1)}_{1p} \\
x^{(1)}_{21} & x^{(1)}_{22} & \cdots & x^{(1)}_{2p} \\
\vdots       & \vdots       & \ddots & \vdots       \\
x^{(1)}_{n1} & x^{(1)}_{n2} & \cdots & x^{(1)}_{np}
\end{bmatrix},
\]

with

\[
p = 6.
\]

In the implementation, the six predictors are:

\[
\mathcal{P}^{(1)}
=
\{
\texttt{vpi\_mean},
\texttt{cold\_mean},
\texttt{dry\_mean},
\texttt{height},
\texttt{mammal\_richness},
\texttt{consumption}
\}.
\]

The model is

\[
y_i = f_1(\mathbf{x}^{(1)}_i) + \varepsilon_i.
\]

The function \(f_1\) is estimated using CatBoost gradient-boosted regression trees. The fitted function is an additive ensemble:

\[
\hat{f}_1(\mathbf{x})
=
\sum_{m=1}^{M}
\eta T_m(\mathbf{x}),
\]

where \(T_m\) is the regression tree fitted at boosting iteration \(m\), \(M\) is the number of boosting iterations, and \(\eta\) is the learning rate.

The empirical loss minimized during regression is based on squared prediction error:

\[
\mathcal{L}
=
\sum_{i=1}^{n}
\left(
y_i - \hat{f}_1(\mathbf{x}^{(1)}_i)
\right)^2.
\]

Model performance is evaluated using root mean squared error:

\[
\operatorname{RMSE}
=
\left[
\frac{1}{n}
\sum_{i=1}^{n}
\left(
y_i - \hat{y}_i
\right)^2
\right]^{1/2},
\]

and the coefficient of determination:

\[
R^2
=
1
-
\frac{
\sum_{i=1}^{n}
\left(
y_i - \hat{y}_i
\right)^2
}{
\sum_{i=1}^{n}
\left(
y_i - \bar{y}
\right)^2
}.
\]

---

## Spatial Cross-Validation

Because neighbouring grid cells are spatially autocorrelated, random cross-validation may produce overly optimistic estimates of predictive performance.

The spatial domain is partitioned into \(K\) spatially explicit folds:

\[
\mathcal{D}
=
\bigcup_{k=1}^{K}
\mathcal{D}_k,
\qquad
\mathcal{D}_j \cap \mathcal{D}_k = \varnothing
\quad
\text{for } j \neq k.
\]

For fold \(k\), the training set is

\[
\mathcal{D}_{-k}
=
\mathcal{D}
\setminus
\mathcal{D}_k,
\]

and the validation set is \(\mathcal{D}_k\).

For a candidate hyperparameter configuration \(\lambda\), the spatial cross-validation criterion is

\[
\operatorname{CV}(\lambda)
=
\frac{1}{K}
\sum_{k=1}^{K}
\operatorname{RMSE}
\left(
\mathcal{D}_k,
\hat{f}_{1,\lambda}^{(-k)}
\right),
\]

where \(\hat{f}_{1,\lambda}^{(-k)}\) is fitted on \(\mathcal{D}_{-k}\).

The selected configuration is

\[
\hat{\lambda}
=
\arg\min_{\lambda \in \Lambda}
\operatorname{CV}(\lambda).
\]

In the implementation, hyperparameters are sampled randomly and evaluated with spatial cross-validation.

---

## Bootstrap Evaluation

After hyperparameter tuning, Model 1 is evaluated using bootstrap resampling.

For bootstrap replicate \(b = 1,\dots,B\), a resampled training set is drawn:

\[
\mathcal{D}^{\ast}_b
=
\left\{
(\mathbf{x}^{\ast}_{1b}, y^{\ast}_{1b}),
\dots,
(\mathbf{x}^{\ast}_{nb}, y^{\ast}_{nb})
\right\}.
\]

A model \(\hat{f}^{\ast}_{1b}\) is fitted on \(\mathcal{D}^{\ast}_b\) and evaluated on the held-out test set.

This gives bootstrap estimates

\[
\theta^{\ast}_1,\dots,\theta^{\ast}_B,
\]

where \(\theta\) may be \(R^2\) or RMSE.

The bootstrap mean is

\[
\bar{\theta}^{\ast}
=
\frac{1}{B}
\sum_{b=1}^{B}
\theta^{\ast}_b,
\]

and percentile confidence intervals are estimated as

\[
\left[
Q_{0.025}(\theta^{\ast}),
Q_{0.975}(\theta^{\ast})
\right].
\]

---

## Partial Dependence

For Model 1, predictor effects are summarized using partial dependence functions.

For predictor \(j\), the partial dependence function is

\[
PD_j(z)
=
\frac{1}{n}
\sum_{i=1}^{n}
\hat{f}_1
\left(
z,
\mathbf{x}_{i,-j}
\right),
\]

where \(z\) is a fixed value of predictor \(j\), and \(\mathbf{x}_{i,-j}\) denotes all predictors except \(j\).

Bootstrap partial dependence intervals are estimated by computing \(PD_j^{\ast b}(z)\) across bootstrap-fitted models:

\[
\widehat{PD}_j(z)
=
\frac{1}{B}
\sum_{b=1}^{B}
PD_j^{\ast b}(z),
\]

with uncertainty summarized by empirical quantiles across bootstrap replicates.

---

## Model 2: Monotonic Mammal-Clade Models

The second modelling component evaluates positive associations between mammal clade richness and relative spiny-trunk richness.

Let

\[
r \in \mathcal{R}
\]

index broad geographic regions, and let

\[
c \in \mathcal{C}
\]

index mammal clades.

For each region-clade pair \((r,c)\), the model uses one predictor:

\[
z^{(c,r)}_i
\in \mathbb{R}_{\geq 0},
\]

representing the richness of mammal clade \(c\) in grid cell \(i\) within region \(r\).

The univariate model is

\[
y^{(r)}_i
=
f^{+}_{c,r}
\left(
z^{(c,r)}_i
\right)
+
\varepsilon^{(r)}_i.
\]

The superscript \(+\) indicates that the fitted function is constrained to be monotonic non-decreasing:

\[
\frac{\partial f^{+}_{c,r}(z)}{\partial z}
\geq
0
\qquad
\forall z.
\]

This constraint represents the directional biological hypothesis that, if a mammal clade is a plausible positive driver of spiny-trunk richness, increasing clade richness should not reduce predicted spiny-trunk richness.

For each fitted monotonic curve, the predictor is standardized as

\[
\tilde{z}^{(c,r)}_i
=
\frac{
z^{(c,r)}_i
-
\mu_{c,r}
}{
\sigma_{c,r}
},
\]

and the modelled relationship is summarized using the slope

\[
\beta_{c,r}
=
\frac{
\operatorname{Cov}
\left(
\tilde{z}^{(c,r)},
\hat{f}^{+}_{c,r}(z^{(c,r)})
\right)
}{
\operatorname{Var}
\left(
\tilde{z}^{(c,r)}
\right)
}.
\]

Larger positive values of \(\beta_{c,r}\) indicate stronger positive association between mammal clade richness and relative spiny-trunk richness.

---

## Model 3: Unconstrained Mammal-Clade Models

The third modelling component uses the same region-by-clade structure but removes the monotonic constraint.

For each region-clade pair \((r,c)\), the model is

\[
y^{(r)}_i
=
g_{c,r}
\left(
z^{(c,r)}_i
\right)
+
\varepsilon^{(r)}_i,
\]

where \(g_{c,r}\) is estimated without imposing

\[
\frac{\partial g_{c,r}(z)}{\partial z}
\geq
0.
\]

These unconstrained models are used to visualize the empirical form of each clade-richness relationship without enforcing a directional assumption.

Together, Models 2 and 3 separate two questions:

\[
\text{directional association}
\quad
\text{vs.}
\quad
\text{empirical response shape}.
\]

Model 2 asks whether a clade is positively associated with spiny-trunk richness under a monotonic hypothesis. Model 3 asks whether the observed relationship is nonlinear, saturating, threshold-like, or non-monotonic.

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