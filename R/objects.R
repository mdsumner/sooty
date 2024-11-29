.objects <- function() {
  bucket <- arrow::s3_bucket("idea-objects", endpoint_override= "https://projects.pawsey.org.au", region = "")
  arrow::read_parquet(bucket$OpenInputFile("idea-objects.parquet"))
}

.curated_objects <- function() {
  bucket <- arrow::s3_bucket("idea-objects", endpoint_override= "https://projects.pawsey.org.au", region = "")
  arrow::read_parquet(bucket$OpenInputFile("idea-curated-objects.parquet"))
}
.datasets <- function() {
##'SEALEVEL_GLO_PHY_L4', 'NSIDC_SEAICE_PS_S25km', 'NSIDC_SEAICE_PS_N25km', 'oisst-avhrr-v02r01'
##'
##'
  unique(idt:::.curated_objects()$Dataset)
}
.fileobjects <- function() {
  objects() |> dplyr::mutate(fullname = sprintf("/vsis3/%s/%s", Bucket, Key))
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
    files <- dplyr::transmute(files, source = sprintf("%s/%s/%s", protocol, Bucket, Key), Bucket, Key, protocol = protocol)
    files
}


.curated_files <- function(dataset) {
  files <- .curated_objects() |> dplyr::filter(Dataset == dataset)
  protocol <- "/vsis3"
  dplyr::transmute(files, source = sprintf("%s/%s/%s", protocol, Bucket, Key), Bucket, Key, protocol = protocol)
}

