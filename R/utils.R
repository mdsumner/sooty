if (getRversion() < "4.4.0") {
  `%||%` <- function(x, y) if (is.null(x)) y else x
}
