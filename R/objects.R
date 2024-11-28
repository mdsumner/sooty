.objects <- function() {
  bucket <- arrow::s3_bucket("idea-objects", endpoint_override= "https://projects.pawsey.org.au", region = "")
  arrow::read_parquet(bucket$OpenInputFile("idea-objects.parquet"))
}

.fileobjects <- function() {
  .objects() |> dplyr::mutate(fullname = sprintf("/vsis3/%s/%s", Bucket, Key))
}
.findfiles <- function (pattern, objects = NULL, ...)
{
    objects <- objects %||% .objects()
    files <- objects
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

#' @export
oisstfiles <- function(objects = NULL) {

  if (missing(objects)) objects <- .objects()

    pattern <- c("avhrr", "^.*www.ncei.noaa.gov.*sea-surface-temperature-optimum-interpolation/v2.1/access/avhrr/.*\\.nc$")
    files <- .findfiles(pattern, objects = objects)
    if (nrow(files) < 1) {
        stop("no files found")
    }
    files <- dplyr::mutate(files, date = as.POSIXct(as.Date(stringr::str_extract(basename(.data$source), "[0-9]{8}"), "%Y%m%d"), tz = "UTC"))
    dplyr::arrange(dplyr::distinct(files, date, .keep_all = TRUE), date) |>  dplyr::select(.data$date, .data$source, .data$Bucket, .data$Key, .data$protocol)
}

#' @export
readoisst <- function(date, gridspec = NULL, ..., latest = TRUE) {

  ## if we open with GDAL VRT (vapour_vrt or vrt://) we get full wrap on this 0-360 source for projected grids or rast() -180,180,-90,90 gridspec
  varname <- "" # "sst"
  .projectit <- function(.x) {
    terra::project(terra::rast(.x, varname), gridspec, by_util = TRUE)
  }
  files <- oisstfiles()
  if (missing(date)) {
     if (latest) date <- max(files$date) else date <- min(files$date)
  }
  ssf <- findInterval(date, files$date)

  files <- files[ssf, ]

  ## not until GDAL 3.8 or whatever
  #files$source <- sprintf("vrt://%s?sd_name=sst&a_srs=EPSG:4326", files$source)
  files$source <- vapour::vapour_vrt(files$source, projection = "EPSG:4326", sds = "sst")
  if (!is.null(gridspec)) {
    out <- rast(lapply(files$source, .projectit))
  } else {
  out <- terra::rast(files$source, varname)

  }
  terra::time(out) <- files$date
  out
}
