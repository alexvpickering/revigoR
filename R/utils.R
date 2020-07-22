#' Get merged gene names, logfc values, and analysis indicator
#'
#' Used internally by \link{revigo_forcegraph} and \code{revigo_scatterplot}
#'
#' @param data_dir directory with scraped revigo data
#'
#' @importFrom magrittr %>%
#' @return \code{tibble} with columes merged_genes, logFC, analysis, and id
#' @export
#' @keywords internal
#'
#' data(go_up1)
#' data_dir <- tempdir()
#' scrape_revigo(data_dir, go_up1)
#' xgmml_path <- file.path(data_dir, 'cytoscape_map.xgmml')
#' data <- convert_xgmml(xgmml_path)
#' data <- get_merged_annotations(data_dir)
#'
get_merged_annotations <- function(data_dir) {

  # read original RDS with gene names/logfc values
  go_res <- readRDS(file.path(data_dir, 'go_res.rds'))

  if (!all(c('SYMBOL', 'logFC') %in% colnames(go_res)))
    stop("go_res supplied to scrape_revigo lacked columns 'SYMBOL' and/or 'logFC'")

  if (length(unique(go_res$analysis)) > 2)
    stop("go_res supplied to scrape_revigo has more than two unique analyses")

  if (is.null(go_res$analysis)) go_res$analysis <- 0

  # obtain revigo collapsed columns
  revigo_res <- read.csv(file.path(data_dir, 'rsc.csv'), row.names = 1, stringsAsFactors = FALSE, check.names = FALSE)

  # label used by tooltip
  revigo_res$label <- revigo_res$description

  # remove leading zeros in GO:0 for joins
  revigo_res$id <- gsub(':0+', ':', row.names(revigo_res))

  go_res$representative <- revigo_res[row.names(go_res), 'representative']

  # get genes where inconsistent logFC (occurs with two analyses)
  exclude <- get_inconsistent_genes(unnameunlist(go_res$SYMBOL),
                                    unnameunlist(go_res$logFC))

  # merge to unique genes and associated logfc within revigo groups
  # if two analyses merge set analysis indicator to 2
  go_merged <- go_res %>%
    dplyr::group_by(representative) %>%
    dplyr::summarize(merged_genes = list(unlist(SYMBOL)[is_consistent(unnameunlist(SYMBOL), exclude)]),
                     logFC = list(unlist(logFC)[is_consistent(unnameunlist(SYMBOL), exclude)]),
                     id = paste0('GO:', unique(representative)),
                     analysis = ifelse(length(unique(analysis)) == 2, 2, unique(analysis))) %>%
    dplyr::select(-representative)

  go_merged <- dplyr::left_join(go_merged, revigo_res, by = 'id')

  return(go_merged)
}

unnameunlist <- function(x) {
  unname(unlist(x))
}

#' Identify genes with inconsistent logFC values
#'
#' Used to resolve conflicts for two-analysis plots.
#'
#' @param symbols character vector of gene names
#' @param logfc numeric vector of logFC values
#'
#' @return character vector of gene names where logFC values disagree
#' @export
#' @keywords internal
#'
get_inconsistent_genes <- function(symbols, logfc) {

  exclude <- c()
  if (length(unique(symbols)) == length(symbols)) return(exclude)

  for (symbol in unique(symbols)) {

    # if just one then skip
    is.symbol <- which(symbols == symbol)
    if (length(is.symbol) == 1) next()

    symbol_logfcs <- logfc[is.symbol]
    if (length(unique(sign(symbol_logfcs))) == 1) {
      # keep gene
      next()

    } else {
      # hide gene
      exclude <- c(exclude, symbol)
    }
  }
  return(exclude)
}

#' Resolve conflicts of logfc for multi-sample analyses
#'
#' @param symbols character vector of gene names
#' @param exclude gene names to exclude
#'
#' @return boolean of length \code{unlist(symbols)}
#' @export
#' @keywords internal
#'
is_consistent <- function(symbols, exclude) {
  !duplicated(symbols) & !symbols %in% exclude
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
