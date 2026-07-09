# CI has intermittently seen raw.githubusercontent.com fetches fail with
# "cannot open URL" (transient network/DNS errors). Retry with backoff
# before giving up, instead of failing the whole pipeline on one bad request.
download_retry <- function(url, path) {
  httr2::request(url) |>
    httr2::req_retry(max_tries = 5, retry_on_failure = TRUE) |>
    httr2::req_perform(path = path)
  path
}
