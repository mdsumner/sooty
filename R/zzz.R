.onLoad <- function(libname, pkgname) {
  memoise::memoize(.objects, cache = cachem::cache_mem(max_age = 3600))
  Sys.setenv("AWS_NO_SIGN_REQUEST" = "YES")
  Sys.setenv("AWS_S3_ENDPOINT" = "projects.pawsey.org.au")
  Sys.setenv("GDAL_DISABLE_READDIR_ON_OPEN" = "EMPTY_DIR")
  Sys.setenv("VSI_CACHE"="TRUE")
  Sys.setenv("GDAL_NETCDF_ASSUME_LONGLAT" = "YES")

}

