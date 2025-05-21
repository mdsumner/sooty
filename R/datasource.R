# enable usage of <S7_object>@name in package code
#' @rawNamespace if (getRversion() < "4.3.0") importFrom("S7", "@")
NULL

#' Create a datasource object. A data source can access a list of files that together comprise a dataset.
#'
#' Generates an object whose "@id" property may be set, which then communicates with a dataset of files/objects that
#' sooty knows about.
#'
#' Compare 'curated' to 'sooty_files(curated = FALSE)', if its curated sooty knows what dataset it belongs to
#'
#' @param id a dataset label, see 'datasorce()@available_datasources' (get, and settable)
#' @param n the number of files (objects) comprising the dataset (get, not settable)
#' @param mindate the minimum available date for the files
#' @param maxdate the maximum available date for the files
#' @param source the set of files (objects) belonging to this dataset (get, not settable)
#' @usage NULL
#' @importFrom S7 new_class new_property class_character class_integer class_POSIXct class_data.frame
#' @importFrom dplyr filter
#' @export
#' @examples
#' ds <- datasource()  ## FIXME this should validate empty input
#' ## available dataset names
#' available_datasets()
#' ## set to one of those
#' ds@id <- "oisst-tif"
#' ds
#' ds@source
datasource <- S7::new_class(name = "dataset", package = "sooty",
  properties = list(
    id = S7::new_property(class = S7::class_character, default = NA_character_),
    n = S7::new_property(class = S7::class_integer, getter = function(self) if (is.na(self@id)) NA else  nrow(self@source)),
    mindate = S7::new_property(class = S7::class_POSIXct, getter = function(self) if (is.na(self@id)) NA else min(self@source$date)),
    maxdate = S7::new_property(class = S7::class_POSIXct, getter = function(self) if (is.na(self@id)) NA else max(self@source$date)),
    source = S7::new_property(
      class = S7::class_data.frame,
      getter = function(self) {
        if (is.na(self@id)) message("`id` is NA, please see `sooty::available_datasets()` and set `@id` or use `datasource(id)`")
        sooty_files(TRUE) |> dplyr::filter(Dataset == self@id)
      }
    ))

  )

#' Title
#'
#' @returns character vector of available dataset ids for `datasource()`
#' @export
#'
#' @examples
available_datasets <- function() {
  sort(unique(sooty_files()$Dataset))
}


#sooty_files()
# sooty::available_datasources()
#sooty::datasource(<any,name-of-datasource>)
## datasource@source,n,mindate,maxdate,id


#' @export
#' @name deprecated-sooty
dataset <- function(...) {
  .Deprecated("datasource")
  datasource(...)
}
