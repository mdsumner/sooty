
<!-- README.md is generated from README.Rmd. Please edit that file -->

# sooty <img src="man/figures/hex-sooty.png" align="right" height="188" />

<!-- badges: start -->

[![R-CMD-check](https://github.com/mdsumner/sooty/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/mdsumner/sooty/actions/workflows/R-CMD-check.yaml)
[![CRAN
status](https://www.r-pkg.org/badges/version/sooty)](https://CRAN.R-project.org/package=sooty)
<!-- badges: end -->

The goal of sooty is to read data of interest to Southern Ocean
research.

At the moment we only return lists of files available in object storage,
but future versions will provide direct access to the data in these
files with helper functions defined here.

To see what files we have in object storage, use

``` r
library(sooty)
(files <- tibble::as_tibble(sooty_files()))
#> # A tibble: 65,753 × 5
#>    date                source                              Bucket Key   protocol
#>    <dttm>              <chr>                               <chr>  <chr> <chr>   
#>  1 1981-09-01 00:00:00 /vsis3/idea-10.7289-v5sq8xb5/www.n… idea-… www.… /vsis3  
#>  2 1981-09-02 00:00:00 /vsis3/idea-10.7289-v5sq8xb5/www.n… idea-… www.… /vsis3  
#>  3 1981-09-03 00:00:00 /vsis3/idea-10.7289-v5sq8xb5/www.n… idea-… www.… /vsis3  
#>  4 1981-09-04 00:00:00 /vsis3/idea-10.7289-v5sq8xb5/www.n… idea-… www.… /vsis3  
#>  5 1981-09-05 00:00:00 /vsis3/idea-10.7289-v5sq8xb5/www.n… idea-… www.… /vsis3  
#>  6 1981-09-06 00:00:00 /vsis3/idea-10.7289-v5sq8xb5/www.n… idea-… www.… /vsis3  
#>  7 1981-09-07 00:00:00 /vsis3/idea-10.7289-v5sq8xb5/www.n… idea-… www.… /vsis3  
#>  8 1981-09-08 00:00:00 /vsis3/idea-10.7289-v5sq8xb5/www.n… idea-… www.… /vsis3  
#>  9 1981-09-09 00:00:00 /vsis3/idea-10.7289-v5sq8xb5/www.n… idea-… www.… /vsis3  
#> 10 1981-09-10 00:00:00 /vsis3/idea-10.7289-v5sq8xb5/www.n… idea-… www.… /vsis3  
#> # ℹ 65,743 more rows
```

These are all directly useable source identifiers that a GDAL-enabled
package can read.

In time we will provide helpers to pick specific data sets and open data
for a given date.

For now we only have manual handling, such as

``` r
library(terra)
#> terra 1.7.83
file <- files$source[which.max(files$date) ]
print(file)
#> [1] "/vsis3/idea-10.7289-v5sq8xb5/www.ncei.noaa.gov/data/sea-surface-temperature-optimum-interpolation/v2.1/access/avhrr/202412/oisst-avhrr-v02r01.20241207_preliminary.nc"

Sys.setenv(AWS_S3_ENDPOINT="projects.pawsey.org.au", 
           AWS_NO_SIGN_REQUEST="YES",
           GDAL_DISABLE_READDIR_ON_OPEN = "EMPTY_DIR")
rast(file)
#> class       : SpatRaster 
#> dimensions  : 720, 1440, 4  (nrow, ncol, nlyr)
#> resolution  : 0.25, 0.25  (x, y)
#> extent      : 0, 360, -90, 90  (xmin, xmax, ymin, ymax)
#> coord. ref. : lon/lat WGS 84 
#> sources     : oisst-avhrr-v02r01.20241207_preliminary.nc:sst  
#>               oisst-avhrr-v02r01.20241207_preliminary.nc:anom  
#>               oisst-avhrr-v02r01.20241207_preliminary.nc:err  
#>               oisst-avhrr-v02r01.20241207_preliminary.nc:ice  
#> varnames    : sst (Daily sea surface temperature) 
#>               anom (Daily sea surface temperature anomalies) 
#>               err (Estimated error standard deviation of analysed_sst) 
#>               ...
#> names       : sst_zlev=0, anom_zlev=0, err_zlev=0, ice_zlev=0 
#> unit        :    Celsius,     Celsius,    Celsius,          % 
#> time (days) : 2024-12-07
```

There are data sets like the 25km resolution south polar stereographic
sea ice concentration, available via `readnsidc25kmS()`:

``` r
library(sooty)
readnsidc25kmS()
#> class       : SpatRaster 
#> dimensions  : 332, 316, 1  (nrow, ncol, nlyr)
#> resolution  : 25000, 25000  (x, y)
#> extent      : -3950000, 3950000, -3950000, 4350000  (xmin, xmax, ymin, ymax)
#> coord. ref. : NSIDC Sea Ice Polar Stereographic South (EPSG:3412) 
#> source      : NSIDC0081_SEAICE_PS_S25km_20241207_v2.0.nc:F16_ICECON 
#> varname     : F16_ICECON (Sea Ice Concentration) 
#> name        :                 F16_ICECON 
#> unit        : Fraction between 0.0 - 1.0 
#> time (days) : 2024-12-07
```

You can immediately see what range of dates is available by setting
`latest = FALSE`:

``` r
readnsidc25kmS(latest = FALSE)
#> class       : SpatRaster 
#> dimensions  : 332, 316, 1  (nrow, ncol, nlyr)
#> resolution  : 25000, 25000  (x, y)
#> extent      : -3950000, 3950000, -3950000, 4350000  (xmin, xmax, ymin, ymax)
#> coord. ref. : NSIDC Sea Ice Polar Stereographic South (EPSG:3412) 
#> source      : NSIDC0051_SEAICE_PS_S25km_19781026_v2.0.nc:N07_ICECON 
#> varname     : N07_ICECON (Sea Ice Concentration) 
#> name        :                 N07_ICECON 
#> unit        : Fraction between 0.0 - 1.0 
#> time (days) : 1978-10-26
```

And, explore exactly what source files are available with the full
table:

``` r
files <- nsidc25kmSfiles()

range(files$date)
#> [1] "1978-10-26 UTC" "2024-12-07 UTC"
range(diff(files$date))  ## there are some gaps, it's every two days to start and some are missing
#> Time differences in days
#> [1]  1 42

diff(range(files$date))  ## the number of potential data days
#> Time difference of 16844 days

nrow(files)  ## the actual number of data days
#> [1] 15188
```

This is a very experimental begin at replacing
[raadtools](https://github.com/AustralianAntarcticDivision/raadtools)
with a package anyone can use.

Apart from north and south 25km sea ice we also have higher resolution
sea ice data for the southern hemisphere.

``` r
readamsr()
#> class       : SpatRaster 
#> dimensions  : 2656, 2528, 1  (nrow, ncol, nlyr)
#> resolution  : 3125, 3125  (x, y)
#> extent      : -3950000, 3950000, -3950000, 4350000  (xmin, xmax, ymin, ymax)
#> coord. ref. : WGS 84 / NSIDC Sea Ice Polar Stereographic South (EPSG:3976) 
#> source      : VRTDataset> 
#> name        : VRTDataset> 
#> time        : 2024-12-07 UTC
```

### Global SST 0.25 degree from 1982-current

``` r
readoisst()
#> class       : SpatRaster 
#> dimensions  : 720, 1440, 1  (nrow, ncol, nlyr)
#> resolution  : 0.25, 0.25  (x, y)
#> extent      : 0, 360, -90, 90  (xmin, xmax, ymin, ymax)
#> coord. ref. : lon/lat WGS 84 (EPSG:4326) 
#> source      : VRTDataset> 
#> name        : VRTDataset> 
#> time        : 2024-12-07 UTC
```

### Note for MacOS users (sadly)

On MacOS the best GDAL we can get is 3.5.3 which is sadly too old for
some of these NetCDF files (these can be worked around but I don’t want
to do that here).

At your own risk, we’ve had success installing GDAL latest.

    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" && brew install gdal --HEAD

We haven’t yet figured out what is the minimum version needed for this
package to work well with all the datasets, or how to get a particular
commit/tag/version (WIP).

## Code of Conduct

Please note that the idt project is released with a [Contributor Code of
Conduct](https://contributor-covenant.org/version/2/1/CODE_OF_CONDUCT.html).
By contributing to this project, you agree to abide by its terms.
