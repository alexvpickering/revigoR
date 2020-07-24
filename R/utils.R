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

  # read original goana result submitted to scrape_revigo with gene names/logfc values
  go_res <- readRDS(file.path(data_dir, 'go_res.rds'))

  if (!all(c('SYMBOL', 'logFC') %in% colnames(go_res)))
    stop("go_res supplied to scrape_revigo lacked columns 'SYMBOL' and/or 'logFC'")

  num_anals <- length(unique(go_res$analysis))
  if (num_anals > 2)
    stop("go_res supplied to scrape_revigo has more than two unique analyses")

  if (num_anals == 0) go_res$analysis <- 0

  # result from scrape_revigo
  revigo_res <- read.csv(file.path(data_dir, 'rsc.csv'), row.names = 1, stringsAsFactors = FALSE, check.names = FALSE)

  # some revigo GO ids absent because of version differences in GO
  go_res <- go_res[row.names(revigo_res), ]

  # remove NULL logfc
  null.logfc <- sapply(go_res$logFC, function(x) is.null(x))
  go_res <- go_res[!null.logfc, ]
  revigo_res <- revigo_res[!null.logfc, ]

  # remove leading zeros in GO:0 for joins with other data sources (cytoscape nodes)
  revigo_res$id <- gsub(':0+', ':', row.names(revigo_res))

  go_res$representative <- revigo_res$representative

  # table of all logFC for each analysis
  anal0 <- go_res$analysis == 0

  rns0 <- unnameunlist(go_res[anal0, 'SYMBOL'])
  unq0 <- !duplicated(rns0)

  logFCs0 <- data.frame(
    logFC = unnameunlist(go_res[anal0, 'logFC'])[unq0],
    row.names = rns0[unq0], stringsAsFactors = FALSE
  )

  rns1 <- unnameunlist(go_res[!anal0, 'SYMBOL'])
  unq1 <- !duplicated(rns1)

  logFCs1 <- data.frame(
    logFC = unnameunlist(go_res[!anal0, 'logFC'])[unq1],
    row.names = rns1[unq1], stringsAsFactors = FALSE
  )

  # merge to unique genes and associated logfc within revigo groups
  # if two analyses merge set analysis indicator to 2
  go_merged <- go_res %>%
    dplyr::group_by(representative) %>%
    dplyr::summarize(analysis = ifelse(length(unique(analysis)) == 2, 2, unique(analysis)),
                     genes0 = summarize_genes(SYMBOL, logFCs0), # for analysis 0
                     logFC0 = summarize_logfc(genes0, logFCs0),
                     genes1 = summarize_genes(SYMBOL, logFCs1), # for analysis 1
                     logFC1 = summarize_logfc(genes1, logFCs1),
                     id = paste0('GO:', unique(representative)), .groups = 'drop') %>%
    dplyr::select(-representative)

  go_merged <- dplyr::left_join(go_merged, revigo_res, by = 'id')

  return(go_merged)
}

summarize_genes <- function(SYMBOL, logFCsn) {

  # all non-duplicated symbols from either/both analyses
  symbols <- unnameunlist(SYMBOL)
  symbols <- symbols[!duplicated(symbols)]

  # return list of symbols that have logFC values for this analysis
  symbols <- symbols[symbols %in% row.names(logFCsn)]

  return(list(symbols))
}

summarize_logfc <- function(genesn, logFCsn) {

  # genes in analysis that have logFCs for
  genes <- unnameunlist(genesn)
  list(logFCsn[genes, 'logFC'])
}

unnameunlist <- function(x) {
  unname(unlist(x))
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
                   dataframe = "rows", null = "null", na = "null", auto_unbox = FALSE,
                   digits = getOption("shiny.json.digits", 16), use_signif = TRUE, force = TRUE,
                   POSIXt = "ISO8601", UTC = TRUE, rownames = FALSE, keep_vec_names = TRUE,
                   json_verabitm = TRUE
  )
}
