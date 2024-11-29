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

.fileobjects <- function() {
  .objects() |> dplyr::mutate(fullname = sprintf("/vsis3/%s/%s", Bucket, Key))
}
.findfiles <- function (pattern, objects = NULL, ...)
{
    if (is.null(objects)) objects <- .objects()
    for (pattern0 in pattern) {
        files <- dplyr::filter(objects, stringr::str_detect(.data$Key,
            pattern0))
        if (nrow(files) < 1)
            stop("no files found")
    }

    protocol <- "/vsis3"
    files <- dplyr::transmute(files, source = sprintf("%s/%s/%s", protocol, Bucket, Key), Bucket, Key, protocol = protocol)
    files
}
