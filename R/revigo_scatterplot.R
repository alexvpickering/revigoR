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
    ggplot2::geom_point(ggplot2::aes(plot_X, plot_Y, colour = -log10_p_value), alpha = I(0.6), size = 2) +
    ggplot2::scale_size_area() +
    ggplot2::scale_colour_gradientn(colours = c("blue", "green", "yellow", "red")) +
    ggplot2::geom_point(ggplot2::aes(plot_X, plot_Y), shape = 1, fill = "transparent", colour = I (ggplot2::alpha("black", 0.1))) +
    ggplot2::scale_size_area() +
    ggplot2::scale_size(range=c(5, 30)) +
    ggplot2::theme_bw() +
    ggrepel::geom_label_repel(data = ex,
                              min.segment.length = 0,label.size = 0, label.padding = 0,
                              ggplot2::aes(plot_X, plot_Y, label = description), colour = I(ggplot2::alpha("black", 0.85)), size = 3) +
    ggplot2::labs (y = "Semantic Space X", x = "Semantic Space Y") +
    ggplot2::theme(legend.key = ggplot2::element_blank()) +
    ggplot2::xlim(min(revigo.data$plot_X)-one.x_range/10,max(revigo.data$plot_X)+one.x_range/10) +
    ggplot2::ylim(min(revigo.data$plot_Y)-one.y_range/10,max(revigo.data$plot_Y)+one.y_range/10)

  p1
}






