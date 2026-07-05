process_sitrep <- function(insp_sitrep_cum_cases, insp_sitrep_cum_deaths) {
  all_dates <- tidyr::crossing(
    nom = unique(c(insp_sitrep_cum_cases$nom, insp_sitrep_cum_deaths$nom)),
    date = seq(
      min(c(insp_sitrep_cum_cases$date, insp_sitrep_cum_deaths$date)),
      max(c(insp_sitrep_cum_cases$date, insp_sitrep_cum_deaths$date)),
      by = "1 day"
    )
  )
  cases <- insp_sitrep_cum_cases |>
    full_join(insp_sitrep_cum_deaths, by = c("nom", "date")) |>
    full_join(all_dates, by = c("nom", "date")) |>
    arrange(nom, date) |>
    mutate(across(
      c(cumulative_confirmed_cases, cumulative_confirmed_deaths),
      \(.x) {
        as.integer(stri_replace_all_regex(
          .x,
          pattern = "\\D",
          replacement = "",
          vectorize_all = FALSE
        ))
      }
    )) |>
    tidyr::fill(
      c(cumulative_confirmed_cases, cumulative_confirmed_deaths),
      .by = nom,
      .direction = "down"
    ) |>
    mutate(across(
      c(cumulative_confirmed_cases, cumulative_confirmed_deaths),
      \(.x) coalesce(.x, 0L)
    )) |>
    mutate(
      cases_raw = cumulative_confirmed_cases -
        lag(cumulative_confirmed_cases, default = 0L),
      deaths_raw = cumulative_confirmed_deaths -
        lag(cumulative_confirmed_deaths, default = 0L),
      .by = nom
    ) |>
    # Replace negative values with zero, then distribute the negative values to previous days,
    # substracting from previous days' positive values until the negative value is fully accounted for.
    # This is done to avoid negative case counts in the daily data.
    mutate(
      cases = redistribute_negatives(cases_raw),
      deaths = redistribute_negatives(deaths_raw),
      .by = nom
    ) |>
    select(-cases_raw, -deaths_raw)

  cases
}

# Replace negative values with zero, then distribute the negative values to
# previous days, subtracting from previous days' positive values until the
# negative value is fully accounted for. Avoids negative case counts caused
# by downward corrections in cumulative source data.
redistribute_negatives <- function(x) {
  x <- as.numeric(x)
  for (i in seq_along(x)) {
    if (x[i] < 0) {
      deficit <- -x[i]
      x[i] <- 0
      j <- i - 1
      while (deficit > 0 && j >= 1) {
        if (x[j] > 0) {
          take <- min(x[j], deficit)
          x[j] <- x[j] - take
          deficit <- deficit - take
        }
        j <- j - 1
      }
    }
  }
  as.integer(x)
}
