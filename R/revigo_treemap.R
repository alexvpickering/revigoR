#' Plot Revigo Treemap
#'
#' @inheritParams scrape_revigo
#' @param ... additional arguments to \code{\link[treemap]{treemap}}
#'
#' @return treemap plot
#' @export
#'
#' @examples
#'
#' data(go_up1)
#' data_dir <- tempdir()
#' scrape_revigo(data_dir, go_up1)
#' revigo_treemap(data_dir, palette = "Accent", border.lwds = c(1,1), border.col = '#333333', fontcolor.labels = c('#333333', 'white'))
#'
revigo_treemap <- function(data_dir, ...) {

  stuff <- read.csv(file.path(data_dir, 'tree_map.csv'), skip = 4)
  stuff$frequencyInDb <- as.numeric(gsub('%', '', stuff$frequencyInDb))
  stuff$abslog10pvalue <- abs(stuff$log10pvalue)

  treemap::treemap(
    stuff,
    index = c("representative","description"),
    vSize = "abslog10pvalue",
    type = "categorical",
    vColor = "representative",
    title = "REVIGO Gene Ontology treemap",
    inflate.labels = FALSE,      # set this to TRUE for space-filling group labels - good for posters
    lowerbound.cex.labels = 0,   # try to draw as many labels as possible (still, some small squares may not get a label)
    bg.labels = "#FFFFFFAA",     # define background color of group labels
    # "#CCCCCC00" is fully transparent, "#CCCCCCAA" is semi-transparent grey, NA is opaque
    position.legend = "none",
    ...
  )

}
