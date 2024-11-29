#' Return the available files for the readoisst function
#'
#' The column 'source' is the one to use, this is constructed from the other columns
#' 'protocol', 'Bucket', and 'Key'. This may change, note that the actual source url of the data
#' originally can be obtained, see examples.
#' @export
#' @examples
#' (files <- oisstfiles())
#'
#'## generate original source urls (beware this design may change)
#' sprintf("https://%s", tail(files$Key))
#'
#' ## to read this with a GDAL-capable read do
#' dsn <- sprintf("/vsicurl/https://%s", tail(files$Key))
#' ## e.g. terra::rast(dsn[1], "sst")  ## can be "sst", "anom", "err", "ice"
oisstfiles <- function() {

  files <- .curated_files("oisst-avhrr-v02r01")
  files <- dplyr::mutate(files, date = as.POSIXct(as.Date(stringr::str_extract(basename(.data$source), "[0-9]{8}"), "%Y%m%d"), tz = "UTC"))
  dplyr::arrange(dplyr::distinct(files, date, .keep_all = TRUE), date) |>  dplyr::select("date", "source", "Bucket", "Key", "protocol")
}

#' Read Reynolds OISST (optimally interpolated sea surface temperature)
#'
#' By default latest date is returned, set `latest = FALSE` to find earliest data.
#'
#' By default the data is returned on the native grid, here global Pacific-view longlat (0,360). Use
#' `gridspec` to specify a different grid, i.e. `rast(res = 0.25)` is the equivalent grid
#' for Atlantic-view (-180, 180).
#'
#' @param date date or date-time (or string)
#' @param gridspec optional terra object for the target grid
#' @param ... ignored currently
#' @param latest return most recent data if `TRUE`, else earliest data
#'
#' @return terra SpatRaster object
#' @export
#' @importFrom terra rast
#' @importFrom vapour vapour_vrt
#' @examples
#' readoisst("2000-04-01")
#'
readoisst <- function(date, gridspec = NULL, ..., latest = TRUE) {
  ## if we open with GDAL VRT (vapour_vrt or vrt://) we get full wrap on this 0-360 source for projected grids or rast() -180,180,-90,90 gridspec
  varname <- "sst"
  files <- oisstfiles()
  if (missing(date)) {
    if (latest) date <- max(files$date) else date <- min(files$date)
  } else {
    date <- as.POSIXct(date, tz = "UTC")
  }
  ssf <- findInterval(date, files$date)

  files <- files[ssf, ]

  ## not until GDAL 3.8 or whatever
  #files$source <- sprintf("vrt://%s?sd_name=sst&a_srs=EPSG:4326", files$source)
  files$source <- vapour::vapour_vrt(files$source, projection = "EPSG:4326", sds = "sst")
  if (!is.null(gridspec)) {
    out <- rast(lapply(files$source, .projectit, grid_specification = gridspec, varname = varname))
  } else {
    out <- rast(files$source, varname)

  }
  terra::time(out) <- files$date
  out
}
