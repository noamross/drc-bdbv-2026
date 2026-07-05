#' .. content for \description{} (no empty lines) ..
#'
#' .. content for \details{} ..
#'
#' @title
#' @param drc_zone_w_plots
#' @return
#' @author Noam Ross
#' @export
make_drc_bdbv_leaflet <- function(drc_zone_w_plots) {
  ht <- if_else(interactive(), "1200px", "100vh")
  pal <- colorNumeric(
    palette = "plasma",
    domain = drc_zone_w_plots$cases_past_week
  )
  drc_bdbv_leaflet <-
    leaflet(
      width = "100%",
      height = ht,
      padding = 0,
      data = drc_zone_w_plots,
    ) |>
    addProviderTiles(
      providers$CartoDB.Positron
    ) |>
    addPolygons(
      fillOpacity = 0.25,
      color = "#03F",
      popup = ~svgplot,
      popupOptions = popupOptions(closeOnClick = TRUE, maxWidth = 600),
      fillColor = ~ pal(cases_past_week),
      weight = 0.75
    ) |>
    addLegend(
      position = "bottomright",
      pal = pal,
      values = ~cases_past_week,
      title = "Cases, past week"
    )
  drc_bdbv_leaflet
}
