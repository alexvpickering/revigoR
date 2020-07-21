#' Install python packages required by package
#'
#' Creates virtualenv with name revigo and installs numpy, werkzeug, and robobrowser
#'
#' @return
#' @export
#'
setup_env <- function() {

  reticulate::virtualenv_create('revigo')
  reticulate::virtualenv_install(envname = 'revigo',
                                 packages = c('Hnumpy', 'werkzeug', 'robobrowser'),
                                 ignore_installed = TRUE)
}
