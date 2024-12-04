.read_tempfile <- function(curated = TRUE) {
  #bucket <- arrow::s3_bucket("idea-objects", endpoint_override= "https://projects.pawsey.org.au", region = "")
  #out <- arrow::read_parquet(bucket$OpenInputFile("idea-curated-objects.parquet"))

  sourcefile <- "https://projects.pawsey.org.au/idea-objects/idea-objects.parquet"
  if (curated) sourcefile <- "https://projects.pawsey.org.au/idea-objects/idea-curated-objects.parquet"
  tfile <- tempfile(fileext = ".parquet")
  on.exit(unlink(tfile), add = TRUE)
  err <- try(curl::curl_download(sourcefile, tfile), silent = TRUE)
  if (inherits(err, "try-error")) stop("cannot download latest file list, curl download failed")
  arrow::read_parquet(tfile)
}
#' @importFrom arrow  read_parquet
.objects <- function() {
  .read_tempfile(FALSE)
}
.curated_objects <- function(ds  = NULL) {
  out <- .read_tempfile()

  if (!is.null(ds)) out <- dplyr::filter(out, .data$Dataset == ds)
  out
}


.fileobjects <- function() {
  .objects() |> dplyr::mutate(fullname = sprintf("/vsis3/%s/%s", .data$Bucket, .data$Key))
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
#' The public object URI can be reconstructed by replacing the value of 'protocol' in 'source' with
#' 'https://projects.pawsey.org.au'.
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


