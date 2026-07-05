targets_bdbv <- c(
  tar_download(
    insp_sitrep_cum_cases_csv,
    url = "https://raw.githubusercontent.com/INRB-UMIE/BDBV2026-Data/refs/heads/main/data/insp_sitrep/processed/insp_sitrep__cumulative_confirmed_cases__daily.csv",
    path = "data/insp_sitrep_cases.csv"
  ),
  tar_download(
    insp_sitrep_cum_deaths_csv,
    url = "https://raw.githubusercontent.com/INRB-UMIE/BDBV2026-Data/refs/heads/main/data/insp_sitrep/processed/insp_sitrep__cumulative_confirmed_deaths__daily.csv",
    path = "data/insp_sitrep_deaths.csv"
  ),
  tar_download(
    drc_health_zones_geojson,
    url = "https://raw.githubusercontent.com/INRB-UMIE/BDBV2026-Data/refs/heads/main/build/drc_health_zones.geojson",
    path = "data/drc_health_zones.geojson"
  ),
  tar_quarto(
    drc_map_site,
    "www"
  ),
  tar_assign({
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
  })
)
