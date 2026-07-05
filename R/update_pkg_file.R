update_pkg_file <- function(snapshot = TRUE) {
  run_env <- new.env()
  pkg_file <- "packages.R"
  if (fs::file_exists(pkg_file)) {
    fs::file_delete(pkg_file)
  }
  deps <- sort(unique(
    renv::dependencies(quiet = TRUE, errors = "reported")$Package
  ))

  targets::tar_renv(
    path = pkg_file,
    extras = deps,
    callr_function = NULL,
    env = run_env
  )
  if (snapshot) {
    renv::snapshot()
  }
  invisible(pkg_file)
}
