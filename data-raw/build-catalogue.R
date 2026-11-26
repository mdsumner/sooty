## data-raw/build-catalogue.R
##
## Rebuild the curated catalogue (one row per file: Bucket, Key, Host,
## Protocol, date, Dataset) from anonymous listings of the public stores the
## files live in. No credentials are needed.
##
##   Rscript data-raw/build-catalogue.R [output.parquet]
##
## writes the catalogue to output.parquet (default
## data-raw/idea-curated-objects.parquet, not tracked) and, when run from the
## package root, to R/sysdata.rda as the bundled fallback. The Parquet file is
## what `.remote_url()` in R/000-cache.R serves to installed copies: upload it
## there after a rebuild.
##
## History. Until 2025-08 the catalogue was built on Pawsey from the idea-*
## buckets (see 00-archive/pawsey-aad/acacia/curated_listing.R). Those buckets
## are no longer public. Their derived GeoTIFFs were copied on 2026-04-02 into
## prefixes of the public bucket `aad-derived` and are not updated there, and
## their mirrors of publisher netCDF were not kept. So each dataset is now
## listed from where it is public today:
##
##  - archive: the frozen copies under aad-derived/ (Pawsey)
##  - live:    the publisher, or a store that is still fed
##  - index:   the files a raad.virtualize store reads (its grist catalog)
##
## A dataset with both takes the archive first and the live source for later
## dates. `Bucket` and `Key` are the first path segment and the rest of the
## URL, whatever the host.

suppressPackageStartupMessages({
  library(arrow)
  library(curl)
})
invisible(Sys.setlocale("LC_TIME", "C"))  ## English month names in Bremen paths

PAWSEY <- "https://projects.pawsey.org.au/aad-derived"
SOURCECOOP <- "https://data.source.coop/ausantarctic"
## the indexes of raad.virtualize (drafts: this moves when they go to production)
RV_INDEX <- "https://data.source.coop/ausantarctic/ausantarctic-scratch"
NOAA_OISST <- "https://noaa-cdr-sea-surface-temp-optimum-interpolation-pds.s3.amazonaws.com"
## the bucket of a CMEMS product's native files is the `native_url` column of
## the cmemsarco catalog (hypertidy/cmemsarco)
CMEMS_NATIVE <- "https://s3.waw3-1.cloudferro.com/mdl-native-07"
BREMEN <- "https://data.seaice.uni-bremen.de"
REMSS <- "https://data.remss.com"

## listings ---------------------------------------------------------------

fetch <- function(url) {
  res <- curl::curl_fetch_memory(url)
  if (res$status_code != 200) stop(sprintf("HTTP %d: %s", res$status_code, url))
  rawToChar(res$content)
}

## many pages at once; NA for one that is not there
fetch_all <- function(urls) {
  out <- rep(NA_character_, length(urls))
  pool <- curl::new_pool(host_con = 4)
  for (i in seq_along(urls)) local({
    i <- i
    curl::multi_add(curl::new_handle(url = urls[i]), pool = pool,
      done = function(res) if (res$status_code == 200) out[i] <<- rawToChar(res$content),
      fail = function(msg) NULL)
  })
  curl::multi_run(pool = pool)
  out
}

xml_values <- function(x, tag) {
  m <- regmatches(x, gregexpr(sprintf("<%s>[^<]*</%s>", tag, tag), x))[[1]]
  gsub("<[^>]+>", "", m)
}

s3_page <- function(bucket_url, prefix, token = NULL, delimiter = NULL) {
  u <- sprintf("%s?list-type=2&max-keys=1000&prefix=%s", bucket_url, utils::URLencode(prefix, reserved = TRUE))
  if (!is.null(delimiter)) u <- paste0(u, "&delimiter=", delimiter)
  if (!is.null(token)) u <- paste0(u, "&continuation-token=", utils::URLencode(token, reserved = TRUE))
  fetch(u)
}

## every object URL under a prefix (anonymous ListObjectsV2)
s3_urls <- function(bucket_url, prefix) {
  keys <- character()
  token <- NULL
  repeat {
    x <- s3_page(bucket_url, prefix, token)
    keys <- c(keys, xml_values(x, "Key"))
    token <- xml_values(x, "NextContinuationToken")
    if (!length(token)) break
  }
  message(sprintf("  %6d objects  %s/%s", length(keys), bucket_url, prefix))
  paste(bucket_url, keys, sep = "/")
}

s3_prefixes <- function(bucket_url, prefix) {
  setdiff(xml_values(s3_page(bucket_url, prefix, delimiter = "/"), "Prefix"), prefix)
}

## file URLs linked from directory index pages
index_urls <- function(pages) {
  html <- fetch_all(pages)
  unlist(lapply(which(!is.na(html)), function(i) {
    href <- regmatches(html[i], gregexpr('href="[^"?]+"', html[i], ignore.case = TRUE))[[1]]
    href <- sub('"$', "", sub('^[^"]*"', "", href))
    host <- sub("^(https?://[^/]+)/.*", "\\1", pages[i])
    ifelse(grepl("^/", href), paste0(host, href), paste0(pages[i], href))
  }))
}

## the files behind a raad.virtualize store, from its grist catalog (one row
## per date and array, `source` the file). Following an index keeps a dataset
## here on whichever copy raad.virtualize reads: the publisher's today, a
## production copy later.
index_sources <- function(store) {
  f <- tempfile(fileext = ".parquet")
  on.exit(unlink(f))
  curl::curl_download(sprintf("%s/%s/grist/catalog.parquet", RV_INDEX, store), f)
  urls <- unique(sub("^/vsicurl/", "", arrow::read_parquet(f, col_select = "source")$source))
  message(sprintf("  %6d files    %s/%s", length(urls), RV_INDEX, store))
  urls
}

## catalogue rows -----------------------------------------------------------

## rows of one dataset from the URLs matching `pattern`: the date is read
## from the file name (`date_pattern` has one group; `pad` completes a month
## or a year to YYYYMMDD). One file per date, the first in key order, a
## preliminary file last.
dataset <- function(name, urls, pattern, date_pattern = "([0-9]{8})", pad = "") {
  urls <- urls[grepl(pattern, urls)]
  if (!length(urls)) stop("no files for dataset: ", name)
  m <- regmatches(urls, regexec("^(https?://[^/]+)/([^/]+)/(.*)$", urls))
  d <- data.frame(Bucket = vapply(m, `[`, "", 3), Key = vapply(m, `[`, "", 4),
                  Host = vapply(m, `[`, "", 2), Protocol = "/vsicurl",
                  stringsAsFactors = FALSE)
  stamp <- regmatches(basename(urls), regexec(date_pattern, basename(urls)))
  d$date <- as.POSIXct(strptime(paste0(vapply(stamp, `[`, "", 2), pad), "%Y%m%d", tz = "UTC"))
  d$Dataset <- name
  if (anyNA(d$date)) stop("unparsed dates in dataset: ", name)
  d <- d[order(grepl("preliminary", d$Key), d$Key, method = "radix"), ]
  d <- d[!duplicated(d$date), ]
  d[order(d$date), ]
}

## the archive, then the live source for the dates after it
extend <- function(archive, live) {
  rbind(archive, live[live$date > max(archive$date), ])
}

months_since <- function(date) {
  seq(as.Date(format(date, "%Y-%m-01")), Sys.Date(), by = "1 month")
}

## sources ------------------------------------------------------------------

message("listing Pawsey aad-derived")
p_amsr <- s3_urls(PAWSEY, "idea-amsr2-asi-s3125/")
p_esacci <- s3_urls(PAWSEY, "idea-esacci/")
p_esacci_cog <- s3_urls(PAWSEY, "esacci-oc/")
p_oisst <- s3_urls(PAWSEY, "idea-oisst/")
p_sealevel <- s3_urls(PAWSEY, "sealevel-glo-phy-tif/")

message("listing source.coop, NOAA, CMEMS")
sc_ghrsst <- s3_urls(SOURCECOOP, "ghrsst-mur-v2/")
noaa_oisst <- s3_urls(NOAA_OISST, "data/v2.1/avhrr/")
## altimetry netCDF: the latest version of the 0.125 degree daily dataset of
## the reprocessed (MY) and near real time (NRT) products
cmems_latest <- function(product) {
  p <- s3_prefixes(CMEMS_NATIVE, sprintf("native/%s/", product))
  p <- grep("_allsat-l4-duacs-0\\.125deg_P1D_[0-9]{6}/$", p, value = TRUE)
  s3_urls(CMEMS_NATIVE, max(p))
}
cmems_ssh <- c(cmems_latest("SEALEVEL_GLO_PHY_L4_MY_008_047"), cmems_latest("SEALEVEL_GLO_PHY_L4_NRT_008_046"))

catalogue <- list()

## sea surface temperature
catalogue$ghrsst <- dataset("ghrsst-tif", sc_ghrsst, "JPL-L4_GHRSST-SSTfnd-MUR-GLOB-v02\\.0-fv04\\.1_analysed_sst\\.tif$")
catalogue$oisst <- dataset("oisst-avhrr-v02r01", noaa_oisst, "oisst-avhrr-v02r01\\.[0-9]{8}(_preliminary)?\\.nc$")
## the YYYY/MM tree, as before (longitude -180 to 180; nothing from 2020-02-16
## to 2025-05, a gap of the conversion). The bucket root holds a complete
## series on the native 0 to 360 grid.
catalogue$oisst_tif <- dataset("oisst-tif", p_oisst, "idea-oisst/[0-9]{4}/[0-9]{2}/oisst-avhrr-v02r01\\.[0-9]{8}(_preliminary)?_sst\\.tif$")

## sea ice, University of Bremen
message("listing Bremen")
amsr <- dataset("antarctica-amsr2-asi-s3125-tif", p_amsr,
                "/seaice\\.uni-bremen\\.de/data/amsr2/asi_daygrid_swath/s3125/.*Antarctic3125/asi-AMSR2-s3125-[0-9]{8}-v5\\.4\\.tif$")
amsr_pages <- sprintf("%s/amsr2/asi_daygrid_swath/s3125/%s/Antarctic3125/", BREMEN,
                      tolower(format(months_since(max(amsr$date)), "%Y/%b")))
catalogue$amsr <- extend(amsr, dataset("antarctica-amsr2-asi-s3125-tif", index_urls(amsr_pages), "asi-AMSR2-s3125-[0-9]{8}-v5\\.4\\.tif$"))
smos <- index_urls(sprintf("%s/smos/tif/", BREMEN))
for (hem in c("north", "south")) {
  id <- sprintf("BREMEN-SEAICE-SMOS-%s", hem)
  pattern <- sprintf("/smos/tif/[0-9]{8}_hv%s__l1c\\.tif$", hem)
  catalogue[[id]] <- extend(dataset(id, p_amsr, pattern), dataset(id, smos, pattern))
}

## sea ice, 25 km polar stereographic. These ids listed NSIDC-0051 and
## NSIDC-0081 (NASA Team), which NSIDC serves only to a login; they now list
## the NOAA/NSIDC climate data record G02202 v6 on the same grids, the files
## that raad.virtualize indexes (variable cdr_seaice_conc).
message("reading raad.virtualize indexes")
for (hem in c("north", "south")) {
  id <- sprintf("NSIDC_SEAICE_PS_%s25km", toupper(substr(hem, 1, 1)))
  catalogue[[id]] <- dataset(id, index_sources(sprintf("seaice/g02202-v6-daily-%s", hem)), "/G02202_V6/.*\\.nc$")
}

## wind, Remote Sensing Systems CCMP v3.1
message("listing RSS")
ccmp_pages <- sprintf("%s/ccmp/v03.1/%s/", REMSS, format(months_since(as.Date("1993-01-01")), "Y%Y/M%m"))
catalogue$ccmp <- dataset("ccmp-wind-product-v2", index_urls(ccmp_pages), "CCMP_Wind_Analysis_[0-9]{8}_V03\\.1_L4\\.nc$")

## ocean colour, ESA CCI v6.0 chlorophyll-a. Monthly and 5-day are the COGs
## that raad.virtualize keeps current; daily and annual are the archive.
esacci <- function(cadence, urls, ...) {
  dataset(sprintf("esacci-oc-l3s-chlor-a-merged-%s", cadence), urls,
          sprintf("/geographic/%s/chlor_a/.*\\.tif$", cadence), ...)
}
catalogue$chl_5day <- esacci("5day", p_esacci_cog)
catalogue$chl_monthly <- esacci("monthly", p_esacci_cog, "OCx-([0-9]{6})-fv", pad = "01")
catalogue$chl_daily <- esacci("daily", p_esacci)
## a year is dated 1 September, as it always was here
catalogue$chl_annual <- esacci("annual", p_esacci, "OCx-([0-9]{4})-fv", pad = "0901")

## altimetry
catalogue$ssh <- dataset("SEALEVEL_GLO_PHY_L4", cmems_ssh, "_allsat_phy_l4_[0-9]{8}_[0-9]{8}\\.nc$")
for (v in c("adt", "err_sla", "err_ugosa", "err_vgosa", "flag_ice", "sla", "ugos", "ugosa", "vgos", "vgosa")) {
  id <- sprintf("sealevel-%s-tif", v)
  catalogue[[id]] <- dataset(id, p_sealevel, sprintf("_[0-9]{8}_[0-9]{8}_%s\\.tif$", v))
}

curated <- do.call(rbind, catalogue)
rownames(curated) <- NULL

## write --------------------------------------------------------------------

args <- commandArgs(trailingOnly = TRUE)
out <- if (length(args)) args[1] else "data-raw/idea-curated-objects.parquet"
arrow::write_parquet(curated, out)
message(sprintf("%d rows, %d datasets: %s", nrow(curated), length(unique(curated$Dataset)), out))

if (file.exists("R/sysdata.rda") && file.exists("DESCRIPTION")) {
  .sooty_stale_cache <- curated
  ## an installed copy replaces a user cache older than this
  .sooty_stale_cache_built <- Sys.time()
  save(.sooty_stale_cache, .sooty_stale_cache_built, file = "R/sysdata.rda", compress = "bzip2")
  message("bundled: R/sysdata.rda")
}
