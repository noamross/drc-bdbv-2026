make_health_area_plot <- function(cases) {
  #cases <- cases |> filter(nom == "Lita")
  area_name <- unique(cases$nom)
  if (length(area_name) != 1) {
    stop("cases must be for a single health area")
  }
  area_cases <- cases |>
    filter(nom == area_name)

  cases_past_week <- area_cases |>
    filter(date > max(date) - 7) |>
    summarise(cases_past_week = sum(cases, na.rm = TRUE)) |>
    pull(cases_past_week)

  plot_data <- area_cases |>
    select(date, cases, deaths) |>
    tidyr::pivot_longer(
      cols = c(cases, deaths),
      names_to = "type",
      values_to = "count"
    ) |>
    mutate(count = as.integer(count))

  plot <- ggplot(plot_data, aes(x = date, y = count, fill = type)) +
    geom_col(
      data = ~ filter(.x, type == "cases"),
      width = 0.6,
    ) +
    geom_col(
      data = ~ filter(.x, type == "deaths"),
      width = 0.6,
      position = position_nudge(x = 0.3),
      alpha = 0.8
    ) +
    theme_minimal() +
    scale_y_continuous(
      labels = scales::comma,
      breaks = integer_breaks(),
      limits = c(0, max(c(5, plot_data$count)))
    ) +
    labs(
      title = glue::glue(
        "Daily confirmed cases and deaths in {area_name} Health Zone"
      )
    ) +
    theme(
      axis.title = element_blank(),
      legend.position = "inside",
      legend.position.inside = c(0.05, 0.9),
      legend.title = element_blank(),
      legend.text = element_text(size = 10)
    )

  plot_svg <- inline_html_svg_plot(
    plot,
    width = 6,
    height = 6 * 9 / 16,
    img_attr = list(width = "100%", class = "figure"),
    bg = "#FFFFFF00",
    pointsize = 12
  )

  bar_tooltips <- scales::comma(c(
    plot_data |> filter(type == "cases") |> pull(count),
    plot_data |> filter(type == "deaths") |> pull(count)
  ))
  plot_svg <- svg_add_bar_tooltips(plot_svg, bar_tooltips)

  plot_out <- tibble(
    nom = area_name,
    svgplot = plot_svg,
    cases_past_week = cases_past_week
  )

  plot_out
}
