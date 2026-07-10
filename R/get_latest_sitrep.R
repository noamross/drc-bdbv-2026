# INRB-UMIE commits digitised sitreps under data/insp_sitrep/reports as
# SitRep_MVE_<number>-2026.md, one per source PDF. The "Report date" field
# inside that file is the date INSP issued the sitrep, which can lag the
# commit date of the processed CSVs.
get_latest_sitrep <- function(
  owner = "INRB-UMIE",
  repo = "BDBV2026-Data",
  path = "data/insp_sitrep/reports"
) {
  contents <- gh::gh(
    "GET /repos/{owner}/{repo}/contents/{path}",
    owner = owner,
    repo = repo,
    path = path
  )
  names <- vapply(contents, function(x) x$name, character(1))
  numbers <- suppressWarnings(as.integer(
    stringi::stri_match_first_regex(
      names,
      "^SitRep_MVE_0*([0-9]+)-[0-9]{4}\\.md$"
    )[, 2]
  ))

  latest_i <- which(numbers == max(numbers, na.rm = TRUE))[1]
  latest <- contents[[latest_i]]

  report_txt <- paste(readLines(latest$download_url, warn = FALSE), collapse = "\n")
  report_date_str <- stringi::stri_match_first_regex(
    report_txt,
    "\\*\\*Report date\\*\\*\\s*\\|\\s*([0-9]{1,2} [A-Za-z]+ [0-9]{4})"
  )[, 2]

  tibble::tibble(
    number = numbers[latest_i],
    report_date = lubridate::dmy(report_date_str),
    url = latest$html_url
  )
}
