#' Revigo MDS plot
#'
#' @param data_dir directory with scraped revigo data
#'
#' @return ggplot object
#' @export
#'
#' @examples
#'
#' data(go_up1)
#' data_dir <- tempdir()
#' scrape_revigo(data_dir, go_up1)
#' revigo_scatterplot_original(data_dir)
#'
revigo_scatterplot_original <- function(data_dir) {

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
    ggplot2::geom_point(ggplot2::aes(plot_X, plot_Y, colour = -log10_p_value), alpha = I(0.6), size = 2) +
    ggplot2::scale_size_area() +
    ggplot2::scale_colour_gradientn(colours = c("blue", "green", "yellow", "red")) +
    ggplot2::geom_point(ggplot2::aes(plot_X, plot_Y), shape = 1, fill = "transparent", colour = I (ggplot2::alpha("black", 0.1))) +
    ggplot2::scale_size_area() +
    ggplot2::scale_size(range=c(5, 30)) +
    ggplot2::theme_bw() +
    ggrepel::geom_label_repel(data = ex,
                              min.segment.length = 0,
                              label.size = 0,
                              label.padding = 0,
                              ggplot2::aes(plot_X, plot_Y, label = description), colour = I(ggplot2::alpha("black", 0.85)), size = 3, fill = "transparent") +
    ggplot2::labs (y = "Semantic Space X", x = "Semantic Space Y") +
    ggplot2::theme(legend.key = ggplot2::element_blank()) +
    ggplot2::xlim(min(revigo.data$plot_X)-one.x_range/10,max(revigo.data$plot_X)+one.x_range/10) +
    ggplot2::ylim(min(revigo.data$plot_Y)-one.y_range/10,max(revigo.data$plot_Y)+one.y_range/10)

  p1
}

#' Revigo MDS plot
#'
#' Uses MDS coordinates from revigo.
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
#' @param data_dir directory with scraped revigo data
#'
#' @return r2d3 plot
#' @export
#'
#' @examples
#'
#'
#' # single analysis
#' data(go_up1)
#' data_dir <- tempdir()
#' scrape_revigo(data_dir, go_up1)
#' revigo_scatterplot(data_dir)
#'
#' # two analyses
#' data(go_up2)
#' data_dir <- tempdir()
#' go_up1$analysis <- 0
#' go_up2$analysis <- 1
#' go_up <- rbind(go_up1, go_up2)
#' scrape_revigo(data_dir, go_up)
#' revigo_scatterplot(data_dir)
#'
revigo_scatterplot <- function(data_dir) {

  # load revigo data
  data <- get_merged_annotations(data_dir)
  r2d3::r2d3(
    system.file("d3/scatterplot/scatterplot.js", package = 'revigoR'),
    data = data_to_json(data),
    dependencies = system.file("d3/tooltip/tooltip.js", package = 'revigoR'),
    d3_version = 4
  )

}






