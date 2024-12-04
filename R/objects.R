#' @importFrom arrow s3_bucket read_parquet
.objects <- function() {
  bucket <- arrow::s3_bucket("idea-objects", endpoint_override= "https://projects.pawsey.org.au", region = "")
  arrow::read_parquet(bucket$OpenInputFile("idea-objects.parquet"))
}
.curated_objects <- function(ds  = NULL) {
  bucket <- arrow::s3_bucket("idea-objects", endpoint_override= "https://projects.pawsey.org.au", region = "")

  out <- arrow::read_parquet(bucket$OpenInputFile("idea-curated-objects.parquet"))
  if (!is.null(ds)) out <- dplyr::filter(out, .data$Dataset == ds)
  out
}

.curated_objects <- function() {
  bucket <- arrow::s3_bucket("idea-objects", endpoint_override= "https://projects.pawsey.org.au", region = "")
  arrow::read_parquet(bucket$OpenInputFile("idea-curated-objects.parquet"))
}
.datasets <- function() {
##'SEALEVEL_GLO_PHY_L4', 'NSIDC_SEAICE_PS_S25km', 'NSIDC_SEAICE_PS_N25km', 'oisst-avhrr-v02r01'
##'
##'
  unique(.curated_objects()$Dataset)
}
.fileobjects <- function() {
  .objects() |> dplyr::mutate(fullname = sprintf("/vsis3/%s/%s", .data$Bucket, .data$Key))
}
.findfiles <- function (pattern, objects = NULL, ...)
{
    files <- objects %||% .objects()

    for (pattern0 in pattern) {
        files <- dplyr::filter(files, stringr::str_detect(.data$Key,
            pattern0))
        if (nrow(files) < 1)
            stop("no files found")
    }

    protocol <- "/vsis3"
      files$source <- sprintf("%s/%s/%s", files$protocol, files$Bucket, files$Key)
  files[c("date", "source", "Bucket", "Key", "protocol")]
}

.curated_files <- function(dataset) {
  files <- .curated_objects()
  if (!missing(dataset)) files <- files[files$Dataset == dataset, , drop = FALSE]
  files$protocol <-  "/vsis3"
  files$source <- sprintf("%s/%s/%s", files$protocol, files$Bucket, files$Key)

  files[c("date", "source", "Bucket", "Key", "protocol")]
}

#' Obtain object storage catalogues as a dataframe of file/object identifiers.
#'
#' The object (file) catalogue of available sources is stored in Parquet format on Pawsey
#' object storage. This function retrieves the curated catalogue, or the raw catalogue.
#'
#' In the curated case, the returned data frame has columns 'date', 'source' which are the main
#' useful fields, these describe the date of the data in the file, and its full URI (Uniform Resource Identifier) source on
#' S3 object storage. There are also fields 'Bucket', 'Key', and 'protocol' from which 'source' is
#' constructed.
#'
#' The original publisher URI can be reconstructed by replacing the value of 'protocol' in 'source'
#' with 'https://'.
#'
#' @param curated logical `TRUE` by default, set to `FALSE` to return raw object catalogue
#'
#' @return a data frame, see details
#' @export
#'
#' @examples
#' if (interactive()) {
#'   sooty_files(FALSE)
#' }
#'
#' sooty_files()
sooty_files <- function(curated = TRUE) {
  if (curated) {
    return(.curated_files())
  } else {
    return(.fileobjects())
  }
}


