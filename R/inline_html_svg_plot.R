inline_html_svg_plot <- function(
  obj,
  width = 3,
  height = width * 9 / 16,
  outfile = NULL,
  path = NULL,
  plain = TRUE,
  b64 = FALSE,
  img_attr = list(width = "100%", class = "figure"),
  bg = "#FFFFFF00",
  pointsize = 12,
  standalone = FALSE
) {
  # sans <- systemfonts::match_font("sans")$path
  # sans <- systemfonts::system_fonts()$family[
  #   systemfonts::system_fonts()$path == sans
  # ][1]
  # systemfonts::register_variant(
  #   name = "Sans EHA",
  #   family = sans,
  #   weight = "normal"
  # )

  s <- svglite::svgstring(
    width = width,
    height = height,
    standalone = standalone,
    bg = bg,
    pointsize = pointsize
  )
  print(obj)
  dev.off()

  st <- s()
  if (!is.null(outfile)) {
    cat(as.character(st), file = path("outputs", outfile))
    return(paste0(
      '<object data="',
      outfile,
      '" type="image/svg+xml"></object>'
    ))
  } else if (plain) {
    return(as.character(st))
  } else if (b64) {
    src <- paste0("data:image/svg+xml;base64,", base64encode(charToRaw(st)))
  } else if (is.null(path)) {
    src <- paste0("data:image/svg+xml;utf8,", st)
  } else {
    cat(st, path)
    src <- path
  }
  attrs <- c(img_attr, list(src = src))
  as.character(do.call(htmltools::img, attrs))
}
