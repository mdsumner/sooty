# enable usage of <S7_object>@name in package code
#' @rawNamespace if (getRversion() < "4.3.0") importFrom("S7", "@")
NULL

#' Create a datasource object. A data source provides a list of files that together comprise a dataset.
#'
#' Generates an object whose `@id` property may be set, which then communicates with a dataset
#' of files/objects that sooty knows about.
#'
#' The following properties are available via the `@` slot:
#' * `id` a dataset label, see [available_datasets()] (gettable and settable)
#' * `n` the number of files (objects) comprising the dataset (get only)
#' * `mindate` the minimum available date for the files (get only)
#' * `maxdate` the maximum available date for the files (get only)
#' * `source` the set of files (objects) belonging to this dataset (get only)
#'
#' By default sooty maintains a local cache of the catalogue used to populate these
#' properties. Set `options("sooty.allow.cache" = FALSE)` to use only the bundled
#' sysdata, or `options("sooty.cache.path" = tempdir())` to redirect the cache
#' directory. See [sooty_cache_info()] for details.
#'
#' @param id a dataset label, see [available_datasets()]
#' @importFrom S7 new_class new_property class_character class_integer class_POSIXct class_data.frame
#' @export
#' @note This was originally called `dataset()` which usage has now been deprecated.
#' @examples
#' options("sooty.allow.cache" = FALSE)
#' ## available dataset names
#' available_datasets()
#' ## set to one of those
#' ds <- datasource("ghrsst-tif")
datasource <- S7::new_class(name = "dataset", package = "sooty",
  properties = list(
    id = S7::new_property(class = S7::class_character, default = NA_character_),
    n = S7::new_property(
      class = S7::class_integer,
      getter = function(self) if (is.na(self@id)) NA_integer_ else nrow(self@source)
    ),
    mindate = S7::new_property(
      class = S7::class_POSIXct,
      getter = function(self) if (is.na(self@id)) as.POSIXct(NA) else min(self@source$date)
    ),
    maxdate = S7::new_property(
      class = S7::class_POSIXct,
      getter = function(self) if (is.na(self@id)) as.POSIXct(NA) else max(self@source$date)
    ),
    source = S7::new_property(
      class = S7::class_data.frame,
      getter = function(self) {
        if (is.na(self@id)) message("`id` is NA, please see `sooty::available_datasets()` and set `@id` or use `datasource(id)`")
        thefiles <- sooty_files(TRUE)
        thefiles[thefiles$Dataset == self@id, ]
      }
    )
  )
)

#' List available datasets
#'
#' In `sooty_files()` the data source files are grouped by `Dataset`, this is the
#' list of unique datasets, values that can be used in `datasource(id)`.
#'
#' @returns character vector of available dataset ids for `datasource()`
#' @export
#'
#' @examples
#' options("sooty.allow.cache" = FALSE)
#' available_datasets()
available_datasets <- function() {
  sort(unique(sooty_files()$Dataset))
}


#' @export
#' @param ... only used by deprecated function, will become defunct
#' @name datasource
dataset <- function(...) {
  .Deprecated("datasource")
  datasource(...)
}
