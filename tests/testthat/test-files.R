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

test_that("bundled catalogue is one file per date in each dataset", {
  files <- sooty_files()
  expect_false(anyDuplicated(files[c("Dataset", "date")]) > 0)
  expect_true(all(grepl("^/vsicurl/https://[^/]+/[^/]+/.+", files$source)))
  expect_false(anyNA(files$date))
})

test_that("a failed update leaves the cache as it was", {
  td <- tempfile("sooty_cache_test")
  withr::local_options(list("sooty.allow.cache" = TRUE, "sooty.cache.path" = td))
  local_mocked_bindings(.remote_url = function() paste0("file://", tempfile()))
  .seed_cache_from_sysdata()
  before <- tools::md5sum(.cache_path())
  expect_message(ok <- .download_to_cache(), "could not be updated")
  expect_false(ok)
  expect_identical(tools::md5sum(.cache_path()), before)
  expect_identical(list.files(td), basename(.cache_path()))
  expect_true(nrow(.read_parquet()) > 0)
})

test_that("an update that is not the catalogue is not used", {
  td <- tempfile("sooty_cache_test")
  withr::local_options(list("sooty.allow.cache" = TRUE, "sooty.cache.path" = td))
  notit <- tempfile(fileext = ".parquet")
  writeLines("<Error><Code>AccessDenied</Code></Error>", notit)
  local_mocked_bindings(.remote_url = function() paste0("file://", notit))
  .seed_cache_from_sysdata()
  expect_message(ok <- .download_to_cache(), "could not be updated")
  expect_false(ok)
  expect_identical(nrow(.read_cache_file(.cache_path())), nrow(.sooty_stale_cache))
})

test_that("a good update replaces the cache", {
  td <- tempfile("sooty_cache_test")
  withr::local_options(list("sooty.allow.cache" = TRUE, "sooty.cache.path" = td))
  newer <- tempfile(fileext = ".parquet")
  arrow::write_parquet(.sooty_stale_cache[1:10, ], newer)
  local_mocked_bindings(.remote_url = function() paste0("file://", newer))
  .seed_cache_from_sysdata()
  expect_true(.download_to_cache())
  expect_identical(nrow(.read_cache_file(.cache_path())), 10L)
})

test_that("a cache older than the bundled catalogue is replaced, an unreadable one is not fatal", {
  td <- tempfile("sooty_cache_test")
  dir.create(td)
  withr::local_options(list("sooty.allow.cache" = TRUE, "sooty.cache.path" = td))
  arrow::write_parquet(.sooty_stale_cache[1:10, ], .cache_path())
  Sys.setFileTime(.cache_path(), .sooty_stale_cache_built - 86400)
  expect_identical(.seed_cache_from_sysdata(), .cache_path())
  expect_identical(nrow(.read_cache_file(.cache_path())), nrow(.sooty_stale_cache))
  ## the cache just written is current, it is not written again
  expect_null(.seed_cache_from_sysdata())

  writeLines("not parquet", .cache_path())
  Sys.setFileTime(.cache_path(), Sys.time())
  .sooty_cache$staleness_checked <- TRUE
  expect_identical(nrow(.read_parquet()), nrow(.sooty_stale_cache))
})
