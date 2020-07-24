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
#' @examples
#'
#' data(go_up1)
#' data_dir <- tempdir()
#' scrape_revigo(data_dir, go_up1)
#' data <- get_merged_annotations(data_dir)
#'
get_merged_annotations <- function(data_dir) {

  # read original RDS with gene names/logfc values
  go_res <- readRDS(file.path(data_dir, 'go_res.rds'))

  if (!all(c('SYMBOL', 'logFC') %in% colnames(go_res)))
    stop("go_res supplied to scrape_revigo lacked columns 'SYMBOL' and/or 'logFC'")

  num_anals <- length(unique(go_res$analysis))
  if (num_anals > 2)
    stop("go_res supplied to scrape_revigo has more than two unique analyses")

  if (num_anals == 0) go_res$analysis <- 0

  # some revigo GO ids absent because of version differences in GO
  revigo_res <- read.csv(file.path(data_dir, 'rsc.csv'), row.names = 1, stringsAsFactors = FALSE, check.names = FALSE)
  go_res <- go_res[row.names(revigo_res), ]

  # remove na logfc
  rm.logfc <- sapply(go_res$logFC, function(x) is.null(x))
  go_res <- go_res[!rm.logfc, ]
  revigo_res <- revigo_res[!rm.logfc, ]

  # remove leading zeros in GO:0 for joins
  revigo_res$id <- gsub(':0+', ':', row.names(revigo_res))

  go_res$representative <- revigo_res$representative

  # get genes where inconsistent logFC (occurs when terms merged between two analyses)
  if (num_anals == 0) {
    exclude <- NULL

  } else {
    is.merged <- go_res$analysis == 2
    exclude <- get_inconsistent_genes(unnameunlist(go_res[is.merged, 'SYMBOL']),
                                      unnameunlist(go_res[is.merged, 'logFC']))

  }

  # merge to unique genes and associated logfc within revigo groups
  # if two analyses merge set analysis indicator to 2
  go_merged <- go_res %>%
    dplyr::group_by(representative) %>%
    dplyr::summarize(analysis = ifelse(length(unique(analysis)) == 2, 2, unique(analysis)),
                     merged_genes = summarize_genes(SYMBOL, exclude, analysis),
                     logFC = summarize_logfc(SYMBOL, logFC, exclude, analysis),
                     id = paste0('GO:', unique(representative)), .groups = 'drop') %>%
    dplyr::select(-representative)

  go_merged <- dplyr::left_join(go_merged, revigo_res, by = 'id')

  return(go_merged)
}

summarize_genes <- function(SYMBOL, exclude, analysis) {
  symbols <- unnameunlist(SYMBOL)
  symbols <- symbols[!duplicated(symbols)]

  if (analysis == 2 && length(exclude))
    symbols <- symbols[!symbols %in% exclude]

  return(list(symbols))
}

summarize_logfc <- function(SYMBOL, logFC, exclude, analysis) {

  logfc <- unnameunlist(logFC)
  symbols <- unnameunlist(SYMBOL)

  if (analysis != 2) {
    logfc <- logfc[!duplicated(symbols)]

  } else {

    # remove excluded
    df <- dplyr::tibble(SYMBOL = symbols, logFC = logfc) %>%
      dplyr::filter(!SYMBOL %in% exclude)

    # summarize rest with mean
    means <- df %>%
      dplyr::group_by(SYMBOL) %>%
      dplyr::summarize(SYMBOL = SYMBOL[1],
                       logFC = mean(unique(logFC)), .groups = 'drop')

    # extract logfcs in same order as summarize_genes
    logfc <- df %>%
      dplyr::select(SYMBOL) %>%
      dplyr::distinct() %>%
      dplyr::left_join(means, by = 'SYMBOL') %>%
      dplyr::pull(logFC)
  }

  return(list(logfc))
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
