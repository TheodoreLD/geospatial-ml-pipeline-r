# run_pipeline.R
# Master script to run the full analysis pipeline

cat('Starting pipeline...\n')

source('scripts/00_standardization.R')
cat('Step 0 complete\n')

source('scripts/01_biogeography_trunk.R')
cat('Step 1 complete\n')

source('scripts/02_mammal_ecoregions.R')
cat('Step 2 complete\n')

source('scripts/03_data_preparation_models.R')
cat('Step 3 complete\n')

source('scripts/04_catboost_models.R')
cat('Step 4 complete\n')

cat('Pipeline completed successfully\n')
