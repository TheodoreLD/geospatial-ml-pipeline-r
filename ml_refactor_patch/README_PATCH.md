Add this under the README setup section:

## Model Outputs

The modeling step writes outputs to:

```text
outputs/models/
├── model1_global_drivers/
│   ├── best_cv_rmse.csv
│   ├── bootstrap_metrics.csv
│   ├── bootstrap_metric_summary.csv
│   ├── catboost_global_model.cbm
│   ├── holdout_predictions.csv
│   └── observed_vs_predicted.png
├── model2_univariate_monotonic/
│   ├── model_metrics.csv
│   ├── pdp_curves.csv
│   └── r2_by_clade_region.png
└── model3_univariate_unconstrained/
    ├── model_metrics.csv
    ├── pdp_curves.csv
    └── r2_by_clade_region.png
```

Note: `catboost` may require manual installation depending on the operating system and R version.
