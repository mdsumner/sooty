#' @importFrom S7 new_class new_property class_character class_integer class_POSIXct class_data.frame
#' @importFrom dplyr filter
dataset <- S7::new_class(name = "dataset",
  properties = list(
    id = S7::new_property(class = S7::class_character, default = "id"),
    n = S7::new_property(class = S7::class_integer, getter = function(self) nrow(self@source)),
    mindate = S7::new_property(class = S7::class_POSIXct, getter = function(self) min(self@source$date)),
    maxdate = S7::new_property(class = S7::class_POSIXct, getter = function(self) max(self@source$date)),
    available_datasets = S7::new_property(class = S7::class_character, getter = function(self) unique(self@curated$Dataset)),
    curated = S7::new_property(
      class = S7::class_data.frame, getter = function(self) {sooty_files(curated = TRUE)}),
    source = S7::new_property(
      class = S7::class_data.frame,
      getter = function(self) {
        self@curated |> dplyr::filter(Dataset == self@id)
      }
    ))

  )

