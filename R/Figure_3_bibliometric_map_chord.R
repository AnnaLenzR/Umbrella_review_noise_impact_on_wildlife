# Figure 3: bibliometric geography of the included syntheses
# Standalone, reproducible R script.
#
# Panel A  world map of first-author countries (Equal Earth projection)
# Panel B  chord diagram of country co-authorship
#
# Country handling: UK constituent countries (England, Scotland, Wales,
# Northern Ireland) are collapsed to "United Kingdom" in BOTH panels so the two
# panels count the same way.

library(tidyverse)
library(here)
library(sf)
library(rnaturalearth)
library(circlize)
library(png)
library(patchwork)

# Panel B's co-authorship network comes from bibliometrix, matching the original
# Overview_figures.Rmd analysis. Set to FALSE to derive the same network directly
# from the Scopus affiliation strings instead (see build_edges_direct() below);
# both routes return the same 25 countries and 98 country pairs.
# Use the cleaned Scopus affiliation strings directly. This is equivalent to the
# bibliometrix route but avoids a version-sensitive `bibtag` import failure.
USE_BIBLIOMETRIX <- FALSE

biblio <- read_csv(here("Data", "Dataset2_bibliometric_data.csv"), show_col_types = FALSE)

colours <- c(
  ink = "#243746",
  muted_ink = "#52636F",
  paper = "#FBFAF8",
  land = "#E3E6E4",
  border = "#FBFAF8",
  graticule = "#DBE2E6"
)

base_size <- 12

# ---- Country cleaning -------------------------------------------------------

# Constituent countries of the UK, plus the spellings Scopus emits.
uk_parts <- c("england", "scotland", "wales", "northern ireland", "uk",
              "united kingdom", "united kingdom.")

clean_country <- function(x) {
  x <- str_trim(x)
  x <- str_remove(x, "\\.$")
  low <- str_to_lower(str_trim(x))
  case_when(
    low %in% uk_parts ~ "United Kingdom",
    low %in% c("usa", "united states", "united states of america") ~ "United States",
    low == "russian federation" ~ "Russia",
    low == "czech republic" ~ "Czechia",
    low == "viet nam" ~ "Vietnam",
    TRUE ~ x
  )
}

# Country sits in the last comma-separated slot of a Scopus affiliation string.
country_of <- function(affiliation) {
  map_chr(affiliation, ~ {
    parts <- str_split(.x, ",")[[1]]
    clean_country(parts[length(parts)])
  })
}

# ---- Panel A: first-author countries ----------------------------------------

first_author_country <- biblio %>%
  mutate(
    first_affiliation = map_chr(
      authors_with_affiliations,
      ~ str_trim(str_split(.x, ";")[[1]][1])
    ),
    country = country_of(first_affiliation)
  ) %>%
  count(country, name = "n_first_authors")

n_records <- nrow(biblio)

world <- ne_countries(scale = "medium", returnclass = "sf") %>%
  filter(admin != "Antarctica")

# Natural Earth uses its own naming; align the few that differ from Scopus.
ne_lookup <- c(
  "United States of America" = "United States",
  "United Kingdom" = "United Kingdom"
)

world_first <- world %>%
  mutate(
    match_name = recode(admin, !!!ne_lookup)
  ) %>%
  left_join(first_author_country, by = c("match_name" = "country"))

# Equal Earth: equal-area, so country sizes are proportionally honest, and it
# keeps the rounded silhouette that reads better than a plate carree rectangle.
crs_equal_earth <- "EPSG:8857"

world_ee <- st_transform(world_first, crs_equal_earth)
graticule <- st_graticule(
  lat = seq(-60, 80, 20),
  lon = seq(-180, 180, 60)
) %>%
  st_transform(crs_equal_earth)

land_bbox <- st_bbox(world_ee)

panel_a <- ggplot() +
  geom_sf(data = graticule, colour = colours["graticule"], linewidth = 0.25) +
  geom_sf(
    data = world_ee,
    aes(fill = n_first_authors),
    colour = colours["border"],
    linewidth = 0.12
  ) +
  scale_fill_stepsn(
    colours = c("#EBD9E6", "#D3A8CB", "#B173A8", "#8A4A82", "#5F2C5B"),
    na.value = colours["land"],
    breaks = c(2, 4, 6, 8),
    limits = c(0, 10),
    name = "First-author records",
    guide = guide_colorsteps(
      title.position = "top",
      barwidth = unit(190, "pt"),
      barheight = unit(10, "pt"),
      show.limits = FALSE
    )
  ) +
  # Crop to the land extent: with Antarctica dropped, the full projection would
  # leave a wide empty band of southern ocean.
  coord_sf(
    crs = crs_equal_earth,
    xlim = land_bbox[c("xmin", "xmax")],
    ylim = land_bbox[c("ymin", "ymax")],
    expand = FALSE
  ) +
  labs(tag = "A") +
  theme_void(base_size = base_size) +
  theme(
    plot.background = element_rect(fill = colours["paper"], colour = NA),
    legend.position = "bottom",
    legend.margin = margin(t = 2, b = 2),
    legend.title = element_text(size = base_size - 0.5, colour = colours["muted_ink"]),
    legend.text = element_text(size = base_size - 1, colour = colours["muted_ink"]),
    plot.tag = element_text(face = "bold", size = base_size + 6, colour = colours["ink"]),
    plot.tag.position = c(0, 1),
    plot.margin = margin(6, 6, 2, 6)
  )

# ---- Panel B: co-authorship chord -------------------------------------------

# Every country credited on a record, one row per record x country.
record_countries <- biblio %>%
  mutate(record = row_number()) %>%
  select(record, affiliations) %>%
  separate_rows(affiliations, sep = ";") %>%
  filter(str_trim(affiliations) != "") %>%
  mutate(country = country_of(affiliations)) %>%
  distinct(record, country)

# Records per country drives which sectors are small enough to pool.
records_per_country <- count(record_countries, country, name = "n_records")

# --- Route 1: bibliometrix (the analysis used in Overview_figures.Rmd) --------
build_edges_bibliometrix <- function() {
  bib <- bibliometrix::convert2df(
    here("Data", "bibliometric.bib"),
    dbsource = "scopus",
    format = "bibtex"
  )
  bib <- bibliometrix::metaTagExtraction(bib, Field = "AU_CO", sep = ";")
  net <- bibliometrix::biblioNetwork(
    bib,
    analysis = "collaboration",
    network = "countries",
    sep = ";"
  )
  m <- as.matrix(net)
  diag(m) <- 0
  m[lower.tri(m)] <- 0
  # bibliometrix returns upper-case country names.
  dimnames(m) <- list(
    clean_country(str_to_title(rownames(m))),
    clean_country(str_to_title(colnames(m)))
  )
  as.data.frame(as.table(m)) %>%
    set_names(c("country.x", "country.y", "n")) %>%
    mutate(across(c(country.x, country.y), as.character)) %>%
    filter(n > 0, country.x != country.y)
}

# --- Route 2: direct from Scopus affiliation strings -------------------------
build_edges_direct <- function() {
  record_countries %>%
    inner_join(record_countries, by = "record", relationship = "many-to-many") %>%
    filter(country.x < country.y) %>%
    count(country.x, country.y, name = "n")
}

edges_raw <- if (USE_BIBLIOMETRIX) {
  build_edges_bibliometrix()
} else {
  build_edges_direct()
}

# Countries credited on a single record are pooled into one "Other" sector; the
# ring is otherwise dominated by hairline sectors carrying long labels.
other_countries <- records_per_country %>%
  filter(n_records == 1) %>%
  pull(country) %>%
  sort()

other_label <- paste0("Other (", length(other_countries), ")")

pool <- function(x) if_else(x %in% other_countries, other_label, x)

edges <- edges_raw %>%
  mutate(country.x = pool(country.x), country.y = pool(country.y)) %>%
  # Re-sort each pair alphabetically so pooled duplicates merge cleanly.
  mutate(
    a = pmin(country.x, country.y),
    b = pmax(country.x, country.y)
  ) %>%
  summarise(n = sum(n), .by = c(a, b)) %>%
  rename(country.x = a, country.y = b)

# Order sectors by total collaboration volume, with Other pinned to the end.
country_strength <- bind_rows(
  edges %>% select(country = country.x, n),
  edges %>% select(country = country.y, n)
) %>%
  summarise(strength = sum(n), .by = country) %>%
  arrange(country == other_label, desc(strength))

chord_order <- country_strength$country

# Shorter display labels keep the ring from being swamped by text.
display_label <- function(x) {
  recode(
    x,
    "United States" = "USA",
    "United Kingdom" = "UK",
    .default = x
  )
}

adjacency <- edges %>%
  rename(from = country.x, to = country.y) %>%
  filter(from %in% chord_order, to %in% chord_order)

# Palette: distinct hues for the high-volume sectors, muted for the long tail.
sector_colours <- setNames(
  colorRampPalette(
    c("#6C5FC7", "#91D3C5", "#5D5D5D", "#BCCF7F", "#A9C7E8", "#C49ACF",
      "#B28A85", "#7A8BD1", "#6BB6C9", "#D6A9A5", "#E8C1A8", "#9FBBB0")
  )(length(chord_order)),
  chord_order
)

draw_chord <- function() {
  circos.clear()
  circos.par(
    track.margin = c(0.005, 0.005),
    gap.degree = 2.2,
    start.degree = 90,
    points.overflow.warning = FALSE,
    # Room for the outer labels so long names are not clipped.
    canvas.xlim = c(-1.16, 1.16),
    canvas.ylim = c(-1.16, 1.16)
  )
  chordDiagram(
    adjacency,
    order = chord_order,
    grid.col = sector_colours,
    transparency = 0.28,
    annotationTrack = "grid",
    annotationTrackHeight = mm_h(4),
    preAllocateTracks = list(track.height = 0.17),
    directional = 0,
    link.sort = TRUE,
    link.decreasing = TRUE
  )
  circos.trackPlotRegion(
    track.index = 1,
    bg.border = NA,
    panel.fun = function(x, y) {
      xlim <- get.cell.meta.data("xlim")
      sector <- get.cell.meta.data("sector.index")
      # Radial labels match the author-approved chord diagram.
      circos.text(
        mean(xlim), 0.86, display_label(sector),
        facing = "clockwise",
        niceFacing = TRUE,
        adj = c(0, 0.5),
        cex = 1.28,
        col = "#243746"
      )
    }
  )
  circos.clear()
}

# Capture the base-graphics chord as a high-resolution raster grob. This keeps
# the ring circular in patchwork without an additional conversion package.
chord_png <- tempfile(fileext = ".png")
grDevices::png(chord_png, width = 3000, height = 3000, res = 300, bg = colours["paper"])
draw_chord()
grDevices::dev.off()

chord_grob <- grid::rasterGrob(png::readPNG(chord_png), interpolate = TRUE)
unlink(chord_png)

panel_b <- patchwork::wrap_elements(full = chord_grob, clip = FALSE) +
  labs(tag = "B") +
  theme(
    plot.background = element_rect(fill = colours["paper"], colour = NA),
    plot.tag = element_text(face = "bold", size = base_size + 6, colour = colours["ink"]),
    plot.tag.position = c(0, 1),
    plot.margin = margin(-12, 6, 2, 6)
  )

# ---- Assemble ---------------------------------------------------------------

figure_3 <- panel_a / panel_b +
  plot_layout(heights = c(0.50, 1)) +
  plot_annotation(
    theme = theme(
      plot.background = element_rect(fill = colours["paper"], colour = NA),
      plot.margin = margin(8, 8, 8, 8)
    )
  )

ggsave(
  here("Figures", "raw", "Figure_3_bibliometric_map_chord.pdf"),
  figure_3,
  width = 10,
  height = 15,
  units = "in"
)

ggsave(
  here("Figures", "raw", "Figure_3_bibliometric_map_chord.png"),
  figure_3,
  width = 10,
  height = 15,
  units = "in",
  dpi = 300
)

message("network source: ", if (USE_BIBLIOMETRIX) "bibliometrix" else "direct",
        " | records: ", n_records,
        " | first-author countries: ", nrow(first_author_country),
        " | chord sectors: ", length(chord_order),
        " | edges: ", nrow(adjacency))

# For the figure caption: name the countries pooled into the Other sector.
message("\n", other_label, " comprises: ",
        paste(other_countries, collapse = ", "), ".")
