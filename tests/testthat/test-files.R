test_that("list works", {
  skip_if_not_installed("curl")
  skip_if_offline()
  expect_true((n <- nrow(files <- sooty_files())) > 15000)
  expect_true(nrow(files <- sooty_files(FALSE)) > n)
})

