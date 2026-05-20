\# Mathematical and Statistical Framework



This project implements a reproducible geospatial machine-learning pipeline for modelling the global distribution and ecological drivers of woody plant species with trunk spines.



The workflow combines spatial data engineering, biodiversity modelling, gradient-boosted decision trees, spatial cross-validation, bootstrap uncertainty estimation, and interpretable machine learning.



\## 1. Supervised learning formulation



Let \\(i = 1, \\dots, n\\) index spatial grid cells or spatial sampling units. For each unit, the response variable is



\\\[

y\_i \\in \\mathbb{R},

\\]



where \\(y\_i\\) denotes relative spiny-trunk richness.



Each spatial unit is associated with a vector of predictors



\\\[

\\mathbf{x}\_i =

(x\_{i1}, x\_{i2}, \\dots, x\_{ip})^\\top

\\in \\mathbb{R}^p,

\\]



including environmental, vegetation-structure, climatic, spatial, and herbivore-related covariates.



The modelling objective is to estimate an unknown nonlinear function



\\\[

f: \\mathbb{R}^p \\rightarrow \\mathbb{R}

\\]



such that



\\\[

y\_i = f(\\mathbf{x}\_i) + \\varepsilon\_i,

\\]



where \\(\\varepsilon\_i\\) is an error term representing unexplained ecological variation, measurement uncertainty, spatial mismatch, and unobserved historical processes.



The fitted model produces predictions



\\\[

\\hat{y}\_i = \\hat{f}(\\mathbf{x}\_i).

\\]



\## 2. Relative richness



Absolute spiny-trunk richness is sensitive to variation in total woody plant richness across regions. To control for this, the project uses relative richness:



\\\[

r\_i = \\frac{s\_i}{w\_i},

\\]



where \\(s\_i\\) is the number of spiny-trunk woody species in grid cell \\(i\\), and \\(w\_i\\) is the estimated total woody plant richness in that cell.



This normalization allows the analysis to distinguish areas where spiny-trunk species are unusually frequent relative to the background woody flora.



\## 3. Gradient-boosted decision trees



The main predictive model is based on gradient-boosted decision trees. The fitted function is represented as an additive ensemble:



\\\[

\\hat{f}(\\mathbf{x}) =

\\sum\_{m=1}^{M}

\\eta T\_m(\\mathbf{x}),

\\]



where:



\- \\(M\\) is the number of boosting iterations,

\- \\(\\eta\\) is the learning rate,

\- \\(T\_m(\\mathbf{x})\\) is the decision tree fitted at iteration \\(m\\).



At each boosting step, a new tree is added to reduce the empirical loss:



\\\[

\\mathcal{L}

=

\\sum\_{i=1}^{n}

\\ell(y\_i, \\hat{f}(\\mathbf{x}\_i)).

\\]



For regression, the squared-error loss can be written as



\\\[

\\ell(y\_i, \\hat{y}\_i)

=

(y\_i - \\hat{y}\_i)^2.

\\]



The residual for observation \\(i\\) is



\\\[

e\_i = y\_i - \\hat{y}\_i.

\\]



\## 4. Spatial cross-validation



Because geographically nearby observations are spatially autocorrelated, random train-test splitting can overestimate model performance. The project therefore uses spatial cross-validation.



Let the spatial domain be partitioned into \\(K\\) spatial folds:



\\\[

\\mathcal{D}

=

\\bigcup\_{k=1}^{K}

\\mathcal{D}\_k.

\\]



For validation fold \\(\\mathcal{D}\_k\\), the model is trained on



\\\[

\\mathcal{D}\_{-k}

=

\\mathcal{D}

\\setminus

\\mathcal{D}\_k.

\\]



The model is then evaluated on the spatially withheld fold \\(\\mathcal{D}\_k\\). This gives a more conservative estimate of predictive performance under spatial transfer.



\## 5. Model evaluation metrics



Predictive performance is evaluated using several complementary metrics.



The root mean squared error is



\\\[

RMSE

=

\\sqrt{

\\frac{1}{n}

\\sum\_{i=1}^{n}

(y\_i - \\hat{y}\_i)^2

}.

\\]



The mean absolute error is



\\\[

MAE

=

\\frac{1}{n}

\\sum\_{i=1}^{n}

|y\_i - \\hat{y}\_i|.

\\]



The coefficient of determination is



\\\[

R^2

=

1 -

\\frac{

\\sum\_{i=1}^{n}

(y\_i - \\hat{y}\_i)^2

}{

\\sum\_{i=1}^{n}

(y\_i - \\bar{y})^2

}.

\\]



These metrics are interpreted together because they capture different aspects of predictive error.



\## 6. Bootstrap uncertainty estimation



Bootstrap resampling is used to quantify uncertainty in model performance and predictor-response relationships.



Let \\(B\\) denote the number of bootstrap replicates. For replicate \\(b\\), a resampled dataset is drawn and a metric \\(\\theta\_b\\) is computed.



The bootstrap distribution is



\\\[

\\{\\theta\_1, \\theta\_2, \\dots, \\theta\_B\\}.

\\]



A percentile confidence interval is given by



\\\[

CI\_{95\\%}

=

\\left\[

Q\_{0.025}(\\theta\_b),

Q\_{0.975}(\\theta\_b)

\\right],

\\]



where \\(Q\_q\\) denotes the empirical quantile at probability \\(q\\).



\## 7. Partial dependence analysis



Partial dependence functions are used to interpret nonlinear predictor effects.



For predictor \\(x\_j\\), the partial dependence function is



\\\[

PD\_j(z)

=

\\frac{1}{n}

\\sum\_{i=1}^{n}

\\hat{f}

(z, \\mathbf{x}\_{i,-j}),

\\]



where \\(\\mathbf{x}\_{i,-j}\\) denotes all predictors except \\(x\_j\\), and \\(z\\) is a fixed value of the focal predictor.



This estimates the average model-predicted response as \\(x\_j\\) varies while the remaining predictors follow their empirical distribution.



\## 8. Monotonic clade models



To evaluate whether mammal clade richness is positively associated with relative spiny-trunk richness, the project uses univariate models with and without monotonic constraints.



For a mammal clade predictor \\(c\_i\\), the constrained model imposes



\\\[

\\frac{\\partial \\hat{f}(c\_i)}{\\partial c\_i} \\geq 0.

\\]



This forces the modelled relationship to be non-decreasing and allows the analysis to identify clades whose richness is positively associated with spiny-trunk richness.



A standardized slope is then used to compare positive associations across clades and continents:



\\\[

z\_i =

\\frac{c\_i - \\mu\_c}{\\sigma\_c}.

\\]



The fitted positive relationship can be summarized as



\\\[

\\hat{y}\_i = \\alpha + \\beta z\_i,

\\]



where larger positive values of \\(\\beta\\) indicate stronger positive association between mammal clade richness and relative spiny-trunk richness.



\## 9. Spatial residual diagnostics



Residuals are mapped geographically to identify spatial structure in model error:



\\\[

e\_i = y\_i - \\hat{y}\_i.

\\]



Spatially clustered residuals may indicate missing predictors, spatial non-stationarity, scale mismatch, historical contingency, or unresolved ecological mechanisms.



\## 10. Reproducibility



The project is structured as a reproducible computational pipeline. Dependencies are managed with `renv`, and the full workflow can be executed through `run\_pipeline.R`.



Heavy raw data and intermediate geospatial outputs are excluded from version control. Curated figures and methodological documentation are included in `docs/` to make the project interpretable from GitHub.

