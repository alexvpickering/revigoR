% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/revigo_scatterplot.R
\name{revigo_scatterplot_original}
\alias{revigo_scatterplot_original}
\title{Revigo MDS plot}
\usage{
revigo_scatterplot_original(data_dir)
}
\arguments{
\item{data_dir}{directory with scraped revigo data}
}
\value{
ggplot object
}
\description{
Revigo MDS plot
}
\examples{

data(go_up1)
data_dir <- tempdir()
scrape_revigo(data_dir, go_up1)
revigo_scatterplot_original(data_dir)

}
