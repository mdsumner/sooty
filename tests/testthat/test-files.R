test_that("oisst works", {
  expect_true(nrow(files <- oisstfiles()) > 15000)
})

test_that("nsidc works", {
  expect_true(nrow(files <- nsidc25kmSfiles()) > 15177)
})

