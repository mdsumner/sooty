utils::globalVariables(".data")

.onLoad <- function(libname, pkgname) {
  .objects <<- memoise::memoize(.objects, cache = cachem::cache_mem(max_age = 3600))
  .curated_objects <<- memoise::memoize(.curated_objects, cache = cachem::cache_mem(max_age = 3600))
  sooty_files <<- memoise::memoize(sooty_files, cache = cachem::cache_mem(max_age = 3600))
}

