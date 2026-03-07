withr::local_options(list("sooty.allow.cache" = FALSE))

test_that("sysdata fallback returns data without cache", {
  expect_true((n <- nrow(files <- sooty_files())) > 0)
  expect_true(is.character(files$Dataset))
  expect_true("source" %in% names(files))
})

test_that("curated subset works from sysdata", {
  datasets <- unique(sooty_files()$Dataset)
  expect_true(length(datasets) > 0)
  sub <- .curated_files(datasets[[1]])
  expect_true(nrow(sub) > 0)
  expect_true(nrow(sub) < nrow(sooty_files()))
})

test_that("available_datasets returns character vector", {
  expect_true(is.character(av <- available_datasets()))
  expect_true(length(av) > 0)
})

test_that("datasource object works from sysdata", {
  av <- available_datasets()
  ds <- datasource(av[[1]])
  expect_s3_class(ds@source, "data.frame")
  expect_true(is.integer(ds@n))
  expect_true(ds@n > 0)
})

test_that("deprecation warning fires", {
  expect_warning(dataset(available_datasets()[[1]]))
})

test_that("sooty_cache_info reflects disabled cache", {
  info <- sooty_cache_info()
  expect_false(info$cache_allowed)
  expect_true(info$bundled_rows > 0)
})

test_that("live catalogue works when online", {
  skip_if_offline()
  withr::local_options(list(
    "sooty.allow.cache" = TRUE,
    "sooty.cache.path"  = tempdir()
  ))
  expect_true((n <- nrow(files <- sooty_files())) > 15000)
  expect_true(is.character(av <- available_datasets()))
  expect_true(length(av) > 0)
})

test_that("cache redirects to tempdir when sooty.cache.path set", {
  skip_if_offline()
  td <- tempfile("sooty_cache_test")
  dir.create(td)
  withr::local_options(list(
    "sooty.allow.cache" = TRUE,
    "sooty.cache.path"  = td
  ))
  files <- sooty_files()
  expect_true(nrow(files) > 0)
  expect_true(file.exists(file.path(td, "idea-curated-objects.parquet")))
})
