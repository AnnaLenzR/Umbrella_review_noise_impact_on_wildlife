# Figure 1: hybrid radial evidence wheel
# Doughnuts are used only for mutually exclusive partitions.
# Overlapping categories are represented by count bars or bubbles.

library(tidyverse)
library(here)
library(grid)

map <- read_csv(
  here("Data", "Dataset1_map_data_extraction.csv"),
  show_col_types = FALSE
)

n_syntheses <- n_distinct(map$study_id)

pal <- c(
  ink = "#243746",
  muted = "#5A6973",
  navy = "#315F7D",
  coral = "#B5687A",
  teal = "#568589",
  plum = "#74627D",
  pale_navy = "#DCE7ED",
  pale_coral = "#EEDDE2",
  pale_teal = "#DCE9E8",
  pale_plum = "#E7E1E9",
  paper = "#FBFAF8",
  line = "#CCD4D9"
)

split_categories <- function(data, variable) {
  data %>%
    select(study_id, {{ variable }}) %>%
    separate_rows({{ variable }}, sep = ",") %>%
    mutate({{ variable }} := str_trim({{ variable }})) %>%
    filter(!is.na({{ variable }}), {{ variable }} != "") %>%
    distinct()
}

# Return polygon coordinates for one annular segment.
arc_polygon <- function(cx, cy, start, end, inner, outer, id, fill, n = 80) {
  theta <- seq(start, end, length.out = n)
  tibble(
    x = c(cx + outer * cos(theta), cx + inner * cos(rev(theta))),
    y = c(cy + outer * sin(theta), cy + inner * sin(rev(theta))),
    id = id,
    fill = fill
  )
}

# Return polygons and label positions for a doughnut.
make_donut <- function(values, labels, fills, cx, cy, inner, outer, start = pi / 2) {
  cumulative <- c(0, cumsum(values) / sum(values) * 2 * pi)
  polygons <- map_dfr(seq_along(values), function(i) {
    arc_polygon(
      cx, cy,
      start - cumulative[i + 1],
      start - cumulative[i],
      inner, outer,
      paste0(cx, "_", cy, "_", i),
      fills[i]
    )
  })
  mid <- start - (cumulative[-1] + cumulative[-length(cumulative)]) / 2
  label_radius <- (inner + outer) / 2
  label_data <- tibble(
    x = cx + label_radius * cos(mid),
    y = cy + label_radius * sin(mid),
    label = paste(labels, values),
    text_colour = if_else(fills %in% c(pal["navy"], pal["coral"]), "white", pal["ink"])
  )
  list(polygons = polygons, labels = label_data)
}

# ---- Summaries ---------------------------------------------------------------

approach_year <- map %>%
  transmute(
    study_id,
    year,
    approach = if_else(
      str_to_lower(str_trim(quantitative)) == "yes",
      "Quantitative",
      "Narrative/Descriptive"
    )
  ) %>%
  distinct() %>%
  count(year, approach, name = "n") %>%
  complete(
    year = seq(min(map$year), max(map$year)),
    approach = c("Narrative/Descriptive", "Quantitative"),
    fill = list(n = 0)
  )

approach_counts <- approach_year %>%
  summarise(n = sum(n), .by = approach) %>%
  arrange(match(approach, c("Narrative/Descriptive", "Quantitative")))

outcomes <- split_categories(map, outcome_category)
outcome_breadth <- outcomes %>%
  count(study_id, name = "categories") %>%
  count(breadth = if_else(categories == 1, "Single", "Multiple"), name = "n") %>%
  arrange(match(breadth, c("Multiple", "Single")))

noise <- split_categories(map, noise_source)
noise_breadth <- noise %>%
  count(study_id, name = "categories") %>%
  count(breadth = if_else(categories == 1, "Single", "Multiple"), name = "n") %>%
  arrange(match(breadth, c("Multiple", "Single")))

environments <- split_categories(map, ecosystem_type)
environment_counts <- environments %>%
  count(ecosystem_type, name = "n") %>%
  arrange(desc(n))

vertebrate_taxa <- c("Aves", "Mammalia", "Reptilia", "Fish", "Amphibia")
invertebrate_taxa <- c(
  "Invertebrates", "Arthropoda", "Mollusca", "Cnidaria",
  "Echinodermata", "Annelida", "Bryozoa"
)

taxonomic_membership <- map %>%
  select(study_id, scope_taxon) %>%
  separate_rows(scope_taxon, sep = ",") %>%
  mutate(
    scope_taxon = str_to_title(str_trim(scope_taxon)),
    group = case_when(
      scope_taxon %in% vertebrate_taxa ~ "Vertebrate",
      scope_taxon %in% invertebrate_taxa ~ "Invertebrate",
      TRUE ~ NA_character_
    )
  ) %>%
  filter(!is.na(group)) %>%
  distinct(study_id, group)

taxonomic_counts <- taxonomic_membership %>%
  count(group, name = "n") %>%
  arrange(match(group, c("Vertebrate", "Invertebrate")))

taxonomic_overlap <- taxonomic_membership %>%
  count(study_id) %>%
  summarise(n = sum(n == 2)) %>%
  pull(n)

# ---- Radial publication histogram -------------------------------------------

year_sequence <- seq(min(map$year), max(map$year))
year_angles <- tibble(
  year = year_sequence,
  mid = seq(pi * 0.92, pi * 0.08, length.out = length(year_sequence))
)

year_dots <- approach_year %>%
  summarise(n = sum(n), .by = year) %>%
  left_join(year_angles, by = "year") %>%
  mutate(
    radius = 22,
    x = 50 + radius * cos(mid),
    y = 35 + radius * sin(mid),
    point_colour = if_else(n == 0, pal["line"], pal["navy"])
  )

# ---- Doughnuts ---------------------------------------------------------------

approach_donut <- make_donut(
  approach_counts$n,
  c("Narrative", "Quantitative"),
  c(pal["coral"], pal["navy"]),
  cx = 18, cy = 40, inner = 4.8, outer = 8.0
)

outcome_donut <- make_donut(
  outcome_breadth$n,
  outcome_breadth$breadth,
  c(pal["coral"], pal["pale_coral"]),
  cx = 42, cy = 17.5, inner = 3.7, outer = 6.2
)

noise_donut <- make_donut(
  noise_breadth$n,
  noise_breadth$breadth,
  c(pal["navy"], pal["pale_navy"]),
  cx = 79, cy = 22.5, inner = 3.7, outer = 6.2
)

# ---- Overlapping-category marks ---------------------------------------------

environment_marks <- environment_counts %>%
  mutate(
    y = seq(18.2, 8.0, length.out = n()),
    x0 = 6.0,
    x1 = x0 + scales::rescale(n, to = c(5, 18))
  )

# ---- One integrated wheel ----------------------------------------------------

figure_1_radial_wheel <- ggplot() +
  theme_void(base_size = 12) +
  theme(
    plot.background = element_rect(fill = pal["paper"], colour = NA),
    plot.margin = margin(14, 14, 14, 14)
  ) +
  coord_equal(xlim = c(0, 100), ylim = c(0, 72), clip = "off") +
  # Light spokes
  geom_segment(
    aes(
      x = c(44, 56, 45, 55),
      y = c(32, 32, 29, 29),
      xend = c(26, 74, 31, 73),
      yend = c(40, 40, 18, 22.5)
    ),
    colour = pal["line"],
    linewidth = 1.0,
    lineend = "round"
  ) +
  # Publication-year bubble timeline
  geom_point(
    data = year_dots,
    aes(x, y, size = n),
    shape = 21,
    stroke = 0.7,
    fill = year_dots$point_colour,
    colour = pal["paper"]
  ) +
  scale_size_continuous(
    range = c(2.5, 10),
    limits = c(0, 10),
    guide = "none"
  ) +
  scale_fill_identity() +
  annotate(
    "text", x = 50, y = 66.5, label = "PUBLICATION YEARS",
    size = 4.8, fontface = "bold", colour = pal["ink"]
  ) +
  annotate(
    "text", x = c(28.3, 71.7), y = c(54.0, 54.0),
    label = c(min(map$year), max(map$year)),
    size = 4.25, colour = pal["muted"]
  ) +
  annotate(
    "text", x = 50, y = 62.7,
    label = "Peak: 10 syntheses in 2024",
    size = 4.25, colour = pal["muted"]
  ) +
  # Central node
  annotate(
    "point", x = 50, y = 35,
    shape = 21, size = 50, stroke = 1.2,
    fill = pal["ink"], colour = pal["paper"]
  ) +
  annotate(
    "text", x = 50, y = 36.2, label = n_syntheses,
    size = 8.2, fontface = "bold", colour = "white"
  ) +
  annotate(
    "text", x = 50, y = 33.4, label = "syntheses",
    size = 4.25, colour = "white"
  ) +
  # Approach doughnut
  geom_polygon(
    data = approach_donut$polygons,
    aes(x, y, group = id, fill = fill),
    colour = pal["paper"],
    linewidth = 0.8
  ) +
  annotate(
    "text", x = 18, y = 50.5, label = "SYNTHESIS APPROACH",
    size = 4.8, fontface = "bold", colour = pal["ink"]
  ) +
  annotate(
    "text", x = c(11.5, 24.5), y = c(30.7, 30.7),
    label = c("Narrative/Descriptive\n27", "Quantitative\n23"),
    size = 4.25, colour = c(pal["coral"], pal["navy"])
  ) +
  # Taxonomic bubbles
  annotate(
    "text", x = 82, y = 50.5, label = "TAXONOMIC SCOPE",
    size = 4.8, fontface = "bold", colour = pal["ink"]
  ) +
  annotate(
    "point", x = c(78, 89), y = c(41.5, 41.5),
    shape = 21, size = c(29, 21), stroke = 0,
    fill = c(pal["plum"], pal["teal"])
  ) +
  annotate(
    "text", x = c(78, 89), y = c(41.5, 41.5),
    label = c(47, 24),
    size = 5.4, fontface = "bold", colour = "white"
  ) +
  annotate(
    "text", x = c(78, 89), y = c(36.8, 36.8),
    label = c("Vertebrate", "Invertebrate"),
    size = 4.25, colour = pal["ink"]
  ) +
  annotate(
    "text", x = 83.5, y = 34.3,
    label = paste(taxonomic_overlap, "included both"),
    size = 4.25, colour = pal["muted"]
  ) +
  # Environments
  annotate(
    "text", x = 15, y = 25.5, label = "ENVIRONMENTS",
    size = 4.8, fontface = "bold", colour = pal["ink"]
  ) +
  geom_segment(
    data = environment_marks,
    aes(x = x0, xend = x1, y = y, yend = y),
    linewidth = 8, lineend = "round", colour = pal["teal"]
  ) +
  geom_text(
    data = environment_marks,
    aes(x = 4.8, y = y, label = ecosystem_type),
    hjust = 1, size = 4.25, colour = pal["ink"]
  ) +
  geom_text(
    data = environment_marks,
    aes(x = x1 + 0.8, y = y, label = n),
    hjust = 0, size = 4.25, colour = pal["ink"]
  ) +
  annotate(
    "text", x = 15, y = 4.1,
    label = "78 assignments  |  mean 1.56",
    size = 4.25, colour = pal["muted"]
  ) +
  # Outcomes: mutually exclusive breadth
  annotate(
    "text", x = 42, y = 25.5, label = "BIOLOGICAL OUTCOMES",
    size = 4.8, fontface = "bold", colour = pal["ink"]
  ) +
  geom_polygon(
    data = outcome_donut$polygons,
    aes(x, y, group = id, fill = fill),
    colour = pal["paper"],
    linewidth = 0.7
  ) +
  annotate(
    "text", x = 42, y = 17.5,
    label = "35 multiple\n15 single",
    size = 4.25, colour = pal["ink"]
  ) +
  # Noise: mutually exclusive breadth
  annotate(
    "text", x = 79, y = 30.8, label = "NOISE SOURCES",
    size = 4.8, fontface = "bold", colour = pal["ink"]
  ) +
  geom_polygon(
    data = noise_donut$polygons,
    aes(x, y, group = id, fill = fill),
    colour = pal["paper"],
    linewidth = 0.7
  ) +
  annotate(
    "text", x = 79, y = 22.5,
    label = "33 multiple\n17 single",
    size = 4.25, colour = pal["ink"]
  ) +
  annotate(
    "text", x = 50, y = 0.8,
    label = "Taxonomic and environmental counts are non-exclusive.",
    size = 4.25, colour = pal["muted"]
  )

figure_1_radial_wheel

ggsave(
  here("Figures", "raw", "Figure_1_systematic_map_radial_wheel.pdf"),
  figure_1_radial_wheel,
  width = 14,
  height = 10,
  units = "in"
)

ggsave(
  here("Figures", "raw", "Figure_1_systematic_map_radial_wheel.png"),
  figure_1_radial_wheel,
  width = 14,
  height = 10,
  units = "in",
  dpi = 300
)
