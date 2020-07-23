#' Get GO geneset list
#'
#' Used by \code{\link{add_path_genes}} so add significant genes to output of \code{limma::goana}.
#' Adapted from \code{limma::goana}
#'
#'
#' @param species string to specify organism annotation package. Default \code{'Hs'} uses org.Hs.eg.db.
#'
#' @return Lists of named character vectors. Each list contains a character vector of ENTREZIDs with HGNC symbols as names
#'  for each GO id.
#'
#' @export
#' @seealso \link[limma]{goana}, \link{add_path_genes}.
#'
#' @examples
#'
#' gslist.go <- get_gslist.go('Hs')
#'
get_gslist.go <- function(species = 'Hs') {
  orgPkg <- paste0("org.",species,".eg.db")
  require(orgPkg, character.only = TRUE, quietly = TRUE)

  #	Get access to package of GO terms
  suppressPackageStartupMessages(OK <- requireNamespace("GO.db",quietly=TRUE))
  if(!OK) stop("GO.db package required but is not installed (or can't be loaded)")

  #	Get access to required annotation functions
  suppressPackageStartupMessages(OK <- requireNamespace("AnnotationDbi",quietly=TRUE))
  if(!OK) stop("AnnotationDbi package required but is not installed (or can't be loaded)")

  #	Load appropriate organism package
  suppressPackageStartupMessages(OK <- requireNamespace(orgPkg,quietly=TRUE))
  if(!OK) stop(orgPkg," package required but is not installed (or can't be loaded)")

  #	Get GO to Entrez Gene mappings
  obj <- paste0("org.",species,".egGO2ALLEGS")
  egGO2ALLEGS <- tryCatch(getFromNamespace(obj,orgPkg), error=function(e) FALSE)
  if(is.logical(egGO2ALLEGS)) stop("Can't find gene ontology mappings in package ",orgPkg)

  # Entrez gene to symbol
  # TODO for Hs: get from toupper(hs[EG.GO$gene_id, SYMBOL_9606]) so that consistent with original annotation
  EG.GO <- AnnotationDbi::toTable(egGO2ALLEGS)
  EG.GO$SYMBOL <- AnnotationDbi::mapIds(get(orgPkg), EG.GO$gene_id, column = 'SYMBOL', keytype = 'ENTREZID')
  gslist <- split(EG.GO, EG.GO$go_id)
  gslist <- lapply(gslist, function(df) {tmp <- df$gene_id; names(tmp) <- df$SYMBOL; tmp})

  return(gslist)
}

#' Get names of gene set
#'
#' @param gslist result of \code{\link{get_gslist}}
#' @param type either 'go' or 'kegg'
#' @param species species identifier
#' @param gs_dir Directory to save results to
#'
#' @return Description of \code{gslist} gene sets
#' @export
#'
#' @examples
#' gslist.go <- get_gslist.go()
#' gs.names.go <- get_gs.names.go(gslist.go)
#'
get_gs.names.go <- function(gslist.go, species = 'Hs') {

  GOID <- names(gslist.go)
  TERM <- suppressMessages(AnnotationDbi::select(GO.db::GO.db,keys=GOID,columns="TERM"))
  gs.names.go <- TERM$TERM
  names(gs.names.go) <- TERM$GOID
  return(gs.names.go)
}

#' Add Gene Names and logFC Values to goana Result
#'
#' Used to add gene name and logfc values to goana result prior to \code{\link{scrape_revigo}}. Allows \code{\link{r2d3_forcegraph}}
#' and other graphs to display gene names and logfc values for GO terms.
#'
#' @param go_res result of call to \code{\link{limma::goana}}
#' @param top_table result of limma::topTable with \code{n = Inf} with character column \code{ENTREZID} added. \code{topTable}
#'   should be called with argument \code{n = Inf} to ensure that all genes with \code{adj.P.Val < FDR} are added
#' @param gslist result of \code{\link{get_gslist.go}}. If \code{NULL} (default) then function retrieved internally.
#' @param species Used by \code{get_gslist.go} if \code{gslist} is NULL.
#' @inheritParams limma::goana
#'
#' @return \code{go_res} with columns \code{SYMBOL} and \code{logFC} containing lists of vectors with gene symbols and logFC
#'   values for genes with \code{adj.P.Val < FDR}.
#'
#' @export
#'
#' @examples
#' ## Not run:
#' ## Example of setup assuming you have: y, design, and enids
#'
#' library(limma)
#'
#' fit <- lmFit(y, design)
#' fit <- eBayes(fit)
#'
#' # add ENTREZID column to fit result (see geneid argument of ?limma::goana)
#' fit$genes <- data.frame(ENTREZID = enids)
#'
#' # Standard GO analysis
#' go_res <- goana(fit, species="Hs")
#'
#' # Differential expression analysis
#' top_table <- topTable(fit, n = Inf)
#'
#' # example for upregulated ontologies
#' go_up <- go_res[go_res$P.Up < 10e-5 & go_res$P.Up < go_res$P.Down, ]
#' go_up <- add_path_genes(go_up, top_table)
#'
#' # column ordering expected by scrape_revigo
#' go_up <- go_up[, c('P.Up', 'SYMBOL', 'logFC')]
#' data_dir <- tempdir()
#' scrape_revigo(data_dir, go_up)
#'
#'
add_path_genes <- function(go_res, top_table, gslist = NULL, species = 'Hs', FDR = 0.05) {

  # if no gslist then fetch
  if (is.null(gslist)) gslist <- get_gslist.go(species)

  path_ids <- row.names(go_res)
  gslist <- gslist[path_ids]

  enids <- na.omit(top_table$ENTREZID[top_table$adj.P.Val < FDR])
  enids <- as.character(enids)
  go_res$SYMBOL <- lapply(gslist, function(x) unique(names(x[x %in% enids])))

  logfc <- top_table$logFC
  names(logfc) <- top_table$ENTREZID
  go_res$logFC <- lapply(gslist, function(x) logfc[unique(x[x %in% enids])])

  return(go_res)
}
