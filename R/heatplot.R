#' Plot heatmap for genes from goana/kegga analysis
#'
#' modified from enrichplot
#'
#' @param path_res data.frame, result of \code{limma::goana} or \code{limma::kegga} with
#' significant genes for each pathway added by \code{add_path_genes}.
#'
#' @return \code{ggplot} object.
#' @export
#'
#' @examples
#'
#' # plot pathways merged by revigo under inflammatory response
#' data(go_up1)
#'
#' data_dir <- tempdir()
#' scrape_revigo(data_dir, go_up1)
#' revigo_res <- read.csv(file.path(data_dir, 'rsc.csv'), row.names = 1, stringsAsFactors = FALSE)
#' go_infl <- row.names(revigo_res)[revigo_res$representative == 6954]
#' heatplot(go_up1[go_infl, ])
#'
heatplot <- function(path_res) {

  foldChange <- unlist(path_res$logFC)
  names(foldChange) <- unlist(path_res$SYMBOL)
  foldChange <- foldChange[!duplicated(foldChange)]

  geneSets <- path_res$SYMBOL
  names(geneSets) <- row.names(path_res)
  d <- list2df(geneSets)

  if (!is.null(foldChange)) {
    d$foldChange <- foldChange[d[,2]]
    d <- d[!is.na(d$foldChange), ]
    d <- d[order(d$foldChange, decreasing = TRUE), ]
    d$Gene <- factor(d$Gene, levels = unique(d$Gene))
    p <- ggplot2::ggplot(d, ggplot2::aes_(~Gene, ~categoryID)) +
      ggplot2::geom_tile(ggplot2::aes_(fill = ~foldChange), color = "white") +
      # ggplot2::scale_fill_continuous(low="blue", high="red", name = "fold change")
      ggplot2::scale_fill_gradient2(
        low = "blue",
        mid = "white",
        high = "#FF0000",
        midpoint = 0)

  } else {
    p <- ggplot2::ggplot(d, ggplot2::aes_(~Gene, ~categoryID)) +
      ggplot2::geom_tile(color = 'white')
  }
  p + ggplot2::xlab(NULL) +
    ggplot2::ylab(NULL) +
    ggplot2::theme_linedraw() +
    ggplot2::theme(axis.text.x=ggplot2::element_text(angle = 90, hjust = 1, size = 8),
                   panel.grid = ggplot2::element_blank())
}

extract_geneSets <- function(path_res) {
  geneSets <- path_res$GeneNames
  geneSets <- lapply(geneSets, function(x) strsplit(x, '/')[[1]])
  names(geneSets) <- path_res$Term
  return(geneSets)
}

list2df <- function (inputList) {
  ldf <- lapply(1:length(inputList), function(i) {
    data.frame(categoryID = rep(names(inputList[i]), length(inputList[[i]])),
               Gene = inputList[[i]],
               stringsAsFactors = FALSE)
  })
  do.call("rbind", ldf)
}
