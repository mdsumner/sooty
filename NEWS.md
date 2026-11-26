# sooty 0.7.0

* The catalogue works again. The Pawsey buckets it listed (and the bucket that held the catalogue itself)
 are no longer public, so every source failed. Each dataset now points at where its files are public today:
 the `aad-derived` bucket on Pawsey, Source Cooperative, or the publisher (NOAA, Copernicus Marine,
 University of Bremen, Remote Sensing Systems). Dataset identifiers and the columns of `sooty_files()` are unchanged.

* These datasets are current again and are extended as their publishers add files: `ghrsst-tif`, `oisst-avhrr-v02r01`,
 `SEALEVEL_GLO_PHY_L4`, `NSIDC_SEAICE_PS_N25km`, `NSIDC_SEAICE_PS_S25km`, `antarctica-amsr2-asi-s3125-tif`,
 `BREMEN-SEAICE-SMOS-north`, `ccmp-wind-product-v2`, and the monthly and 5day `esacci-oc-l3s-chlor-a-merged-*`. The others are an archive that ends in 2025 (`oisst-tif`,
 the `sealevel-*-tif` family, daily and annual `esacci-oc-l3s-chlor-a-merged-*`). See the README for where to go next.

* Fixed `sealevel-sla-tif`, `sealevel-ugos-tif`, `sealevel-ugosa-tif`, `sealevel-vgos-tif` and `sealevel-vgosa-tif`,
 which listed the files of the error variables (`err_sla`, `err_ugosa`, `err_vgosa`) instead of their own.

* `SEALEVEL_GLO_PHY_L4` is now the 0.125 degree product throughout (reprocessed, then near real time). It was 0.25 degree
 before 2024-11-20.

* `NSIDC_SEAICE_PS_N25km` and `NSIDC_SEAICE_PS_S25km` now list a different product on the same grids: the NOAA/NSIDC
 climate data record of sea ice concentration (G02202 version 6, variable `cdr_seaice_conc`, a fraction from 0 to 1),
 daily from 1978-10-25, read from NSIDC. They listed NSIDC-0051 and NSIDC-0081, which NSIDC serves only to a login.
 The file list is that of the raad.virtualize index of the product.

* A failed update of the catalogue no longer removes the local cache (which made the first `sooty_files()` of a session
 fail). The cache is replaced only by a download that reads as the catalogue, a cache older than the catalogue bundled
 with the package is replaced by it, and the updated catalogue now comes from a release of the sooty repository.

* The catalogue is built by `data-raw/build-catalogue.R`, from anonymous listings of the public stores and from
 the indexes that raad.virtualize publishes.

# sooty 0.6.1

* Sooty cache is now never installed into user space during any
 examples / document / test / build / install / check processes, thanks to CRAN. 


# sooty 0.6.0

* A file cache is now stored internally in the package, installed to user cache space as a file,
 and this is checked for staleness once per session and updated if internet access is available. 
 
* Status of user cache can be checked with new function `sooty_cache_info()` which returns information
 about the location, age, and size of the cache. 

* The the non-curated catalogue is no longer exposed to exported functions. 

# sooty 0.5.0

* dataset() is now deprecated in favour of datasource()
 
* Created standalone function available_datasets(), and removed `@curated`, `@available_datasets` from the datasource object. 

* Now using more robust model of GDAL protocol and absolute URLs. 

* Added an S7 object to set dataset id and retrieve files. 

* Removed all read functionality. 

* Removed memoization. 

* Fix scaling mistake for AMSR ice. 

* Added 3.125km AMSR ice. 

# sooty 0.1.0 

* Initial CRAN version. 

* Renamed package. 

# idt 0.0.1

* Initial package functionality. 
