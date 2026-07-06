# raw.githubusercontent.com URLs don't return a Last-Modified header, so get
# the true last-updated date from the GitHub API's commit history for the
# file instead.
gh_raw_url_commit_date <- function(url) {
  parts <- strsplit(
    sub("^https://raw\\.githubusercontent\\.com/", "", url),
    "/"
  )[[1]]
  owner <- parts[1]
  repo <- parts[2]
  rest <- parts[-(1:2)]
  if (identical(rest[1:2], c("refs", "heads"))) {
    ref <- rest[3]
    file_path <- paste(rest[-(1:3)], collapse = "/")
  } else {
    ref <- rest[1]
    file_path <- paste(rest[-1], collapse = "/")
  }

  commits <- gh::gh(
    "GET /repos/{owner}/{repo}/commits",
    owner = owner,
    repo = repo,
    path = file_path,
    sha = ref,
    per_page = 1
  )
  if (length(commits) == 0) {
    return(as.POSIXct(NA))
  }
  lubridate::ymd_hms(commits[[1]]$commit$committer$date)
}
