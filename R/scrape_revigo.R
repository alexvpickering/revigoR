#' Submits GO result to revigo and downloads all scripts and outputs
#'
#' Note: requires installation of python packages through \code{\link{setup_env}}
#'
#' @param data_dir Directory to store revigo scripts and output files
#' @param go_res data.frame with row.names containing GO ids and first column p-values. An optional 3rd and 4th column
#' can contain lists of significant genes and their logFC values respectively (used for heatplots of GO terms).
#' An optional 5th column can contain a variable to indicate analysis identity (used to compare two seperate GO analyses).
#'
#' @return NULL
#' @export
#'
#' @examples
#'
#' data(go_res)
#' data_dir <- tempdir()
#' scrape_revigo(data_dir, go_res)
#'
#'
scrape_revigo <- function(data_dir, go_res) {
  reticulate::use_virtualenv('revigo', required = TRUE)
  unlink(data_dir, recursive = TRUE)
  dir.create(data_dir, recursive = TRUE)

  saveRDS(go_res, file.path(data_dir, 'go_res.rds'))
  write.table(go_res[, 1, drop = FALSE], file.path(data_dir, 'goterms.txt'), quote = FALSE, col.names = FALSE, row.names = TRUE)
  reticulate::source_python(system.file("python/scrape_revigo.py", package = "revigoR"))
  scrape_revigo(data_dir)

  files <- list.files(data_dir)
  message("Saved: ", paste(files, collapse = ', '), ' into ', data_dir)
}



#' Convert cytoscape xgmml to data.frames
#'
#' @param xgmml_path path to .xgmml file
#'
#' @return list of data.frames with nodes and links for forcegraph
#' @export
#'
#' @examples
#' data(go_res)
#' data_dir <- tempdir()
#' scrape_revigo(data_dir, go_res)
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
  nodes <- data.frame(nodes)


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
  edges <- data.frame(edges)
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
#' data(go_res)
#' data_dir <- tempdir()
#' scrape_revigo(data_dir, go_res)
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
