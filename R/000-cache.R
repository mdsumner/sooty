.sooty_cache <- new.env(parent = emptyenv())

.cache_dir <- function() {
  getOption("sooty.cache.path", default = tools::R_user_dir("sooty", which = "cache"))
}

.cache_path <- function() {
  file.path(.cache_dir(), "idea-curated-objects.parquet")
}

.remote_url <- function() {
  "https://projects.pawsey.org.au/idea-objects/idea-curated-objects.parquet"
}

.download_to_cache <- function() {
  path <- .cache_path()
  dir.create(dirname(path), showWarnings = FALSE, recursive = TRUE)
  tryCatch(
    utils::download.file(.remote_url(), destfile = path, quiet = TRUE, mode = "wb"),
    error = function(e) {
      warning(sprintf("sooty: failed to update cache: %s", conditionMessage(e)), call. = FALSE)
      invisible(NULL)
    }
  )
  invisible(path)
}

# Seed user cache from sysdata if missing — no internet required
#' @importFrom arrow write_parquet
.seed_cache_from_sysdata <- function() {
  path <- .cache_path()
  if (file.exists(path)) return(invisible(NULL))
  dir.create(dirname(path), showWarnings = FALSE, recursive = TRUE)
  arrow::write_parquet(.sooty_stale_cache, path)
  invisible(path)
}

# Once per session: update cache if stale and online
.check_staleness <- function() {
  if (isTRUE(.sooty_cache$staleness_checked)) return(invisible(NULL))
  .sooty_cache$staleness_checked <- TRUE

  if (!curl::has_internet()) return(invisible(NULL))

  path <- .cache_path()
  stale <- !file.exists(path) ||
    (Sys.time() - file.mtime(path)) > as.difftime(1, units = "days")

  if (stale) {
    message("sooty: updating local cache of object catalogue...")
    .download_to_cache()
  }
  invisible(NULL)
}

#' @importFrom tibble as_tibble
#' @importFrom arrow read_parquet
.read_parquet <- function() {
  if (isFALSE(getOption("sooty.allow.cache", default = TRUE))) {
    return(.sooty_stale_cache)
  }
  .seed_cache_from_sysdata()
  .check_staleness()
  tibble::as_tibble(arrow::read_parquet(.cache_path()))
}

.objects <- function() {
  sourcefile <- "https://projects.pawsey.org.au/idea-objects/idea-objects.parquet"
  tibble::as_tibble(arrow::read_parquet(sourcefile))
}

.curated_objects <- function() {
  .read_parquet()
}

#' Show sooty cache status
#'
#' Reports the active cache configuration, including the effect of any options
#' that have been set. See the Options section below for details.
#'
#' @return A data frame (invisibly) with cache details.
#' @export
#'
#' @section Options:
#' Two options control cache behaviour:
#' \describe{
#'   \item{`sooty.allow.cache`}{logical, default `TRUE`. Set to `FALSE` to skip
#'     all disk I/O and use only the bundled sysdata. Suitable for examples,
#'     tests, and offline use: `options("sooty.allow.cache" = FALSE)`.}
#'   \item{`sooty.cache.path`}{path, default `tools::R_user_dir("sooty", "cache")`.
#'     Override the cache directory. Useful for CI or shared environments:
#'     `options("sooty.cache.path" = tempdir())`.}
#' }
#'
#' @examples
#' sooty_cache_info()
#'
#' options("sooty.allow.cache" = FALSE)
#' sooty_cache_info()
sooty_cache_info <- function() {
  cache_allowed <- !isFALSE(getOption("sooty.allow.cache", default = TRUE))
  path <- .cache_path()
  pexists <- file.exists(path)

  message(sprintf("Cache directory: %s\n", .cache_dir()))

  if (!cache_allowed) {
    message("  cache disabled via options(\"sooty.allow.cache\" = FALSE)")
    message(sprintf("  bundled  : %d rows (ships with package)\n", nrow(.sooty_stale_cache)))
  } else {
    message("  curated catalogue:")
    if (pexists) {
      age <- round(as.numeric(Sys.time() - file.mtime(path), units = "days"), 1)
      message(sprintf("    modified : %s (%.1f days ago)", format(file.mtime(path)), age))
    } else {
      message("    not yet written to user cache (sysdata fallback available)")
    }
    message(sprintf("    bundled  : %d rows (ships with package)\n", nrow(.sooty_stale_cache)))
  }

  invisible(data.frame(
    path          = path,
    exists        = pexists,
    cache_allowed = cache_allowed,
    modified      = if (pexists) file.mtime(path) else as.POSIXct(NA),
    age_days      = if (pexists) round(as.numeric(Sys.time() - file.mtime(path), units = "days"), 1) else NA_real_,
    bundled_rows  = nrow(.sooty_stale_cache)
  ))
}
