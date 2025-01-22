#' Return the available files for the readamsr functions
#'
#' The column 'source' is the one to use, this is constructed from the other columns
#' 'protocol', 'Bucket', and 'Key'. This may change, note that the actual source url of the data
#' originally can be obtained, see examples.
#'
#' @return dataframe of source files (S3 objects)
#' @export
#' @examples
#' (files <- amsrfiles())
#'
#'## generate original source urls (beware this design may change)
#' sprintf("https://%s", tail(files$Key))
#'
#' ## to read this with a GDAL-capable read do
#' dsn <- sprintf("/vsicurl/https://%s", tail(files$Key))
#' ## e.g. terra::rast(dsn[1])
amsrfiles <- function() {
  files <- .curated_files("antarctica-amsr2-asi-s3125-tif")
  files <- dplyr::mutate(files, date = as.POSIXct(as.Date(stringr::str_extract(basename(.data$source), "[0-9]{8}"), "%Y%m%d"), tz = "UTC"))
  dplyr::arrange(dplyr::distinct(files, date, .keep_all = TRUE), date) |>  dplyr::select("date", "source", "Bucket", "Key", "protocol")

}




#' Read AMSR (Advanced Microwave Scanning Radiometer) files for 3.125km Antarctic sea ice concentration.
#'
#' By default latest date is returned, set `latest = FALSE` to find earliest data.
#'
#' By default the data is returned on the native grid, here polar south stereographic. Use
#' `gridspec` to specify a different grid, i.e. `rast(res = 0.25)` is the equivalent grid
#' for Atlantic-view (-180, 180) longlat.
#'
#' @inheritParams readoisst
#' @return terra SpatRaster object
#' @export
#' @examples
#' readamsr("2020-04-01")
readamsr <- function(date, gridspec = NULL, ..., latest = TRUE) {
  varname <- 1
  files <- amsrfiles()
  if (missing(date)) {
    if (latest) date <- max(files$date) else date <- min(files$date)
  } else {
    date <- as.POSIXct(date, tz = "UTC")

    if (date > max(files$date) || date < min(files$date)) stop("date out of range")
  }
  ssf <- findInterval(date, files$date)

  files <- files[ssf, ]
if (nrow(files) < 1) stop("date input is out of range")
  ## not until GDAL 3.8 or whatever
  #files$source <- sprintf("vrt://%s?sd_name=sst&a_srs=EPSG:4326", files$source)
  ##files$source <- vapour::vapour_vrt(files$source, projection = "EPSG:4326", sds = "sst")


  files$source <- vapour::vapour_vrt(files$source, options = c("-a_nodata", 120))
  op <- options(warn = -1)  ## lest we hear about path.expand
  on.exit(options(op), add = TRUE)
  if (!is.null(gridspec)) {
    out <- rast(lapply(files$source, .projectit, grid_specification = gridspec, varname = varname))
  } else {
    out <- terra::rast(files$source, subds = varname)
  }

  ## this and a_nodata (not scale/expand)
  terra::coltab(out) <- NULL
  if (is.na(terra::time(out))) terra::time(out) <- files$date
  out
}
