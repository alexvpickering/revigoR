## code to prepare `l1000_map` dataset goes here

# subsetted map using an ebfit in drugseqr/data-raw/drug_paths/l1000_paths.R
l1000_map <- readRDS('data-raw/l1000_map.rds')

usethis::use_data(l1000_map, overwrite = TRUE)
