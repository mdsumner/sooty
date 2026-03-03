.sooty_cache <- new.env(parent = emptyenv())

.cache_dir <- function() {
  tools::R_user_dir("sooty", which = "cache")
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
#' @importFrom arrow  read_parquet
.objects <- function() {
  sourcefile <- "https://projects.pawsey.org.au/idea-objects/idea-objects.parquet"
  tibble::as_tibble(arrow::read_parquet(sourcefile))
}

.curated_objects <- function() {
  out <- .read_parquet()
  out
}

.read_parquet <- function() {
  .seed_cache_from_sysdata()
  .check_staleness()
  tibble::as_tibble(arrow::read_parquet(.cache_path()))
}



#' Show sooty cache status
#'
#' @return A data frame (invisibly) with cache details.
#' @export
#' @examples
#' sooty_cache_info()
sooty_cache_info <- function() {
  path <- .cache_path()
  pexists <- file.exists(path)

  message(sprintf("Cache directory: %s\n\n", .cache_dir()))
  message("  curated catalogue:\n")
  if (pexists) {
    age <- round(as.numeric(Sys.time() - file.mtime(path), units = "days"), 1)
    message(sprintf("    modified : %s (%.1f days ago)\n", format(file.mtime(path)), age))
  } else {
    message("    not yet written to user cache (sysdata fallback available)\n")
  }
  message(sprintf("    bundled  : %d rows (ships with package)\n", nrow(.sooty_stale_cache)))

  invisible(data.frame(
    path     = path,
    exists   = pexists,
    modified = if (pexists) file.mtime(path) else as.POSIXct(NA),
    age_days = if (pexists) round(as.numeric(Sys.time() - file.mtime(path), units = "days"), 1) else NA_real_,
    bundled_rows = nrow(.sooty_stale_cache)
  ))
}
