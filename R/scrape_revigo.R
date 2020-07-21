#' Submits GO result to revigo and downloads all scripts and outputs
#'
#' Note: requires installation of python packages through \code{\link{setup_env}}
#'
#' @param data_dir Directory to store revigo scripts and output files
#' @param go_res data.frame with row.names containing GO ids and first column p-values. Optional columns \code{SYMBOL}
#' and \code{logFC} can contain lists of significant genes and their logFC values respectively (used for heatplots of GO terms).
#' An optional \code{analysis} integer column can contain 0 and 1's to indicate analysis identity (used to compare two seperate GO analyses).
#'
#' @return NULL
#' @export
#'
#' @examples
#'
#' data(go_up1)
#' data_dir <- tempdir()
#' scrape_revigo(data_dir, go_up1)
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

