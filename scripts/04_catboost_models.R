# =============================================================================
# 04_catboost_models.R
# CatBoost modeling workflow for global and univariate geospatial models.
# =============================================================================

suppressPackageStartupMessages({
  library(terra)
  library(sf)
  library(blockCV)
  library(catboost)
  library(dplyr)
  library(tidyr)
  library(purrr)
  library(ggplot2)
  library(readr)
  library(forcats)
})

source("R/config.R")
create_project_dirs()
set.seed(123)

# ---- Helpers -----------------------------------------------------------------
rmse <- function(actual, predicted) sqrt(mean((actual - predicted)^2, na.rm = TRUE))
r_squared <- function(actual, predicted) {
  1 - sum((actual - predicted)^2, na.rm = TRUE) / sum((actual - mean(actual, na.rm = TRUE))^2, na.rm = TRUE)
}

make_catboost_pool <- function(df, predictors, target = NULL) {
  data_matrix <- as.matrix(df[, predictors, drop = FALSE])
  if (is.null(target)) {
    catboost.load_pool(data = data_matrix)
  } else {
    catboost.load_pool(data = data_matrix, label = df[[target]])
  }
}

random_param_grid <- function(n_iter = 50, monotonic = NULL) {
  replicate(n_iter, {
    params <- list(
      loss_function = "RMSE",
      eval_metric = "RMSE",
      depth = sample(3:8, 1),
      learning_rate = runif(1, 0.01, 0.10),
      subsample = runif(1, 0.55, 0.85),
      rsm = runif(1, 0.55, 0.85),
      iterations = sample(seq(300, 1000, by = 100), 1),
      leaf_estimation_iterations = sample(1:3, 1),
      l2_leaf_reg = sample(c(1, 3, 5, 7, 10), 1),
      od_pval = 1e-2,
      od_wait = 20,
      allow_writing_files = FALSE,
      verbose = FALSE
    )
    if (!is.null(monotonic)) params$monotone_constraints <- monotonic
    params
  }, simplify = FALSE)
}

spatial_cv_tune <- function(df_sf, predictors, target, param_grid, block_size = 500000, k = 5) {
  folds <- blockCV::cv_spatial(
    x = df_sf,
    size = block_size,
    k = k,
    selection = "random",
    iteration = 20,
    plot = FALSE,
    progress = FALSE
  )$folds_list

  purrr::map_dfr(param_grid, function(params) {
    fold_rmse <- purrr::map_dbl(folds, function(fold) {
      train_idx <- fold[[1]]
      test_idx <- fold[[2]]

      train_df <- sf::st_drop_geometry(df_sf[train_idx, ])
      test_df <- sf::st_drop_geometry(df_sf[test_idx, ])

      train_pool <- make_catboost_pool(train_df, predictors, target)
      test_pool <- make_catboost_pool(test_df, predictors, target)

      model <- catboost.train(train_pool, test_pool, params = params)
      predictions <- catboost.predict(model, test_pool)
      rmse(test_df[[target]], predictions)
    })

    tibble(params = list(params), rmse_cv = mean(fold_rmse, na.rm = TRUE))
  }) %>%
    arrange(rmse_cv) %>%
    slice(1)
}

bootstrap_model_metrics <- function(train_df, test_df, predictors, target, params, n_boot = 100) {
  test_pool <- make_catboost_pool(test_df, predictors)
  y_true <- test_df[[target]]

  purrr::map_dfr(seq_len(n_boot), function(i) {
    boot_idx <- sample(seq_len(nrow(train_df)), replace = TRUE)
    boot_train <- train_df[boot_idx, ]
    boot_pool <- make_catboost_pool(boot_train, predictors, target)
    model <- catboost.train(boot_pool, NULL, params = params)
    predictions <- catboost.predict(model, test_pool)

    tibble(
      bootstrap = i,
      rmse = rmse(y_true, predictions),
      r2 = r_squared(y_true, predictions)
    )
  })
}

bootstrap_pdp <- function(train_df, predictors, target, variable, params, n_grid = 100, n_boot = 100) {
  baseline <- train_df %>% summarise(across(all_of(predictors), ~ median(.x, na.rm = TRUE)))
  grid_x <- seq(min(train_df[[variable]], na.rm = TRUE), max(train_df[[variable]], na.rm = TRUE), length.out = n_grid)
  pred_mat <- matrix(NA_real_, nrow = n_grid, ncol = n_boot)

  for (i in seq_len(n_boot)) {
    boot_idx <- sample(seq_len(nrow(train_df)), replace = TRUE)
    boot_train <- train_df[boot_idx, ]
    boot_pool <- make_catboost_pool(boot_train, predictors, target)
    model <- catboost.train(boot_pool, NULL, params = params)

    grid_df <- baseline[rep(1, n_grid), ]
    grid_df[[variable]] <- grid_x
    grid_pool <- make_catboost_pool(grid_df, predictors)
    pred_mat[, i] <- catboost.predict(model, grid_pool)
  }

  tibble(
    x = grid_x,
    y = rowMeans(pred_mat, na.rm = TRUE),
    y_lo = apply(pred_mat, 1, quantile, 0.025, na.rm = TRUE),
    y_hi = apply(pred_mat, 1, quantile, 0.975, na.rm = TRUE)
  )
}

save_metric_summary <- function(metrics, output_path) {
  summary <- metrics %>%
    summarise(
      rmse_mean = mean(rmse, na.rm = TRUE),
      rmse_lower = quantile(rmse, 0.025, na.rm = TRUE),
      rmse_upper = quantile(rmse, 0.975, na.rm = TRUE),
      r2_mean = mean(r2, na.rm = TRUE),
      r2_lower = quantile(r2, 0.025, na.rm = TRUE),
      r2_upper = quantile(r2, 0.975, na.rm = TRUE)
    )
  readr::write_csv(summary, output_path)
  summary
}

run_global_model <- function() {
  message("Running Model 1: multivariate global drivers...")
  dir.create(paths$model1, recursive = TRUE, showWarnings = FALSE)

  predictor_stack_path <- require_file(file.path(paths$raster_model, "predictor_target_stack.tif"), "predictor stack")
  predictor_stack <- terra::rast(predictor_stack_path)

  df <- as.data.frame(predictor_stack, xy = TRUE, na.rm = TRUE) %>%
    rename(longitude = x, latitude = y)

  target <- "trunkrichness"
  predictors <- setdiff(names(df), c("longitude", "latitude", target))

  train_idx <- sample(seq_len(nrow(df)), size = floor(0.8 * nrow(df)))
  train_df <- df[train_idx, ]
  test_df <- df[-train_idx, ]

  train_sf <- sf::st_as_sf(train_df, coords = c("longitude", "latitude"), crs = 4326) %>%
    sf::st_transform(3857)

  param_grid <- random_param_grid(n_iter = 50)
  best <- spatial_cv_tune(train_sf, predictors, target, param_grid)
  best_params <- best$params[[1]]

  readr::write_csv(tibble(best_cv_rmse = best$rmse_cv), file.path(paths$model1, "best_cv_rmse.csv"))
  saveRDS(best_params, file.path(paths$model1, "best_params.rds"))

  metrics <- bootstrap_model_metrics(train_df, test_df, predictors, target, best_params, n_boot = 100)
  readr::write_csv(metrics, file.path(paths$model1, "bootstrap_metrics.csv"))
  metric_summary <- save_metric_summary(metrics, file.path(paths$model1, "bootstrap_metric_summary.csv"))

  train_pool <- make_catboost_pool(train_df, predictors, target)
  final_model <- catboost.train(train_pool, NULL, params = best_params)
  catboost.save_model(final_model, file.path(paths$model1, "catboost_global_model.cbm"))

  test_pool <- make_catboost_pool(test_df, predictors)
  predictions <- catboost.predict(final_model, test_pool)
  prediction_df <- test_df %>%
    select(longitude, latitude, all_of(target)) %>%
    mutate(prediction = predictions, residual = .data[[target]] - prediction)
  readr::write_csv(prediction_df, file.path(paths$model1, "holdout_predictions.csv"))

  obs_pred_plot <- ggplot(prediction_df, aes(x = trunkrichness, y = prediction)) +
    geom_point(alpha = 0.45) +
    geom_abline(slope = 1, intercept = 0, linetype = "dashed") +
    theme_minimal() +
    labs(
      title = "Observed vs predicted trunk richness",
      subtitle = sprintf("Holdout performance: RMSE = %.3f, R² = %.3f", metric_summary$rmse_mean, metric_summary$r2_mean),
      x = "Observed",
      y = "Predicted"
    )
  ggsave(file.path(paths$model1, "observed_vs_predicted.png"), obs_pred_plot, width = 6, height = 5, dpi = 300)

  for (variable in predictors) {
    pdp <- bootstrap_pdp(train_df, predictors, target, variable, best_params, n_grid = 100, n_boot = 100)
    readr::write_csv(pdp, file.path(paths$model1, paste0("pdp_", variable, ".csv")))

    pdp_plot <- ggplot(pdp, aes(x = x, y = y)) +
      geom_ribbon(aes(ymin = y_lo, ymax = y_hi), alpha = 0.25) +
      geom_line(linewidth = 1) +
      theme_minimal() +
      labs(title = paste("Partial dependence:", variable), x = variable, y = "Predicted trunk richness")
    ggsave(file.path(paths$model1, paste0("pdp_", variable, ".png")), pdp_plot, width = 6, height = 4, dpi = 300)
  }

  invisible(list(model = final_model, metrics = metric_summary))
}

extract_region_clade_data <- function() {
  predictor_stack <- terra::rast(require_file(file.path(paths$raster_model, "predictor_target_stack.tif"), "predictor stack"))
  clade_stack <- terra::rast(require_file(file.path(paths$raster_model, "mammal_clade_richness_stack.tif"), "mammal clade richness stack"))

  model_stack <- c(predictor_stack[["trunkrichness"]], clade_stack)
  names(model_stack) <- c("trunkrichness", names(clade_stack))

  regions <- list(
    Americas = terra::ext(-170, -30, -60, 80),
    Africa = terra::ext(-20, 55, -35, 37),
    Asia = terra::ext(25, 180, -10, 80)
  )

  df_list <- list()
  for (region_name in names(regions)) {
    cropped <- try(terra::crop(model_stack, regions[[region_name]]), silent = TRUE)
    if (inherits(cropped, "try-error")) next

    for (clade in names(clade_stack)) {
      subset_raster <- try(cropped[[c("trunkrichness", clade)]], silent = TRUE)
      if (inherits(subset_raster, "try-error")) next

      df <- as.data.frame(subset_raster, xy = TRUE, na.rm = TRUE)
      if (nrow(df) < 20 || length(unique(df[[clade]])) < 2) next

      df_list[[paste(region_name, clade, sep = "_")]] <- df %>%
        rename(longitude = x, latitude = y, predictor = all_of(clade))
    }
  }

  df_list
}

run_single_univariate <- function(df, params, n_boot = 100) {
  grid_x <- seq(min(df$predictor, na.rm = TRUE), max(df$predictor, na.rm = TRUE), length.out = 100)
  pdp_mat <- matrix(NA_real_, nrow = length(grid_x), ncol = n_boot)
  r2_values <- numeric(n_boot)
  slope_values <- numeric(n_boot)

  for (i in seq_len(n_boot)) {
    boot_idx <- sample(seq_len(nrow(df)), replace = TRUE)
    train_df <- df[boot_idx, ]
    oob_idx <- setdiff(seq_len(nrow(df)), unique(boot_idx))
    test_df <- if (length(oob_idx) > 2) df[oob_idx, ] else df

    model <- catboost.train(
      catboost.load_pool(as.matrix(train_df["predictor"]), label = train_df$trunkrichness),
      NULL,
      params = params
    )

    grid_df <- data.frame(predictor = grid_x)
    pdp_mat[, i] <- catboost.predict(model, catboost.load_pool(as.matrix(grid_df)))

    predictions <- catboost.predict(model, catboost.load_pool(as.matrix(test_df["predictor"])))
    r2_values[i] <- r_squared(test_df$trunkrichness, predictions)

    z_grid <- as.numeric(scale(grid_x))
    slope_values[i] <- coef(lm(pdp_mat[, i] ~ z_grid))[2]
  }

  list(
    pdp = tibble(
      x = grid_x,
      y = rowMeans(pdp_mat, na.rm = TRUE),
      y_lo = apply(pdp_mat, 1, quantile, 0.025, na.rm = TRUE),
      y_hi = apply(pdp_mat, 1, quantile, 0.975, na.rm = TRUE)
    ),
    metrics = tibble(
      r2 = mean(r2_values, na.rm = TRUE),
      r2_lower = quantile(r2_values, 0.025, na.rm = TRUE),
      r2_upper = quantile(r2_values, 0.975, na.rm = TRUE),
      slope_z = mean(slope_values, na.rm = TRUE),
      slope_z_lower = quantile(slope_values, 0.025, na.rm = TRUE),
      slope_z_upper = quantile(slope_values, 0.975, na.rm = TRUE)
    )
  )
}

run_univariate_models <- function(df_list, output_dir, monotonic = TRUE) {
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  params <- random_param_grid(n_iter = 1, monotonic = if (monotonic) "(1)" else NULL)[[1]]

  results <- purrr::imap(df_list, function(df, name) {
    parts <- strsplit(name, "_")[[1]]
    region <- parts[1]
    clade <- paste(parts[-1], collapse = "_")

    message("Running univariate model: ", region, " / ", clade)
    result <- run_single_univariate(df, params, n_boot = 100)

    result$pdp %>%
      mutate(region = region, clade = clade) -> pdp
    result$metrics %>%
      mutate(region = region, clade = clade) -> metrics

    list(pdp = pdp, metrics = metrics)
  })

  pdp_all <- bind_rows(map(results, "pdp"))
  metrics_all <- bind_rows(map(results, "metrics"))
  readr::write_csv(pdp_all, file.path(output_dir, "pdp_curves.csv"))
  readr::write_csv(metrics_all, file.path(output_dir, "model_metrics.csv"))

  r2_plot <- ggplot(metrics_all, aes(x = r2, y = forcats::fct_reorder(clade, r2), color = region)) +
    geom_vline(xintercept = 0, linetype = "dashed") +
    geom_errorbarh(aes(xmin = r2_lower, xmax = r2_upper), height = 0.2) +
    geom_point(size = 2.5) +
    facet_wrap(~ region, scales = "free_y") +
    theme_minimal() +
    labs(title = "Univariate model performance by clade and region", x = expression(R^2), y = "Mammal clade")
  ggsave(file.path(output_dir, "r2_by_clade_region.png"), r2_plot, width = 12, height = 7, dpi = 300)

  invisible(list(pdp = pdp_all, metrics = metrics_all))
}

# ---- Main --------------------------------------------------------------------
global_results <- run_global_model()
region_clade_data <- extract_region_clade_data()

message("Running Model 2: univariate monotonic clade models...")
run_univariate_models(region_clade_data, paths$model2, monotonic = TRUE)

message("Running Model 3: univariate unconstrained clade models...")
run_univariate_models(region_clade_data, paths$model3, monotonic = FALSE)

message("CatBoost modeling completed successfully.")
