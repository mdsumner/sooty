
<!-- README.md is generated from README.Rmd. Please edit that file -->

# sooty <img src="man/figures/hex-sooty.png" align="right" height="188" width="214" />

<!-- badges: start -->

[![R-CMD-check](https://github.com/mdsumner/sooty/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/mdsumner/sooty/actions/workflows/R-CMD-check.yaml)
[![CRAN
status](https://www.r-pkg.org/badges/version/sooty)](https://CRAN.R-project.org/package=sooty)
<!-- badges: end -->

The goal of sooty is to provide access to data of relevance to Southern
Ocean research.

To see what files we know about in object storage, use

``` r
library(sooty)
(files <- sooty_files())
#> # A tibble: 232,798 × 7
#>    date                source                Dataset Bucket Key   Protocol Host 
#>    <dttm>              <chr>                 <chr>   <chr>  <chr> <chr>    <chr>
#>  1 1981-09-01 00:00:00 /vsicurl/https://pro… oisst-… idea-… www.… /vsicurl http…
#>  2 1981-09-02 00:00:00 /vsicurl/https://pro… oisst-… idea-… www.… /vsicurl http…
#>  3 1981-09-03 00:00:00 /vsicurl/https://pro… oisst-… idea-… www.… /vsicurl http…
#>  4 1981-09-04 00:00:00 /vsicurl/https://pro… oisst-… idea-… www.… /vsicurl http…
#>  5 1981-09-05 00:00:00 /vsicurl/https://pro… oisst-… idea-… www.… /vsicurl http…
#>  6 1981-09-06 00:00:00 /vsicurl/https://pro… oisst-… idea-… www.… /vsicurl http…
#>  7 1981-09-07 00:00:00 /vsicurl/https://pro… oisst-… idea-… www.… /vsicurl http…
#>  8 1981-09-08 00:00:00 /vsicurl/https://pro… oisst-… idea-… www.… /vsicurl http…
#>  9 1981-09-09 00:00:00 /vsicurl/https://pro… oisst-… idea-… www.… /vsicurl http…
#> 10 1981-09-10 00:00:00 /vsicurl/https://pro… oisst-… idea-… www.… /vsicurl http…
#> # ℹ 232,788 more rows
```

The main columns of interest are `date` and `source` and `Dataset`, the
`source` is a directly useable source identifier that a GDAL-enabled
package can read. (See examples below).

We can get a very simple model of a “logical dataset” by honing in one
`Dataset` in particular. First let’s make a summary from everything:

``` r
library(sooty)
sooty_files() |> 
     dplyr::mutate(date = as.Date(date)) |>  dplyr::group_by(Dataset) |> 
     dplyr::summarize(earliest = min(date), latest = max(date), n = dplyr::n()) |> 
     dplyr::arrange(Dataset, earliest)
#> # A tibble: 24 × 4
#>    Dataset                             earliest   latest         n
#>    <chr>                               <date>     <date>     <int>
#>  1 BREMEN-SEAICE-SMOS-north            2010-05-01 2025-08-24  5569
#>  2 BREMEN-SEAICE-SMOS-south            2010-10-01 2016-05-03    12
#>  3 NSIDC_SEAICE_PS_N25km               1978-10-26 2025-08-24 15448
#>  4 NSIDC_SEAICE_PS_S25km               1978-10-26 2025-08-24 15448
#>  5 SEALEVEL_GLO_PHY_L4                 1993-01-01 2025-08-25 11811
#>  6 antarctica-amsr2-asi-s3125-tif      2012-07-02 2025-08-24  4791
#>  7 ccmp-wind-product-v2                1993-01-02 2024-08-31 11552
#>  8 esacci-oc-l3s-chlor-a-merged-5day   1997-09-03 2025-03-27  2019
#>  9 esacci-oc-l3s-chlor-a-merged-annual 1997-09-01 2024-09-01    28
#> 10 esacci-oc-l3s-chlor-a-merged-daily  1997-09-04 2025-03-31 10045
#> # ℹ 14 more rows
```

``` r
library(terra)
#> terra 1.8.97
file <- files$source[which.max(files$date) ]
print(file)
#> [1] "/vsicurl/https://data.source.coop/ausantarctic/ghrsst-mur-v2/2025/08/29/20250829090000-JPL-L4_GHRSST-SSTfnd-MUR-GLOB-v02.0-fv04.1_analysed_sst.tif"


rast(file)
#> class       : SpatRaster 
#> size        : 17999, 36000, 1  (nrow, ncol, nlyr)
#> resolution  : 0.01, 0.01  (x, y)
#> extent      : -179.995, 180.005, -89.995, 89.995  (xmin, xmax, ymin, ymax)
#> coord. ref. : lon/lat WGS 84 (EPSG:4326) 
#> source      : 20250829090000-JPL-L4_GHRSST-SSTfnd-MUR-GLOB-v02.0-fv04.1_analysed_sst.tif 
#> name        : 20250829090000-JPL-L4_GHRSST-S~GLOB-v02.0-fv04.1_analysed_sst
```

The available datasets can be found from the table.

``` r
dplyr::distinct(sooty_files(), Dataset)
#> # A tibble: 24 × 1
#>    Dataset                       
#>    <chr>                         
#>  1 oisst-avhrr-v02r01            
#>  2 SEALEVEL_GLO_PHY_L4           
#>  3 NSIDC_SEAICE_PS_S25km         
#>  4 NSIDC_SEAICE_PS_N25km         
#>  5 antarctica-amsr2-asi-s3125-tif
#>  6 ghrsst-tif                    
#>  7 ccmp-wind-product-v2          
#>  8 BREMEN-SEAICE-SMOS-south      
#>  9 BREMEN-SEAICE-SMOS-north      
#> 10 oisst-tif                     
#> # ℹ 14 more rows
```

There are data sets like the 25km resolution south polar stereographic
sea ice concentration, available via the dataset identifier \`:

``` r
icefiles <- sooty_files() |> dplyr::filter(Dataset == "NSIDC_SEAICE_PS_S25km")
dplyr::glimpse(icefiles)
#> Rows: 15,448
#> Columns: 7
#> $ date     <dttm> 1978-10-26, 1978-10-28, 1978-10-30, 1978-11-01, 1978-11-03, …
#> $ source   <chr> "/vsicurl/https://projects.pawsey.org.au/idea-10.5067-mpyg15w…
#> $ Dataset  <chr> "NSIDC_SEAICE_PS_S25km", "NSIDC_SEAICE_PS_S25km", "NSIDC_SEAI…
#> $ Bucket   <chr> "idea-10.5067-mpyg15waa4wx", "idea-10.5067-mpyg15waa4wx", "id…
#> $ Key      <chr> "n5eil01u.ecs.nsidc.org/PM/NSIDC-0051.002/1978.10.26/NSIDC005…
#> $ Protocol <chr> "/vsicurl", "/vsicurl", "/vsicurl", "/vsicurl", "/vsicurl", "…
#> $ Host     <chr> "https://projects.pawsey.org.au", "https://projects.pawsey.or…
```

You can immediately see what range of dates is available:

``` r
range(icefiles$date)
#> [1] "1978-10-26 UTC" "2025-08-24 UTC"
```

And, explore exactly what source files are available:

``` r

range(diff(icefiles$date))  ## there are some gaps, it's every two days to start and some are missing
#> Time differences in days
#> [1]  1 42

diff(range(icefiles$date))  ## the number of potential data days
#> Time difference of 17104 days

nrow(icefiles)  ## the actual number of data days
#> [1] 15448
```

This is a very experimental begin at replacing
[raadtools](https://github.com/AustralianAntarcticDivision/raadtools)
with a package anyone can use.

We can read from the datasets with a GDAL-ready package, such as terra.
But note that we need to set a configuration first, and we need to unset
it after, this is WIP.

``` r
amsrfiles <- dataset("antarctica-amsr2-asi-s3125-tif")@source
#> Warning in dataset("antarctica-amsr2-asi-s3125-tif"): 'dataset' is deprecated.
#> Use 'datasource' instead.
#> See help("Deprecated")
library(terra)

r <- rast(tail(amsrfiles$source, 1))
dim(r); substr(crs(r), 0, 98); ext(r)
#> [1] 2656 2528    1
#> [1] "PROJCRS[\"WGS 84 / NSIDC Sea Ice Polar Stereographic South\",\n    BASEGEOGCRS[\"WGS 84\",\n        ENSE"
#> SpatExtent : -3950000, 3950000, -3950000, 4350000 (xmin, xmax, ymin, ymax)
r[r > 100] <- NA
plot(r[[nlyr(r)]] * 1, main = format(max(icefiles$date)))
ghrsst <- datasource("ghrsst-tif")
sstfile <- ghrsst@source$source[match(max(icefiles$date), ghrsst@source$date)]
sst <- rast(sprintf("vrt://%s?ovr=4", sstfile))
ct <- as.contour(crop(sst, ext(-180, 180, -90, -40)))
plot(project(ct, crs(r)), add = TRUE, col = "hotpink")
```

<img src="man/figures/README-unnamed-chunk-2-1.png" width="100%" />

That should be the state of the sea ice in the Southern Ocean at the
latest available date, sea ice concentration from passive microwave at
3.125km resolution, by the AWI artist sea ice group.

## About the columns in `sooty_files()`

`Dataset` is the main grouping value, and files from different
`Dataset`s are otherwise non-relatable, be it by file format, available
variable/s, grid specification (spatial extent and resolution), or
temporal organization. We guarantee that within a Dataset, the files are
ordered and unique by date(-time) and that they are exactly relatable
spatially and (mostly, or usually also) by variable/s. The time series
may not be regular or complete, but usually is.

We retain the component parts of `source`, as `Bucket`, `Key`,
`Protocol`, and `Host` as this is object storage and these are the
separable parts of addressing objects in different ways, and we’ve
reserved that for future usage. (We use `https://` protocol by default
to avoid any required configurations). Get in touch if you have any
questions about this.

## S7 object control

We have an in-progress class for dataset handling. Create a ‘dataset()’
and set an id.

``` r
ds <- dataset()
#> Warning in dataset(): 'dataset' is deprecated.
#> Use 'datasource' instead.
#> See help("Deprecated")
ds@id <- "NSIDC_SEAICE_PS_S25km"
ds
#> <sooty::dataset>
#>  @ id     : chr "NSIDC_SEAICE_PS_S25km"
#>  @ n      : int 15448
#>  @ mindate: POSIXct[1:1], format: "1978-10-26"
#>  @ maxdate: POSIXct[1:1], format: "2025-08-24"
#>  @ source : tibble [15,448 × 7] (S3: tbl_df/tbl/data.frame)
#>  $ date    : POSIXct[1:15448], format: "1978-10-26" "1978-10-28" ...
#>  $ source  : chr [1:15448] "/vsicurl/https://projects.pawsey.org.au/idea-10.5067-mpyg15waa4wx/n5eil01u.ecs.nsidc.org/PM/NSIDC-0051.002/1978"| __truncated__ "/vsicurl/https://projects.pawsey.org.au/idea-10.5067-mpyg15waa4wx/n5eil01u.ecs.nsidc.org/PM/NSIDC-0051.002/1978"| __truncated__ "/vsicurl/https://projects.pawsey.org.au/idea-10.5067-mpyg15waa4wx/n5eil01u.ecs.nsidc.org/PM/NSIDC-0051.002/1978"| __truncated__ "/vsicurl/https://projects.pawsey.org.au/idea-10.5067-mpyg15waa4wx/n5eil01u.ecs.nsidc.org/PM/NSIDC-0051.002/1978"| __truncated__ ...
#>  $ Dataset : chr [1:15448] "NSIDC_SEAICE_PS_S25km" "NSIDC_SEAICE_PS_S25km" "NSIDC_SEAICE_PS_S25km" "NSIDC_SEAICE_PS_S25km" ...
#>  $ Bucket  : chr [1:15448] "idea-10.5067-mpyg15waa4wx" "idea-10.5067-mpyg15waa4wx" "idea-10.5067-mpyg15waa4wx" "idea-10.5067-mpyg15waa4wx" ...
#>  $ Key     : chr [1:15448] "n5eil01u.ecs.nsidc.org/PM/NSIDC-0051.002/1978.10.26/NSIDC0051_SEAICE_PS_S25km_19781026_v2.0.nc" "n5eil01u.ecs.nsidc.org/PM/NSIDC-0051.002/1978.10.28/NSIDC0051_SEAICE_PS_S25km_19781028_v2.0.nc" "n5eil01u.ecs.nsidc.org/PM/NSIDC-0051.002/1978.10.30/NSIDC0051_SEAICE_PS_S25km_19781030_v2.0.nc" "n5eil01u.ecs.nsidc.org/PM/NSIDC-0051.002/1978.11.01/NSIDC0051_SEAICE_PS_S25km_19781101_v2.0.nc" ...
#>  $ Protocol: chr [1:15448] "/vsicurl" "/vsicurl" "/vsicurl" "/vsicurl" ...
#>  $ Host    : chr [1:15448] "https://projects.pawsey.org.au" "https://projects.pawsey.org.au" "https://projects.pawsey.org.au" "https://projects.pawsey.org.au" ...

ds@source
#> # A tibble: 15,448 × 7
#>    date                source                Dataset Bucket Key   Protocol Host 
#>    <dttm>              <chr>                 <chr>   <chr>  <chr> <chr>    <chr>
#>  1 1978-10-26 00:00:00 /vsicurl/https://pro… NSIDC_… idea-… n5ei… /vsicurl http…
#>  2 1978-10-28 00:00:00 /vsicurl/https://pro… NSIDC_… idea-… n5ei… /vsicurl http…
#>  3 1978-10-30 00:00:00 /vsicurl/https://pro… NSIDC_… idea-… n5ei… /vsicurl http…
#>  4 1978-11-01 00:00:00 /vsicurl/https://pro… NSIDC_… idea-… n5ei… /vsicurl http…
#>  5 1978-11-03 00:00:00 /vsicurl/https://pro… NSIDC_… idea-… n5ei… /vsicurl http…
#>  6 1978-11-05 00:00:00 /vsicurl/https://pro… NSIDC_… idea-… n5ei… /vsicurl http…
#>  7 1978-11-07 00:00:00 /vsicurl/https://pro… NSIDC_… idea-… n5ei… /vsicurl http…
#>  8 1978-11-09 00:00:00 /vsicurl/https://pro… NSIDC_… idea-… n5ei… /vsicurl http…
#>  9 1978-11-11 00:00:00 /vsicurl/https://pro… NSIDC_… idea-… n5ei… /vsicurl http…
#> 10 1978-11-13 00:00:00 /vsicurl/https://pro… NSIDC_… idea-… n5ei… /vsicurl http…
#> # ℹ 15,438 more rows
```

## Code of Conduct

Please note that the idt project is released with a [Contributor Code of
Conduct](https://contributor-covenant.org/version/2/1/CODE_OF_CONDUCT.html).
By contributing to this project, you agree to abide by its terms.
