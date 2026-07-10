targets_bdbv <- c(
  tar_url(
    insp_sitrep_cum_cases_csv_url,
    "https://raw.githubusercontent.com/INRB-UMIE/BDBV2026-Data/refs/heads/main/data/insp_sitrep/processed/insp_sitrep__cumulative_confirmed_cases__daily.csv"
  ),
  tar_file(
    insp_sitrep_cum_cases_csv,
    download_retry(insp_sitrep_cum_cases_csv_url, "data/insp_sitrep_cases.csv"),
    packages = "httr2"
  ),
  tar_url(
    insp_sitrep_cum_deaths_csv_url,
    "https://raw.githubusercontent.com/INRB-UMIE/BDBV2026-Data/refs/heads/main/data/insp_sitrep/processed/insp_sitrep__cumulative_confirmed_deaths__daily.csv"
  ),
  tar_file(
    insp_sitrep_cum_deaths_csv,
    download_retry(insp_sitrep_cum_deaths_csv_url, "data/insp_sitrep_deaths.csv"),
    packages = "httr2"
  ),
  tar_url(
    drc_health_zones_geojson_url,
    "https://raw.githubusercontent.com/INRB-UMIE/BDBV2026-Data/refs/heads/main/build/drc_health_zones.geojson"
  ),
  tar_file(
    drc_health_zones_geojson,
    download_retry(drc_health_zones_geojson_url, "data/drc_health_zones.geojson"),
    packages = "httr2"
  ),
  tar_quarto(
    drc_map_site,
    "www",
    quiet = FALSE,
  ),
  tar_assign({
    last_data_update <- max(
      gh_raw_url_commit_date(insp_sitrep_cum_cases_csv_url),
      gh_raw_url_commit_date(insp_sitrep_cum_deaths_csv_url)
    ) |>
      tar_target(packages = "gh")

    latest_sitrep <- get_latest_sitrep() |>
      tar_target(packages = c("gh", "lubridate"))

    insp_sitrep_cum_cases <- readr::read_csv(
      insp_sitrep_cum_cases_csv,
      col_types = "ccc",
      na = c("", "ND")
    ) |>
      mutate(
        date = lubridate::ymd(stri_replace_first_fixed(date, "]", ""))
      ) |>
      tar_target()

    insp_sitrep_cum_deaths <- readr::read_csv(
      insp_sitrep_cum_deaths_csv,
      col_types = "ccc",
      na = c("", "ND")
    ) |>
      mutate(
        date = lubridate::ymd(stri_replace_first_fixed(date, "]", ""))
      ) |>
      tar_target()

    cases <- process_sitrep(insp_sitrep_cum_cases, insp_sitrep_cum_deaths) |>
      group_by(nom) |>
      targets::tar_group() |>
      tar_target(iteration = "group")

    last_reported_date <- max(cases$date) |>
      tar_target()

    case_plots <- make_health_area_plot(cases) |>
      tar_target(
        pattern = map(cases),
        packages = c("dplyr", "ggplot2")
      )

    drc_health_zones <- sf::st_read(
      drc_health_zones_geojson,
      quiet = TRUE
    ) |>
      sf::st_as_sf() |>
      tar_target()

    drc_zone_w_plots <- drc_health_zones |>
      dplyr::select(nom, province) |>
      dplyr::inner_join(case_plots, join_by(nom)) |>
      sf::st_as_sf() |>
      tar_target()

    drc_bdbv_leaflet <- make_drc_bdbv_leaflet(drc_zone_w_plots) |>
      tar_target(
        packages = c("dplyr", "leaflet", "sf")
      )

    case_data_csv <- {
      # Reference `last_data_update` as a bare symbol (not inside the glue
      # string) so targets detects it as an upstream dependency.
      date_str <- format(last_data_update, "%Y-%m-%d")
      path <- fs::path(
        "www",
        glue::glue("case-data-INRB-UMIE-{date_str}.csv")
      )
      cases |>
        dplyr::select(-tar_group) |>
        readr::write_csv(path)
      path
    } |>
      tar_target(
        format = "file",
        packages = c("readr", "glue", "fs", "dplyr")
      )
  })
)
