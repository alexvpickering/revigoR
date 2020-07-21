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


#' Generate forcegraph plot of revigo GO graph
#'
#' If \link{add_path_genes} is called, hovering a node will show the logFC of significant genes in all GO terms
#' merged into the the representative GO term in question. At most 70 upregulated (red) and 70 downregulated (green)
#' genes with the largest absolute logFC are displayed.
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
#' data(go_res)
#' data_dir <- tempdir()
#' scrape_revigo(data_dir, go_res)
#' r2d3_forcegraph(data_dir)
#'
#'
r2d3_forcegraph <- function(data_dir) {
  xgmml_path <- file.path(data_dir, 'cytoscape_map.xgmml')
  data <- convert_xgmml(xgmml_path)
  data <- append_genes(data, data_dir)

  r2d3::r2d3(system.file("d3/forcegraph/forcegraph.js", package = 'revigoR'), data = data_to_json(data), d3_version = 4)
}

#' Add gene names and logfc values to forcegraph data
#'
#' Used internally by \link{r2d3_forcegraph}
#'
#' @param data result of \code{\link{convert_xgmml}}
#' @param data_dir directory with scraped revigo data
#'
#' @return \code{data} with columes merged_genes and logfc added to nodes data.frame
#' @export
#' @keywords internal
#'
append_genes <- function(data, data_dir) {

  # read original RDS with gene names/logfc values
  go_res <- readRDS(file.path(data_dir, 'go_res.rds'))

  if (!all(c('SYMBOL', 'logFC') %in% colnames(go_res)))
    stop("go_res supplied to scrape_revigo lacked columns 'SYMBOL' and/or 'logFC'")

  # obtain revigo collapsed columns
  revigo_res <- read.csv(file.path(data_dir, 'rsc.csv'), row.names = 1)
  go_res$representative <- revigo_res[row.names(go_res), 'representative']

  # merge to unique genes and associated logfc within revigo groups
  go_merged <- go_res %>%
    dplyr::group_by(representative) %>%
    dplyr::summarize(merged_genes = list(unlist(SYMBOL)[!duplicated(unlist(SYMBOL))]),
                     logFC = list(unlist(logFC)[!duplicated(unlist(SYMBOL))]),
                     id = paste0('GO:', unique(representative))) %>%
    dplyr::select(-representative)

  data$nodes <- dplyr::left_join(data$nodes, go_merged, by = 'id')

  return(data)
}
