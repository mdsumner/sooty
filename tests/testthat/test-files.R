test_that("list works", {
  skip_if_offline()
  expect_true((n <- nrow(files <- sooty_files())) > 15000)

  expect_true((nn <- nrow(files <- sooty_files(FALSE))) > n)

  expect_true(nrow(.curated_files("oisst-tif")) < n)
})

test_that("ghrsst works", {
  skip_if_offline()
  expect_silent(ds <- datasource("ghrsst-tif"))
  expect_s3_class(ds@source, "data.frame")
  expect_true(is.integer(ds@n))
})

test_that("available list is good", {
  skip_if_offline()
  expect_true(is.character(av <- available_datasets()))
  expect_true(length(av) > 0)
})

test_that("deprecation message helpful", {
  skip_if_offline()
  expect_warning(dataset())
})
