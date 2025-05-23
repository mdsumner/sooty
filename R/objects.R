.read_parquet <- function(curated = TRUE) {
  sourcefile <- "https://projects.pawsey.org.au/idea-objects/idea-objects.parquet"
  if (curated) sourcefile <- "https://projects.pawsey.org.au/idea-objects/idea-curated-objects.parquet"
  tibble::as_tibble(arrow::read_parquet(sourcefile))
}
#' @importFrom arrow  read_parquet
.objects <- function() {
  .read_parquet(FALSE)
}
.curated_objects <- function() {
  out <- .read_parquet()
  out
}


.fileobjects <- function() {
   dplyr::mutate(.objects(), fullname = sprintf("%s/%s/%s", .data$Host, .data$Bucket, .data$Key))
}

.curated_files <- function(dataset) {
  files <- .curated_objects()
  if (!missing(dataset)) files <- files[files$Dataset == dataset, , drop = FALSE]
  files$source <- sprintf("%s/%s/%s/%s", files$Protocol, files$Host, files$Bucket, files$Key)

  files[c("date", "source",  "Dataset", "Bucket", "Key", "Protocol", "Host")]
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
