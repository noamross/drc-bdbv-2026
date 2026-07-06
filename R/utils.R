integer_breaks <- function(n = 5) {
  function(x) unique(floor(pretty(x, n)))
}
# Add a native SVG <title> child (browser hover tooltip, no JS) to each bar
# rect in an svglite-rendered ggplot bar chart. `tooltips` must be given in
# the order bars are drawn: layer by layer, in each layer's data row order.
# The panel's data rects are identified as the <g clip-path=...> group with
# the most direct <rect> children (background/legend live in other such
# groups with far fewer rects).
svg_add_bar_tooltips <- function(svg_text, tooltips) {
  doc <- xml2::read_xml(svg_text)
  xml2::xml_ns_strip(doc)
  groups <- xml2::xml_find_all(doc, ".//g[@clip-path]")
  rect_counts <- vapply(
    groups,
    \(g) length(xml2::xml_find_all(g, "./rect")),
    integer(1)
  )
  panel_group <- groups[[which.max(rect_counts)]]
  bars <- xml2::xml_find_all(panel_group, "./rect")
  stopifnot(length(bars) == length(tooltips))
  for (i in seq_along(bars)) {
    xml2::xml_add_child(bars[[i]], "title", tooltips[i])
  }
  as.character(doc)
}
