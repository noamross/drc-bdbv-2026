library(targets)
library(tarchetypes)

tar_option_set(
  controller = crew::crew_controller_local(
    name = "primary",
    workers = as.integer(Sys.getenv("NPROC", unset = "12")),
    local_log_directory = "crew_logs"
  ),
  format = "qs",
  repository = tar_repository_cas_local(consistent = TRUE),
  packages = c("dplyr", "tidyr", "purrr", "stringi", "tibble")
)

for (f in c(
  list.files(".", pattern = "_targets_.*\\.(R|r)$", full.names = TRUE),
  list.files("R", pattern = "\\.(R|r)$", full.names = TRUE)
)) {
  source(f)
}
all_targets()
