if (sprintf("%s.%s", R.version$major, R.version$minor) < "4.4.0" ) {
  `%||%` <- function (x, y) if (is.null(x)) y else x
}


  .projectit <- function(.x, grid_specification, varname = 0) {
    terra::project(terra::rast(.x, subds = varname), grid_specification, by_util = TRUE)
  }
