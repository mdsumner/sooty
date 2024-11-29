utils::globalVariables(".data")


.onLoad <- function(libname, pkgname) {
  .objects <<- memoise::memoize(.objects, cache = cachem::cache_mem(max_age = 3600))
  oisstfiles <<- memoise::memoize(oisstfiles, cache = cachem::cache_mem(max_age = 3600))
  .curated_objects <<- memoise::memoize(.curated_objects, cache = cachem::cache_mem(max_age = 3600))
  nsidc25kmSfiles <<- memoise::memoize(nsidc25kmSfiles, cache = cachem::cache_mem(max_age = 3600 * 12))
  nsidc25kmNfiles <<- memoise::memoize(nsidc25kmNfiles, cache = cachem::cache_mem(max_age = 3600 * 12))
  readoisst <<- memoise::memoize(readoisst, cache = cachem::cache_mem(max_age = 3600 * 24))
  readnsidc25kmN <<- memoise::memoize(readnsidc25kmN, cache = cachem::cache_mem(max_age = 3600 * 24))


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

