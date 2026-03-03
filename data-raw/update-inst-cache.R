# data-raw/update-inst-cache.R
.sooty_stale_cache <- arrow::read_parquet(
  "https://projects.pawsey.org.au/idea-objects/idea-curated-objects.parquet"
)
usethis::use_data(.sooty_stale_cache,
                  internal = TRUE, compress = "bzip2", overwrite = TRUE
)
