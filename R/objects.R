
.fileobjects <- function() {
  out <- .objects()
  out[["fullname"]] <- sprintf("%s/%s/%s", out$Host, out$Bucket, out$Key)
  out
}

.curated_files <- function(dataset) {
  files <- .curated_objects()
  if (!missing(dataset)) files <- files[files$Dataset == dataset, , drop = FALSE]
  files$source <- sprintf("%s/%s/%s/%s", files$Protocol, files$Host, files$Bucket, files$Key)

  files[c("date", "source", "Dataset", "Bucket", "Key", "Protocol", "Host")]
}

#' Obtain object storage catalogues as a dataframe of file/object identifiers.
#'
#' The object (file) catalogue of available sources is stored in Parquet format on Pawsey
#' object storage. This function retrieves the curated catalogue.
#'
#' The returned curated data frame has columns 'date', 'source' which are the main
#' useful fields, these describe the date of the data in the file, and its full URI
#' (Uniform Resource Identifier) source on S3 object storage. There are also fields
#' 'Bucket', 'Key', and 'Protocol' from which 'source' is constructed.
#'
#' The original publisher URI can be reconstructed by replacing the value of 'Protocol'
#' in 'source' with 'https://'.
#'
#' The public object URI can be reconstructed by replacing the value of 'Protocol' in
#' 'source' with 'https://projects.pawsey.org.au'.
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
#' options("sooty.allow.cache" = FALSE)
#' sooty_files()
sooty_files <- function(curated = TRUE) {
  if (!curated) {
    warning("non-curated file return was removed in sooty 0.6.0")
  }
  return(.curated_files())
}
