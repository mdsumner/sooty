# sooty 0.6.1

* Sooty cache is now never installed into user space during any
document/test/build/install/check processes, thanks to CRAN. 


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
