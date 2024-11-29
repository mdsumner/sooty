#' .. content for \description{} (no empty lines) ..
#'
#' .. content for \details{} ..
#'
#' @title

#' @return

#' @export
nsidc25kmSfiles <- function(objects = NULL) {
  files <- .curated_files("NSIDC_SEAICE_PS_S25km")
  files <- dplyr::mutate(files, date = as.POSIXct(as.Date(stringr::str_extract(basename(.data$source), "[0-9]{8}"), "%Y%m%d"), tz = "UTC"))
  dplyr::arrange(dplyr::distinct(files, date, .keep_all = TRUE), date) |>  dplyr::select(.data$date, .data$source, .data$Bucket, .data$Key, .data$protocol)

}
