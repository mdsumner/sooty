if (sprintf("%s.%s", R.version$major, R.version$minor) < "4.4.0" ) {
  `%||%` <- function (x, y) if (is.null(x)) y else x
}
