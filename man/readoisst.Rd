% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/oisst.R
\name{readoisst}
\alias{readoisst}
\title{Read Reynolds OISST (optimally interpolated sea surface temperature)}
\usage{
readoisst(date, gridspec = NULL, ..., latest = TRUE)
}
\arguments{
\item{date}{date or date-time (or string)}

\item{gridspec}{optional terra object for the target grid}

\item{...}{ignored currently}

\item{latest}{return most recent data if \code{TRUE}, else earliest data}
}
\value{
terra SpatRaster object
}
\description{
By default latest date is returned, set \code{latest = FALSE} to find earliest data.
}
\details{
By default the data is returned on the native grid, here global Pacific-view longlat (0,360). Use
\code{gridspec} to specify a different grid, i.e. \code{rast(res = 0.25)} is the equivalent grid
for Atlantic-view (-180, 180).
}
\examples{
readoisst("2000-04-01")

}
