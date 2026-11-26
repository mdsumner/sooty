.sooty_cache <- new.env(parent = emptyenv())

.cache_dir <- function() {
  getOption("sooty.cache.path", default = tools::R_user_dir("sooty", which = "cache"))
}

.cache_path <- function() {
  file.path(.cache_dir(), "idea-curated-objects.parquet")
}

.remote_url <- function() {
  "https://github.com/mdsumner/sooty/releases/download/catalogue/idea-curated-objects.parquet"
}

# Fetch the catalogue beside the cache and replace the cache only with a file
# that reads as the catalogue: a failed or partial download leaves the cache
# as it was.
#' @importFrom arrow read_parquet
.download_to_cache <- function() {
  path <- .cache_path()
  dir.create(dirname(path), showWarnings = FALSE, recursive = TRUE)
  tmp <- tempfile(tmpdir = dirname(path), fileext = ".parquet")
  on.exit(unlink(tmp), add = TRUE)
  ok <- tryCatch({
    suppressWarnings(utils::download.file(.remote_url(), destfile = tmp, quiet = TRUE, mode = "wb"))
    all(names(.sooty_stale_cache) %in% names(arrow::read_parquet(tmp, as_data_frame = FALSE)))
  }, error = function(e) FALSE)
  if (ok) {
    file.rename(tmp, path)
  } else {
    message("sooty: the object catalogue could not be updated, using the local copy")
  }
  invisible(ok)
}

# Seed user cache from sysdata if missing, or older than the bundled
# catalogue (a cache left by an earlier version) — no internet required.
# The file takes the time the bundled catalogue was built, so that the
# staleness check still looks for a newer one.
#' @importFrom arrow write_parquet
.seed_cache_from_sysdata <- function() {
  path <- .cache_path()
  if (file.exists(path) && file.mtime(path) >= .sooty_stale_cache_built) return(invisible(NULL))
  dir.create(dirname(path), showWarnings = FALSE, recursive = TRUE)
  arrow::write_parquet(.sooty_stale_cache, path)
  Sys.setFileTime(path, .sooty_stale_cache_built)
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
.read_parquet <- function() {
  if (isFALSE(getOption("sooty.allow.cache", default = TRUE))) {
    return(tibble::as_tibble(.sooty_stale_cache))
  }
  .seed_cache_from_sysdata()
  .check_staleness()
  ## a cache that cannot be read is no reason to fail
  tryCatch(tibble::as_tibble(arrow::read_parquet(.cache_path())),
           error = function(e) tibble::as_tibble(.sooty_stale_cache))
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
#' op <- options("sooty.allow.cache" = FALSE)
#' sooty_cache_info()
#' options(op)
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
