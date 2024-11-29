#' Return the available files for the readnsidc functions
#'
#' The column 'source' is the one to use, this is constructed from the other columns
#' 'protocol', 'Bucket', and 'Key'. This may change, note that the actual source url of the data
#' originally can be obtained, see examples.
#'
#' @return dataframe of source files (S3 objects)
#' @export
#' @aliases nsidc25kmNfiles
#' @examples
#' (files <- nsidc25kmSfiles())
#'
#'## generate original source urls (beware this design may change)
#' sprintf("https://%s", tail(files$Key))
#'
#' ## to read this with a GDAL-capable read do
#' dsn <- sprintf("/vsicurl/https://%s", tail(files$Key))
#' ## but please note these require earthdata credentials set (WIP)
#' ## e.g. terra::rast(dsn[1])  ## variable name is, um variable
nsidc25kmSfiles <- function() {
  files <- .curated_files("NSIDC_SEAICE_PS_S25km")[-.badnc(), ]  ## FIXME see issue #2
  files <- dplyr::mutate(files, date = as.POSIXct(as.Date(stringr::str_extract(basename(.data$source), "[0-9]{8}"), "%Y%m%d"), tz = "UTC"))
  dplyr::arrange(dplyr::distinct(files, date, .keep_all = TRUE), date) |>  dplyr::select("date", "source", "Bucket", "Key", "protocol")

}

#' @name nsidc25kmSfiles
nsidc25kmNfiles <- function() {
  files <- .curated_files("NSIDC_SEAICE_PS_N25km")[-.badnc(), ]  ## FIXME see issue #2
  files <- dplyr::mutate(files, date = as.POSIXct(as.Date(stringr::str_extract(basename(.data$source), "[0-9]{8}"), "%Y%m%d"), tz = "UTC"))
  dplyr::arrange(dplyr::distinct(files, date, .keep_all = TRUE), date) |>  dplyr::select("date", "source", "Bucket", "Key", "protocol")

}



#' Read NSIDC (National Snow and Ice Data Center) files for 25km polar sea ice concentration.
#'
#' By default latest date is returned, set `latest = FALSE` to find earliest data.
#'
#' By default the data is returned on the native grid, here polar north or polar south stereographic. Use
#' `gridspec` to specify a different grid, i.e. `rast(res = 0.25)` is the equivalent grid
#' for Atlantic-view (-180, 180) longlat.
#'
#' @inheritParams readoisst
#' @aliases readnsidc25kmS
#' @return terra SpatRaster object
#' @export
#' @examples
#' readnsidc25kmN("2000-04-01")
readnsidc25kmN <- function(date, gridspec = NULL, ..., latest = TRUE) {
  ## if we open with GDAL VRT (vapour_vrt or vrt://) we get full wrap on this 0-360 source for projected grids or rast() -180,180,-90,90 gridspec
  varname <- 1
  files <- nsidc25kmNfiles()
  if (missing(date)) {
    if (latest) date <- max(files$date) else date <- min(files$date)
  } else {
    date <- as.POSIXct(date, tz = "UTC")
  }
  ssf <- findInterval(date, files$date)

  files <- files[ssf, ]

  ## not until GDAL 3.8 or whatever
  #files$source <- sprintf("vrt://%s?sd_name=sst&a_srs=EPSG:4326", files$source)
  ##files$source <- vapour::vapour_vrt(files$source, projection = "EPSG:4326", sds = "sst")
  if (!is.null(gridspec)) {
    out <- rast(lapply(files$source, .projectit, grid_specification = gridspec, varname = varname))
  } else {
    out <- terra::rast(files$source, subds = varname)

  }

  if (is.na(terra::time(out))) terra::time(out) <- files$date
  out
}

#' @name readnsidc25kmN
#' @export
readnsidc25kmS <- function(date, gridspec = NULL, ..., latest = TRUE) {
  varname <- 1
  files <- nsidc25kmSfiles()
  if (missing(date)) {
    if (latest) date <- max(files$date) else date <- min(files$date)
  } else {
    date <- as.POSIXct(date, tz = "UTC")
  }
  ssf <- findInterval(date, files$date)

  files <- files[ssf, ]

 if (!is.null(gridspec)) {
    out <- rast(lapply(files$source, .projectit, grid_specification = gridspec, varname = varname))
  } else {
    out <- terra::rast(files$source, subds = varname)

  }

  if (is.na(terra::time(out))) terra::time(out) <- files$date
  out
}
