
#' Generate forcegraph plot of revigo GO graph
#'
#' If \link{add_path_genes} is called, hovering a node will show the logFC of significant genes in all GO terms
#' merged into the the representative GO term in question. At most 70 upregulated (red) and 70 downregulated (green)
#' genes with the largest absolute logFC are displayed.
#'
#' If \code{scrape_revigo} is used with two analyses (see examples), revigo ontolgies where no merge occured
#' across analyses will be shades of red and blue while ontologies where a merge occured across analyses
#' will be shades of purple.
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
#' data_dir <- tempdir()
#' scrape_revigo(data_dir, go_up2)
#' revigo_forcegraph(data_dir)
#'
#' # two analyses
#' data(go_up1)
#' go_up1$analysis <- 0
#' go_up2$analysis <- 1
#' go_up <- rbind(go_up1, go_up2)
#'
#' data_dir <- tempdir()
#' scrape_revigo(data_dir, go_up)
#' revigo_forcegraph(data_dir)
#'
revigo_forcegraph <- function(data_dir) {
  xgmml_path <- file.path(data_dir, 'cytoscape_map.xgmml')
  data <- convert_xgmml(xgmml_path)
  data <- append_forcegraph_annotations(data, data_dir)
  data <- adjust_forcegraph_colors(data)

  r2d3::r2d3(system.file("d3/forcegraph/forcegraph.js", package = 'revigoR'), data = data_to_json(data), d3_version = 4)
}

#' Add gene names, logfc values, and analysis indicator to forcegraph data
#'
#' Used internally by \link{revigo_forcegraph}
#'
#' @param data result of \code{\link{convert_xgmml}}
#' @param data_dir directory with scraped revigo data
#'
#' @importFrom magrittr %>%
#' @return \code{data} with columes merged_genes, logFC, and analysis, added to nodes data.frame
#' @export
#' @keywords internal
#'
#' data(go_up1)
#' data_dir <- tempdir()
#' scrape_revigo(data_dir, go_up1)
#' xgmml_path <- file.path(data_dir, 'cytoscape_map.xgmml')
#' data <- convert_xgmml(xgmml_path)
#' data <- append_annotations(data, data_dir)
#'
append_forcegraph_annotations <- function(data, data_dir) {

  # read original RDS with gene names/logfc values
  go_res <- readRDS(file.path(data_dir, 'go_res.rds'))

  if (!all(c('SYMBOL', 'logFC') %in% colnames(go_res)))
    stop("go_res supplied to scrape_revigo lacked columns 'SYMBOL' and/or 'logFC'")

  if (length(unique(go_res$analysis)) > 2)
    stop("go_res supplied to scrape_revigo has more than two unique analyses")

  if (is.null(go_res$analysis)) go_res$analysis <- 0

  # obtain revigo collapsed columns
  revigo_res <- read.csv(file.path(data_dir, 'rsc.csv'), row.names = 1)
  go_res$representative <- revigo_res[row.names(go_res), 'representative']

  # merge to unique genes and associated logfc within revigo groups
  # if two analyses merge set analysis indicator to 2
  go_merged <- go_res %>%
    dplyr::group_by(representative) %>%
    dplyr::summarize(merged_genes = list(unlist(SYMBOL)[!duplicated(unlist(SYMBOL))]),
                     logFC = list(unlist(logFC)[!duplicated(unlist(SYMBOL))]),
                     id = paste0('GO:', unique(representative)),
                     analysis = ifelse(length(unique(analysis)) == 2, 2, unique(analysis))) %>%
    dplyr::select(-representative)

  data$nodes <- dplyr::left_join(data$nodes, go_merged, by = 'id')

  return(data)
}

#' Adjust forcegraph colors to compare multiple analyses
#'
#' Nodes for single analyses get hue 240(blue) and 0(red).
#' Nodes resulting from merged analyses get hue 275 (purple).
#' Saturation and lightness stay the same to indicate significance.
#'
#' @param data result of \code{append_forcegraph_annotations}
#'
#' @return \code{data} with colors adjusted.
#' @export
#' @keywords internal
#'
adjust_forcegraph_colors <- function(data) {

  cols <- data$nodes$fill
  anals <- data$nodes$analysis

  cols <- plotwidgets::col2hsl(cols)
  cols['H', ] <- sapply(anals, function(anal) {
    if (anal == 0) return(0)
    else if (anal == 1) return(240)
    else if (anal == 2) return(275)
  })

  # convert back to hex
  data$nodes$fill <- plotwidgets::hsl2col(cols)

  return(data)

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

#' Format forcegraph data.frames to JSON
#'
#'
#' @param data result of \code{\link{convert_xgmml}}
#'
#' @return JSON objects
#' @export
#'
#' @examples
#' data(go_up1)
#' data_dir <- tempdir()
#' scrape_revigo(data_dir, go_up1)
#' xgmml_path <- file.path(data_dir, 'cytoscape_map.xgmml')
#' data <- convert_xgmml(xgmml_path)
#' data_to_json(data)
#'
data_to_json <- function(data) {
  jsonlite::toJSON(data,
                   dataframe = "rows", null = "null", na = "null", auto_unbox = TRUE,
                   digits = getOption("shiny.json.digits", 16), use_signif = TRUE, force = TRUE,
                   POSIXt = "ISO8601", UTC = TRUE, rownames = FALSE, keep_vec_names = TRUE,
                   json_verabitm = TRUE
  )
}
