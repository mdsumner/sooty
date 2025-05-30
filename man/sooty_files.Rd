% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/objects.R
\name{sooty_files}
\alias{sooty_files}
\title{Obtain object storage catalogues as a dataframe of file/object identifiers.}
\usage{
sooty_files(curated = TRUE)
}
\arguments{
\item{curated}{logical \code{TRUE} by default, set to \code{FALSE} to return raw object catalogue}
}
\value{
a data frame, see details
}
\description{
The object (file) catalogue of available sources is stored in Parquet format on Pawsey
object storage. This function retrieves the curated catalogue, or the raw catalogue.
}
\details{
In the curated case, the returned data frame has columns 'date', 'source' which are the main
useful fields, these describe the date of the data in the file, and its full URI (Uniform Resource Identifier) source on
S3 object storage. There are also fields 'Bucket', 'Key', and 'protocol' from which 'source' is
constructed.

The original publisher URI can be reconstructed by replacing the value of 'protocol' in 'source'
with 'https://'.

The public object URI can be reconstructed by replacing the value of 'protocol' in 'source' with
'https://projects.pawsey.org.au'.
}
\examples{
if (interactive()) {
  sooty_files(FALSE)
}

sooty_files()
}
