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
  objects() |> dplyr::mutate(fullname = sprintf("/vsis3/%s/%s", .data$Bucket, .data$Key))
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
  files <- files[files$Dataset == dataset, , drop = FALSE]
  files$protocol <-  "/vsis3"
  files$source <- sprintf("%s/%s/%s", files$protocol, files$Bucket, files$Key)

  files[c("date", "source", "Bucket", "Key", "protocol")]
}



