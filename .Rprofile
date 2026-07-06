is_interactive <- interactive()
is_targets <- Sys.getenv("TAR_ACTIVE") == "true"
is_ci <- Sys.getenv("CI") == "true"

# Load env vars from any file starting with `.env`. This allows user-specific
# options to be set in `.env_user` (which is .gitignored), and to have both
# encrypted and non-encrypted .env files
load_env <- function() {
  for (env_file in list.files(all.files = TRUE, pattern = "^\\.env.*")) {
    try(readRenviron(env_file), silent = TRUE)
  }
}
load_env()

options(
  repos = c(
    P3M = "https://p3m.dev/all/latest",
    CRAN = "https://cran.rstudio.com/"
  ),
  pkgType = "binary",
  renv.config.auto.snapshot = FALSE, ## Attempt to keep renv.lock updated automatically
  renv.config.rspm.enabled = TRUE, ## Use RStudio Package manager for pre-built package binaries
  renv.config.install.shortcuts = TRUE, ## Use the existing local library to fetch copies of packages for renv
  renv.config.cache.enabled = TRUE, ## Use the renv build cache to speed up install times
  renv.config.sandbox.enabled = !is_ci,
  renv.config.synchronized.check = is_interactive,
  renv.config.startup.quiet = !is_interactive,
  renv.config.updates.check = FALSE,
  tidyverse.quiet = TRUE,
  gargle_oauth_email = Sys.getenv(
    "GARGLE_OAUTH_EMAIL",
    unset = NA
  ),
  renv.config.install.jobs = 8
)
Sys.setenv("RENV_WATCHDOG_ENABLED" = as.character(!is_targets))
source("renv/activate.R")
load_env() # reload project .env files, after renv/activate.R runs renv::load() which reads user's .renviron


# If project packages have conflicts define them here so as
# as to manage them across all sessions when building targets
if (requireNamespace("conflicted", quietly = TRUE)) {
  conflicted::conflicts_prefer(
    dplyr::filter,
    dplyr::count,
    dplyr::select,
    dplyr::lag,
    dplyr::coalesce,
    dplyr::first,
    dplyr::last,
    magrittr::set_names,
    purrr::flatten,
    utils::View,
    purrr::map,
    lubridate::month,
    lubridate::year,
    #website only:
    plotly::layout,
    .quiet = TRUE
  )
}
