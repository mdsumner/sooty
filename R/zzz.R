utils::globalVariables(".data")


.onLoad <- function(libname, pkgname) {

  Sys.setenv("AWS_NO_SIGN_REQUEST" = "YES")
  Sys.setenv("AWS_S3_ENDPOINT" = "projects.pawsey.org.au")
  Sys.setenv("AWS_VIRTUAL_HOSTING" = "FALSE")

  Sys.setenv("GDAL_DISABLE_READDIR_ON_OPEN" = "EMPTY_DIR")
  Sys.setenv("VSI_CACHE"="TRUE")
  Sys.setenv("GDAL_NETCDF_ASSUME_LONGLAT" = "YES")
  Sys.setenv("VSI_CACHE_MAX" = "40%")
  Sys.setenv("GDAL_HTTP_MULTIPLEX" = "YES")
  Sys.setenv("GDAL_HTTP_VERSION" = "2")
  Sys.setenv("GDAL_HTTP_MERGE_CONSECUTIVE_RANGES" = "YES")
  Sys.setenv("GDAL_NUM_THREADS" = "12")
}

