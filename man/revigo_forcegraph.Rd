% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/revigo_forcegraph.R
\name{revigo_forcegraph}
\alias{revigo_forcegraph}
\title{Generate forcegraph plot of revigo GO graph}
\usage{
revigo_forcegraph(data_dir)
}
\arguments{
\item{data_dir}{Directory to store revigo scripts and output files}
}
\value{
r2d3 plot
}
\description{
Forcegraph uses nodes and links from cytoscape map file.
}
\details{
If \link{add_path_genes} is called, hovering a node will show the logFC of significant genes in all GO terms
merged into the representative GO term in question. At most 70 upregulated (red) and 70 downregulated (blue)
genes with the largest absolute logFC are displayed.
If \code{scrape_revigo} is used with two analyses (see examples), revigo ontolgies where no merge occured
across analyses will be shades of orange (\code{analysis 0}) and green (\code{analysis 1}) while ontologies where a merge occured across analyses
will be shades of purple. For tooltip heatmaps with two analyses, the 70 up-regulated genes shown are up
in the analysis of the hovered node (analysis 0 for merged nodes), prioritizing the inclusion of genes differentially
expressed in both analyses. The 70 down-regulated genes shown are chosen similarly.
}
\examples{

# single analysis
data(go_up2)
data_dir1 <- tempdir()
scrape_revigo(data_dir1, go_up2)
revigo_forcegraph(data_dir1)

# two analyses
data(go_up1)
go_up1$analysis <- 0
go_up2$analysis <- 1
go_up <- rbind(go_up1, go_up2)

data_dir2 <- tempdir()
scrape_revigo(data_dir2, go_up)
revigo_forcegraph(data_dir2)

}
\seealso{
\link{add_path_genes} to enable heatplots on hover.
}
