#' Install python packages required by package
#'
#' @return
#' @export
#'
#' @examples
setup_env <- function() {

  reticulate::virtualenv_create('revigo')
  reticulate::virtualenv_install(envname = 'revigo',
                                 packages = c('numpy', 'werkzeug', 'robobrowser'),
                                 ignore_installed = TRUE)
}

#' Submits GO result to revigo and downloads all scripts and outputs
#'
#' Note: requires installation of python packages through \code{\link{setup_env}}
#'
#' @param data_dir Directory to store revigo scripts and output files
#' @param go_res data.frame with row.names containing GO ids and first column p-values. An optional 3rd column
#' can contain the significant genes seperated by forward slashes (used for heatplots of GO terms).
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

#' Revigo MDS plot
#'
#' @param data_dir directory with scraped revigo data
#'
#' @return ggplot object
#' @export
#'
#' @examples
#'
#' data(go_res)
#' data_dir <- tempdir()
#' scrape_revigo(data_dir, go_res)
#' revigo_scatterplot(data_dir)
#'
revigo_scatterplot <- function(data_dir) {

  # load revigo data
  revigo.data <- read.csv(file.path(data_dir, 'rsc.csv'), check.names = FALSE)
  revigo.data <- revigo.data[(revigo.data$plot_X != "null" & revigo.data$plot_Y != "null"), ]
  revigo.data$frequency <- gsub('%', '', revigo.data$frequency)
  revigo.data$plot_X <- as.numeric(as.character(revigo.data$plot_X))
  revigo.data$plot_Y <- as.numeric(as.character(revigo.data$plot_Y))
  revigo.data$plot_size <- as.numeric(as.character(revigo.data$plot_size))
  revigo.data$log10_p_value <- as.numeric(as.character(revigo.data$`log10 p-value`))
  revigo.data$frequency <- as.numeric(as.character(revigo.data$frequency))
  revigo.data$uniqueness <- as.numeric(as.character(revigo.data$uniqueness))
  revigo.data$dispensability <- as.numeric(as.character(revigo.data$dispensability))

  ex <- revigo.data [ revigo.data$dispensability < 0.15, ]
  one.x_range = max(revigo.data$plot_X) - min(revigo.data$plot_X)
  one.y_range = max(revigo.data$plot_Y) - min(revigo.data$plot_Y)

  p1 <- ggplot2::ggplot(data = revigo.data) +
    ggplot2::geom_point(ggplot2::aes(plot_X, plot_Y, colour = log10_p_value, size = plot_size), alpha = I(0.6)) +
    ggplot2::scale_size_area() +
    ggplot2::scale_colour_gradientn(colours = c("blue", "green", "yellow", "red"), limits = c(min(revigo.data$log10_p_value), 0)) +
    ggplot2::geom_point(ggplot2::aes(plot_X, plot_Y, size = plot_size), shape = 21, fill = "transparent", colour = I (ggplot2::alpha("black", 0.6))) +
    ggplot2::scale_size_area() +
    ggplot2::scale_size(range=c(5, 30)) +
    ggplot2::theme_bw() +
    ggplot2::geom_text(data = ex, ggplot2::aes(plot_X, plot_Y, label = description), colour = I(ggplot2::alpha("black", 0.85)), size = 3) +
    ggplot2::labs (y = "semantic space x", x = "semantic space y") +
    ggplot2::theme(legend.key = ggplot2::element_blank()) +
    ggplot2::xlim(min(revigo.data$plot_X)-one.x_range/10,max(revigo.data$plot_X)+one.x_range/10) +
    ggplot2::ylim(min(revigo.data$plot_Y)-one.y_range/10,max(revigo.data$plot_Y)+one.y_range/10)

  p1
}

convert_kid <- function(kid) {

  if (!'type' %in% names(kid)) {
    res <- kid
  } else if (kid['type'] == 'ELLIPSE') {
    res <- c(kid['x'], kid['y'], kid['fill'])
    names(res) <- c('x', 'y', 'fill')

  } else {
    res <- kid['value']
    names(res) <- kid['name']
  }

  return(res)
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

r2d3_forcegraph <- function(data_dir) {
  xgmml_path <- file.path(data_dir, 'cytoscape_map.xgmml')
  data <- convert_xgmml(xgmml_path)
  data <- append_genes(data, data_dir)

  r2d3::r2d3(system.file("d3/forcegraph/forcegraph.js", package = 'revigoR'), data = data_to_json(data), d3_version = 4)
}

#' Add gene names and logfc values to forcegraph data
#'
#' @param data result of \code{\link{convert_xgmml}}
#' @param data_dir directory with scraped revigo data
#'
#' @return \code{data} with columes merged_genes and logfc added to nodes data.frame
#' @export
#'
#' @examples
append_genes <- function(data, data_dir) {

  # read original RDS with gene names/logfc values
  go_res <- readRDS(file.path(data_dir, 'go_res.rds'))

  if (!all(c('genes', 'logfc') %in% colnames(go_res)))
    stop("go_res supplied to scrape_revigo lacked columns 'genes' and/or 'logfc'")

  # obtain revigo collapsed columns
  revigo_res <- read.csv(file.path(data_dir, 'rsc.csv'), row.names = 1)
  go_res$representative <- revigo_res[row.names(go_res), 'representative']

  # merge to unique genes and associated logfc within revigo groups
  go_merged <- go_res %>%
    dplyr::group_by(representative) %>%
    dplyr::summarize(merged_genes = list(unlist(genes)[!duplicated(unlist(genes))]),
                     logfc = list(unlist(logfc)[!duplicated(unlist(genes))]),
                     id = paste0('GO:', unique(representative))) %>%
    dplyr::select(-representative)

  data$nodes <- dplyr::left_join(data$nodes, go_merged, by = 'id')

  return(data)
}
