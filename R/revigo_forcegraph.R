
#' Generate forcegraph plot of revigo GO graph
#'
#' Forcegraph uses nodes and links from cytoscape map file.
#'
#' If \link{add_path_genes} is called, hovering a node will show the logFC of significant genes in all GO terms
#' merged into the representative GO term in question. At most 70 upregulated (red) and 70 downregulated (blue)
#' genes with the largest absolute logFC are displayed.
#' If \code{scrape_revigo} is used with two analyses (see examples), revigo ontolgies where no merge occured
#' across analyses will be shades of orange (\code{analysis 0}) and green (\code{analysis 1}) while ontologies where a merge occured across analyses
#' will be shades of purple. For tooltip heatmaps with two analyses, the 70 up-regulated genes shown are up
#' in the analysis of the hovered node (analysis 0 for merged nodes), prioritizing the inclusion of genes differentially
#' expressed in both analyses. The 70 down-regulated genes shown are chosen similarly.
#'
#' @inheritParams scrape_revigo
#'
#' @return r2d3 plot
#' @importFrom magrittr %>%
#' @export
#' @seealso \link{add_path_genes} to enable heatplots on hover.
#'
#' @examples
#'
#' # single analysis
#' data(go_up2)
#' data_dir1 <- tempdir()
#' scrape_revigo(data_dir1, go_up2)
#' revigo_forcegraph(data_dir1)
#'
#' # two analyses
#' data(go_up1)
#' go_up1$analysis <- 0
#' go_up2$analysis <- 1
#' go_up <- rbind(go_up1, go_up2)
#'
#' data_dir2 <- tempdir()
#' scrape_revigo(data_dir2, go_up)
#' revigo_forcegraph(data_dir2)
#'
revigo_forcegraph <- function(data_dir) {
  # data prep
  go_merged <- get_merged_annotations(data_dir)

  xgmml_path <- file.path(data_dir, 'cytoscape_map.xgmml')
  data <- convert_xgmml(xgmml_path)
  data$nodes <- dplyr::left_join(data$nodes, go_merged, by = 'id')

  # NA analysis
  # TODO: figure out why
  # remove_nodes <- data$nodes$id[is.na(data$nodes$analysis)]
  # data$nodes <- data$nodes[!data$nodes$id %in% remove_nodes, ]
  # data$links <- data$links[!data$links$source %in% remove_nodes, ]
  # data$links <- data$links[!data$links$target %in% remove_nodes, ]

  r2d3::r2d3(
    system.file("d3/forcegraph/forcegraph.js", package = 'revigoR'),
    data = data_to_json(data),
    dependencies = system.file("d3/tooltip/tooltip.js", package = 'revigoR'),
    d3_version = 4
  )

}

#' Convert cytoscape xgmml to data.frames
#'
#' @param xgmml_path path to .xgmml file
#'
#' @return list of data.frames with nodes and links for forcegraph
#' @export
#'
#' @examples
#' data(go_up1)
#' data_dir <- tempdir()
#' scrape_revigo(data_dir, go_up1)
#' xgmml_path <- file.path(data_dir, 'cytoscape_map.xgmml')
#' data <- convert_xgmml(xgmml_path)
#'
convert_xgmml <- function(xgmml_path) {
  x <- xml2::read_xml(xgmml_path)

  xpath_nodes <- "/d1:graph/d1:node"

  ns <- xml2::xml_find_all(x, xpath_nodes, xml2::xml_ns(x))
  nodes <- xml2::xml_attrs(ns)

  # get children attributes
  for (i in seq_along(ns)) {
    node <- ns[i]
    kids <- xml2::xml_attrs(xml2::xml_children(node))
    nodes[[i]] <- c(nodes[[i]], kids[[6]]['fill'])
  }

  nodes <- do.call(rbind, nodes)
  nodes <- data.frame(nodes, stringsAsFactors = FALSE)


  # now the edges
  xpath_edges <-  "/graph/edge"
  xpath_edges <- stringr::str_replace_all(xpath_edges,'/','/d1:')

  ns <- xml2::xml_find_all(x, xpath_edges, xml2::xml_ns(x))
  edges <- xml2::xml_attrs(ns)
  edges <- lapply(edges, function(x) x[c('target', 'source')])

  for (i in seq_along(ns)) {
    edge <- ns[i]
    kids <- xml2::xml_attrs(xml2::xml_children(edge))
    edges[[i]] <- c(edges[[i]], kids[[1]]['value'])
  }

  edges <-  do.call(rbind, edges)
  edges <- data.frame(edges, stringsAsFactors = FALSE)
  edges$value <- as.numeric(as.character(edges$value))

  return(list(nodes=nodes, links=edges))
}
