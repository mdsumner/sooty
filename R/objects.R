
.curated_files <- function(dataset) {
  files <- .curated_objects()
  if (!missing(dataset)) files <- files[files$Dataset == dataset, , drop = FALSE]
  files$source <- sprintf("%s/%s/%s/%s", files$Protocol, files$Host, files$Bucket, files$Key)

  files[c("date", "source", "Dataset", "Bucket", "Key", "Protocol", "Host")]
}

#' Obtain object storage catalogues as a dataframe of file/object identifiers.
#'
#' The catalogue lists, for each dataset, one file per date in a public store: object
#' storage on Pawsey (`projects.pawsey.org.au/aad-derived`) or Source Cooperative
#' (`data.source.coop/ausantarctic`), or the publisher of the data (NOAA, NSIDC, Copernicus
#' Marine, University of Bremen, Remote Sensing Systems). This function retrieves the catalogue.
#'
#' The returned curated data frame has columns 'date', 'source' which are the main
#' useful fields, these describe the date of the data in the file, and its full URI
#' (Uniform Resource Identifier) source, ready for GDAL. There are also fields
#' 'Protocol', 'Host', 'Bucket', and 'Key' from which 'source' is constructed: 'Bucket' is
#' the first part of the path at 'Host' and 'Key' the rest.
#'
#' The plain URL of a file is 'source' without the leading value of 'Protocol' and its "/".
#'
#' Datasets whose files are GeoTIFF copies on Pawsey are an archive that ends in 2025
#' (`oisst-tif`, the `sealevel-*-tif` family, daily and annual `esacci-oc-*`). The others
#' are extended as their publishers add files.
#'
#' By default sooty maintains a local cache of the catalogue, refreshed once per session
#' when internet is available. Set `options("sooty.allow.cache" = FALSE)` to suppress all
#' disk I/O and use only the bundled sysdata, or `options("sooty.cache.path" = tempdir())`
#' to redirect the cache directory. See [sooty_cache_info()] for details.
#'
#' @param curated logical `TRUE` by default, ignored with a warning if `FALSE`
#'
#' @return a data frame, see details
#' @export
#'
#' @examples
#' op <- options("sooty.allow.cache" = FALSE)
#' sooty_files()
#' options(op)
sooty_files <- function(curated = TRUE) {
  if (!curated) {
    warning("non-curated file return was removed in sooty 0.6.0")
  }
  return(.curated_files())
}
