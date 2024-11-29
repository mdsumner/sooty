test_that("oisst works", {
  expect_true(nrow(files <- oisstfiles()) > 15000)
})
