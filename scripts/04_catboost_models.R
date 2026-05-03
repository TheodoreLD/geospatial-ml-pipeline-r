#===============================================================================
# Global & Univariate Modeling Pipeline for Trunk Richness
#===============================================================================

# 0. Setup ---------------------------------------------------------------------
set.seed(123)

# 0.1 Libraries ----------------------------------------------------------------
library(terra)       # raster I/O & geoprocessing
library(sf)          # spatial data frames
library(blockCV)     # spatial cross-validation
library(catboost)    # gradient boosting
library(dplyr)       # data wrangling
library(tidyr)       # data tidying
library(purrr)       # mapping functions
library(ggplot2)     # plotting
library(readr)       # CSV I/O
library(viridis)     # color palettes
library(forcats)     # factor reordering

# 0.2 Paths --------------------------------------------------------------------
project_dir    <- ""
data_dir       <- file.path(project_dir, "Data")
drivers_plot_dir <- file.path(project_dir, "output", "Models", "Model1", "Plots")

#===============================================================================
# 1. Helper Functions ----------------------------------------------------------
#===============================================================================

# 1.1 Spatial CV tuner ---------------------------------------------------------
tune_spatial_cv <- function(df_sf, predictors, target, param_list,
                            block_size = 500e3, k = 5) {
  folds <- cv_spatial(
    x         = df_sf,
    size      = block_size,
    k         = k,
    selection = "random",
    iteration = 20,
    plot      = FALSE
  )$folds_list
  
  map_dfr(param_list, ~{
    par <- .x
    rmses <- map_dbl(folds, ~{
      tr_i <- .x[[1]]; te_i <- .x[[2]]
      tr <- st_drop_geometry(df_sf[tr_i, ])
      te <- st_drop_geometry(df_sf[te_i, ])
      pool_tr <- catboost.load_pool(
        data  = as.matrix(tr[, predictors]),
        label = tr[[target]]
      )
      pool_te <- catboost.load_pool(
        data  = as.matrix(te[, predictors]),
        label = te[[target]]
      )
      m <- catboost.train(pool_tr, pool_te, params = par)
      preds <- catboost.predict(m, pool_te)
      sqrt(mean((te[[target]] - preds)^2))
    })
    tibble(params = list(par), rmse_cv = mean(rmses, na.rm = TRUE))
  }) %>%
    arrange(rmse_cv) %>%
    slice(1)
}

# 1.2 Bootstrap R2 -------------------------------------------------------------
bootstrap_global <- function(train_df, test_df, predictors, target,
                             params, n_boot = 100) {
  set.seed(42)
  r2_boot <- numeric(n_boot)
  y_true  <- test_df[[target]]
  for(b in seq_len(n_boot)) {
    idx_b <- sample(nrow(train_df), replace = TRUE)
    pool_b <- catboost.load_pool(
      as.matrix(train_df[idx_b, predictors]),
      label = train_df[idx_b, target]
    )
    m_b <- catboost.train(pool_b, NULL, params = params)
    pool_te <- catboost.load_pool(as.matrix(test_df[, predictors]))
    pred_base <- catboost.predict(m_b, pool_te)
    r2_b <- 1 - sum((y_true - pred_base)^2) / sum((y_true - mean(y_true))^2)
    r2_boot[b] <- r2_b
  }
  list(r2_boot = r2_boot)
}

# 1.3 Bootstrapped Partial Dependence ------------------------------------------
bootstrap_pdp <- function(train_df, predictors, target, var,
                          params, n_grid = 100, n_boot = 100) {
  med <- train_df %>% summarise(across(all_of(predictors), \(x) median(x, na.rm = TRUE)))
  grid_x <- seq(
    min(train_df[[var]], na.rm = TRUE),
    max(train_df[[var]], na.rm = TRUE),
    length.out = n_grid
  )
  pred_mat <- matrix(NA_real_, nrow = n_grid, ncol = n_boot)
  for(b in seq_len(n_boot)) {
    idx_b <- sample(nrow(train_df), replace = TRUE)
    pool_b <- catboost.load_pool(
      as.matrix(train_df[idx_b, predictors]),
      label = train_df[idx_b, target]
    )
    m_b <- catboost.train(pool_b, NULL, params = params)
    grid_df <- med[rep(1, n_grid), ]
    grid_df[[var]] <- grid_x
    pool_g <- catboost.load_pool(as.matrix(grid_df[, predictors]))
    pred_mat[, b] <- catboost.predict(m_b, pool_g)
  }
  tibble(
    x    = grid_x,
    y    = rowMeans(pred_mat, na.rm = TRUE),
    y_lo = apply(pred_mat, 1, quantile, 0.025, na.rm = TRUE),
    y_hi = apply(pred_mat, 1, quantile, 0.975, na.rm = TRUE)
  )
}

# 1.4 Helper: Hyperparameter grid for univariate models ------------------------
get_param_grid <- function(monotonic = TRUE, n_iter = 100) {
  base_grid <- list(
    loss_function = "RMSE",
    eval_metric   = "RMSE",
    depth         = sample(1:10,1),
    learning_rate = runif(1,0.01,0.1),
    subsample     = runif(1,0.5,0.8),
    rsm           = runif(1,0.5,0.8),
    iterations    = sample(200:1000,1),
    leaf_estimation_iterations = sample(1:3,1),
    l2_leaf_reg   = sample(c(1,3,5,7,10),1),
    od_pval       = 1e-2,
    od_wait       = 20,
    allow_writing_files = FALSE
  )
  if (monotonic) {
    base_grid$monotone_constraints <- "(1)"
  }
  replicate(n_iter, base_grid, simplify = FALSE)
}

# 1.5 Helper: Tuning function for univariate models ----------------------------
tune_uni <- function(df0, param_grid) {
  train_idx <- sample(nrow(df0), 0.8 * nrow(df0))
  train0 <- df0[train_idx, ]; test0 <- df0[-train_idx, ]
  sf_tr <- st_as_sf(train0, coords = c("longitude","latitude"), crs = 4326) %>%
    st_transform(3857)
  best <- tune_spatial_cv(sf_tr, "predictor", "trunkrichness", param_grid)
  list(best_params = best$params[[1]], rmse = best$rmse_cv)
}

# 1.6 Helper: Main univariate modeling pipeline --------------------------------
run_univariate_model <- function(df_list, param_grid, out_dir, plots_dir, plot_slopes = FALSE) {
  n_iter_uni <- length(param_grid)
  results_uni <- imap(df_list, function(df0, name) {
    parts <- strsplit(name, "_")[[1]]
    region <- parts[1]; clade <- parts[2]
    # Tune
    tune <- tune_uni(df0, param_grid)
    params <- tune$best_params
    # Prepare grid for PDP
    grid_x <- seq(min(df0$predictor, na.rm=TRUE), max(df0$predictor, na.rm=TRUE), length.out = 100)
    med <- df0 %>% summarise(across(c("trunkrichness","predictor"), median, na.rm = TRUE))
    pdp_mat <- matrix(NA, nrow = 100, ncol = n_iter_uni)
    slopes <- numeric(n_iter_uni)
    r2s    <- numeric(n_iter_uni)
    set.seed(42)
    for (b in seq_len(n_iter_uni)) {
      idx_b <- sample(nrow(df0), replace = TRUE)
      tr_b <- df0[idx_b, ]
      oob_idx <- setdiff(seq_len(nrow(df0)), unique(idx_b))
      te_b <- if(length(oob_idx)>0) df0[oob_idx, ] else tr_b
      # Train
      pool_b <- catboost.load_pool(as.matrix(tr_b["predictor"]), label = tr_b$trunkrichness)
      m_b <- catboost.train(pool_b, NULL, params = params)
      # PDP
      grid_df <- med[rep(1,100), ]; grid_df$predictor <- grid_x
      pdp_mat[,b] <- catboost.predict(m_b, catboost.load_pool(as.matrix(grid_df["predictor"])))
      # Slope z (standardized grid)
      zx <- (grid_x - mean(df0$predictor, na.rm=TRUE))/sd(df0$predictor, na.rm=TRUE)
      slopes[b] <- coef(lm(pdp_mat[,b] ~ zx))[2]
      # R2
      pred_oob <- catboost.predict(m_b, catboost.load_pool(as.matrix(te_b["predictor"])))
      r2s[b] <- if(nrow(te_b)>2) 1 - sum((te_b$trunkrichness - pred_oob)^2) / sum((te_b$trunkrichness - mean(te_b$trunkrichness))^2) else NA
    }
    list(
      region = region,
      clade = clade,
      overlay = tibble(
        x = grid_x,
        y = rowMeans(pdp_mat, na.rm = TRUE),
        y_lo = apply(pdp_mat,1,quantile,0.025,na.rm=TRUE),
        y_hi = apply(pdp_mat,1,quantile,0.975,na.rm=TRUE),
        region = region, clade = clade
      ),
      metrics = if (plot_slopes) {
        tibble(
          region = region,
          clade = clade,
          slope_z = mean(slopes, na.rm = TRUE),
          slope_z_lo = quantile(slopes,0.025,na.rm=TRUE),
          slope_z_hi = quantile(slopes,0.975,na.rm=TRUE),
          R2 = mean(r2s, na.rm=TRUE),
          R2_lo = quantile(r2s,0.025,na.rm=TRUE),
          R2_hi = quantile(r2s,0.975,na.rm=TRUE)
        )
      } else {
        tibble(
          region = region,
          clade = clade,
          R2 = mean(r2s, na.rm=TRUE),
          R2_lo = quantile(r2s,0.025,na.rm=TRUE),
          R2_hi = quantile(r2s,0.975,na.rm=TRUE)
        )
      }
    )
  })
  overlays <- bind_rows(map(results_uni, "overlay"))
  metrics  <- bind_rows(map(results_uni, "metrics"))
  write_csv(metrics, file.path(out_dir, "univariate_metrics.csv"))
  
  # --- Global y-limits for overlay plots (all clades/regions on same scale) ---
  y_limits <- range(c(overlays$y_lo, overlays$y_hi), na.rm = TRUE)
  
  # Plot R2 by clade
  p_r2 <- ggplot(metrics, aes(x = R2, y = fct_reorder(clade, R2), color = region)) +
    geom_vline(xintercept = 0, linetype = "dashed", color = "grey80") +
    geom_errorbarh(aes(xmin = R2_lo, xmax = R2_hi), height = 0.2) +
    geom_point(size = 3) +
    facet_wrap(~region, scales = "free_x") +
    theme_minimal() +
    labs(title = "Global R² (95% CI) by Clade & Region", x = expression(R^2), y = "Clade")
  ggsave(file.path(plots_dir, "r2_univariate.png"), p_r2, width = 12, height = 6, dpi = 300)
  ggsave(file.path(plots_dir, "r2_univariate.pdf"), p_r2, width = 12, height = 6, dpi = 300)
  # Plot slopes, if needed (for monotonic model)
  if (plot_slopes) {
    p_slopes <- ggplot(metrics, aes(x = slope_z, y = fct_reorder(clade, slope_z), color = region)) +
      geom_vline(xintercept = 0, linetype = "dashed", color = "grey80") +
      geom_errorbarh(aes(xmin = slope_z_lo, xmax = slope_z_hi), height = 0.2) +
      geom_point(size = 3) +
      facet_wrap(~region, scales = "free_x") +
      theme_minimal() +
      labs(title = "Standardized PDP Slopes (95% CI)")
    ggsave(file.path(plots_dir, "pdp_slopes_univariate.png"), p_slopes, width = 12, height = 6, dpi = 300)
  }
  # Plot overlays by clade (all with same y-axis)
  for (cl in unique(metrics$clade)) {
    dat <- filter(overlays, clade == cl)
    p <- ggplot(dat, aes(x = x, y = y, color = region, fill = region)) +
      geom_ribbon(aes(ymin = y_lo, ymax = y_hi), alpha = 0.3) +
      geom_line(size = 1)
    if (plot_slopes) {
      p <- p + geom_smooth(aes(y = y), method = "lm", se = FALSE, linetype = "dashed")
    }
    p <- p +
      coord_cartesian(ylim = y_limits) +
      theme_minimal() +
      labs(
        title = paste(cl, "→ Trunk richness"),
        x = paste(cl, "richness"),
        y = "Predicted trunk richness",
        caption = sprintf("Slope_z (95%% CI): %s",
                          paste0(metrics$region[metrics$clade==cl], ": ",
                                 sprintf("%.3f [%.3f,%.3f]", metrics$slope_z[metrics$clade==cl],
                                         metrics$slope_z_lo[metrics$clade==cl],
                                         metrics$slope_z_hi[metrics$clade==cl]),
                                 collapse = "; "))
      )
    ggsave(file.path(plots_dir, paste0(cl, "_pdp_overlay.png")), p, width = 8, height = 6, dpi = 300)
    ggsave(file.path(plots_dir, paste0(cl, "_pdp_overlay.pdf")), p, width = 8, height = 6, dpi = 300)
  }
  invisible(list(metrics=metrics, overlays=overlays))
}

#===============================================================================
# 2. Multivariate Modeling — Global Drivers ------------------------------------
#===============================================================================

# 2.1 Load predictor stack
pred_stack <- rast(file.path(project_dir, "output", "Raster_model", "Predictor__target_stack.tif"))
names(pred_stack) <- c(
  "trunkrichness", "vpi_mean", "cold_mean", "dry_mean",
  "height", "mammal_richness", "consumption"
)
df <- as.data.frame(pred_stack, xy = TRUE, na.rm = TRUE)
names(df)[1:2] <- c("longitude","latitude")
target <- "trunkrichness"
predictors <- setdiff(names(df), c("longitude","latitude", target))

# 2.2 Train/test split
train_idx <- sample(nrow(df), 0.8 * nrow(df))
train_df  <- df[train_idx, ]
test_df   <- df[-train_idx, ]

# 2.3 Spatial CV tuning
train_sf <- st_as_sf(train_df, coords = c("longitude","latitude"), crs = 4326) %>%
  st_transform(3857)
param_list <- replicate(100, list(
  loss_function = "RMSE",
  eval_metric   = "RMSE",
  depth         = sample(1:10,1),
  learning_rate = runif(1,0.01,0.1),
  subsample     = runif(1,0.5,0.8),
  rsm           = runif(1,0.5,0.8),
  iterations    = sample(200:1000,1),
  leaf_estimation_iterations = sample(1:3,1),
  l2_leaf_reg   = sample(c(1,3,5,7),1),
  od_pval       = 1e-2,
  od_wait       = 20,
  allow_writing_files = FALSE
), simplify = FALSE)
best_res <- tune_spatial_cv(train_sf, predictors, target, param_list)
best_params <- best_res$params[[1]]
message("Best CV RMSE: ", round(best_res$rmse_cv,3))

# 2.4 Bootstrap global
boot_res <- bootstrap_global(train_df, test_df, predictors, target,
                             best_params, n_boot = 100)
dr2 <- boot_res$r2_boot
df_r2 <- tibble(boot=seq_along(dr2), R2=dr2)
mean_r2 <- mean(dr2, na.rm=TRUE)
ci_r2   <- quantile(dr2, c(0.025,0.975), na.rm=TRUE)
write_csv(df_r2, file.path(drivers_plot_dir, "bootstrap_r2.csv"))
write_csv(
  tibble(metric="R2", mean=mean_r2, lower=ci_r2[1], upper=ci_r2[2]),
  file.path(drivers_plot_dir, "bootstrap_r2_summary.csv")
)

# 2.5 Diagnostic plots
train_pool <- catboost.load_pool(as.matrix(train_df[, predictors]), label=train_df[[target]])
final_model <- catboost.train(train_pool, NULL, params=best_params)
obs_df <- tibble(
  obs = test_df[[target]],
  pred = catboost.predict(final_model, catboost.load_pool(as.matrix(test_df[, predictors])))
)
p1 <- ggplot(obs_df, aes(obs,pred)) +
  geom_point(alpha=0.5) +
  geom_abline(slope=1, intercept=0, linetype="dashed", color="red") +
  theme_minimal() +
  labs(title="Obs vs Pred (holdout)")
ggsave(file.path(drivers_plot_dir, "obs_vs_pred.png"), p1, width=6, height=5, dpi=300)

# 2.6 Global PDPs
for (v in predictors) {
  pdp_df <- bootstrap_pdp(train_df, predictors, target, v,
                          best_params, n_grid = 100, n_boot = 100)
  p <- ggplot(pdp_df, aes(x = x)) +
    geom_ribbon(aes(ymin = y_lo, ymax = y_hi), alpha = 0.3) +
    geom_line(aes(y = y), size = 1) +
    labs(title = paste("PDP –", v), x = v,
         y = "Predicted trunk richness") +
    theme_minimal()
  
  ggsave(file.path(drivers_plot_dir, paste0("PDP_", v, ".png")), p,
         width = 6, height = 4, dpi = 300)
}

#===============================================================================
# 3. Univariate Modeling: Trunk Richness vs. Clade Richness --------------------
#     Runs Both: With (Monotonic) and Without (Unconstrained)
#===============================================================================

# -- Output directories for each mode --
dir_monotonic <- file.path(project_dir, "output", "Models", "Model2", "Univariate_Monotonic")
dir_unconstr  <- file.path(project_dir, "output", "Models", "Model2", "Univariate_Unconstrained")
plots_monotonic <- file.path(dir_monotonic, "Plots")
plots_unconstr  <- file.path(dir_unconstr,  "Plots")

# -- Load stacks & region-clade data extraction --
predictor_stack_fp <- file.path(project_dir, "output", "Raster_model", "predictor_stack.tif")
clade_stack_fp     <- file.path(project_dir, "output", "Raster_model", "clade_richness_stack.tif")
pred_stack  <- rast(predictor_stack_fp)
trunk_rich  <- pred_stack[["trunkrichness"]]
clade_stack <- rast(clade_stack_fp)
model_stack <- c(trunk_rich, clade_stack)
names(model_stack) <- c("trunkrichness", names(clade_stack))
regions <- list(
  Americas = ext(-170, -30, -60, 80),
  Africa   = ext(-20, 55, -35, 37),
  Asia     = ext(25, 180, -10, 80)
)
df_list <- list()
for (rn in names(regions)) {
  crop_r <- try(crop(model_stack, regions[[rn]]), silent = TRUE)
  if (inherits(crop_r, "try-error")) next
  for (cl in names(clade_stack)) {
    sub_r <- try(crop_r[[c("trunkrichness", cl)]], silent = TRUE)
    if (inherits(sub_r, "try-error")) next
    d0 <- as.data.frame(sub_r, xy = TRUE, na.rm = TRUE)
    if (nrow(d0) < 2 || length(unique(d0[[cl]])) < 2) next
    df_list[[paste(rn, cl, sep = "_")]] <- d0 %>%
      rename(longitude = x, latitude = y, predictor = !!cl)
  }
}

# --- Run Model 2: Univariate Monotonic ---
cat("Running Model 2: Univariate Monotonic...\n")
param_uni_mono <- get_param_grid(monotonic=TRUE, n_iter=100)
run_univariate_model(
  df_list         = df_list,
  param_grid      = param_uni_mono,
  out_dir         = dir_monotonic,
  plots_dir       = plots_monotonic,
  plot_slopes     = TRUE  # For monotonic, plot slopes!
)

# --- Run Model 3: Univariate Unconstrained ---
cat("Running Model 3: Univariate Unconstrained...\n")
param_uni_unconstr <- get_param_grid(monotonic=FALSE, n_iter=100)
run_univariate_model(
  df_list         = df_list,
  param_grid      = param_uni_unconstr,
  out_dir         = dir_unconstr,
  plots_dir       = plots_unconstr,
  plot_slopes     = FALSE # No slope plot for unconstrained unless desired
)







