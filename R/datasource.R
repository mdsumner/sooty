# enable usage of <S7_object>@name in package code
#' @rawNamespace if (getRversion() < "4.3.0") importFrom("S7", "@")
NULL

#' Create a datasource object. A data source provides a list of files that together comprise a dataset.
#'
#' Generates an object whose "@id" property may be set, which then communicates with a dataset of files/objects that
#' sooty knows about.
#'
#' Compare 'curated' to 'sooty_files(curated = FALSE)', if it is curated sooty knows what dataset it belongs to, and
#' otherwise it's just the huge list of files we're interested in for our work. All of the curation is done outside of sooty.
#'
#' The following properties are available via the `@` slot:
#' * `n` the number of files (objects) comprising the dataset (get, not settable)
#' * `mindate` the minimum available date for the files
#' * `maxdate1 the maximum available date for the files
#' * `source1 the set of files (objects) belonging to this dataset (get, not settable)
#'
#' @param id a dataset label, see 'datasource()@available_datasources' (get, and settable)
#' @importFrom S7 new_class new_property class_character class_integer class_POSIXct class_data.frame
#' @importFrom dplyr filter
#' @export
#' @note This was originally called `dataset()` which usage has now been deprecated.
#' @examples
#' ## available dataset names
#' if (interactive()) {
#'  available_datasets()
#' }
#' ## set to one of those
#' ds  <- datasource("ghrsst-tif")
#' ## access the 'ds@source' slot, files with 'date','source' (GDAL-readable)
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
         dplyr::filter(sooty_files(TRUE), Dataset == self@id)
      }
    ))

  )

#' List available datasets
#'
#' In `sooty_files()` the data source files are grouped by `Dataset`, this is the
#' list of unique datasets, values that can be used in `datasource(<name>)`.
#'
#' @returns character vector of available dataset ids for `datasource()`
#' @export
#'
#' @examples
#' available_datasets()
available_datasets <- function() {
  sort(unique(sooty_files()$Dataset))
}


#sooty_files()
# sooty::available_datasources()
#sooty::datasource(<any,name-of-datasource>)
## datasource@source,n,mindate,maxdate,id


#' @export
#' @param ... only used by deprecated function, will become defunct
#' @name datasource
dataset <- function(...) {
  .Deprecated("datasource")
  datasource(...)
}
