# Figure 1: systematic-map evidence landscape
# Standalone, reproducible R script.

library(tidyverse)
library(here)
library(grid)

map <- read_csv(
  here("Data", "Dataset1_map_data_extraction.csv"),
  show_col_types = FALSE
)

n_syntheses <- n_distinct(map$study_id)

# Restrained complementary palette inspired by editorial data graphics.
colours <- c(
  ink = "#243746",
  muted_ink = "#52636F",
  navy = "#315F7D",
  coral = "#B5687A",
  teal = "#568589",
  plum = "#74627D",
  pale_navy = "#DCE7ED",
  pale_coral = "#EEDDE2",
  pale_teal = "#DCE9E8",
  pale_plum = "#E7E1E9",
  paper = "#FBFAF8",
  line = "#CBD3D8"
)

split_categories <- function(data, variable) {
  data %>%
    select(study_id, {{ variable }}) %>%
    separate_rows({{ variable }}, sep = ",") %>%
    mutate({{ variable }} := str_trim({{ variable }})) %>%
    filter(!is.na({{ variable }}), {{ variable }} != "") %>%
    distinct()
}

# ---- Data summaries ----------------------------------------------------------

approach_by_year <- map %>%
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
    year = seq(min(map$year, na.rm = TRUE), max(map$year, na.rm = TRUE)),
    approach = c("Narrative/Descriptive", "Quantitative"),
    fill = list(n = 0)
  )

year_totals <- approach_by_year %>%
  summarise(n = sum(n), .by = year)

approach_counts <- approach_by_year %>%
  summarise(n = sum(n), .by = approach)

outcomes <- split_categories(map, outcome_category)
outcome_counts <- outcomes %>%
  count(outcome_category, name = "n") %>%
  arrange(desc(n))
outcome_breadth <- outcomes %>%
  count(study_id, name = "categories") %>%
  count(
    breadth = if_else(categories == 1, "Single", "Multiple"),
    name = "n"
  )

environments <- split_categories(map, ecosystem_type)
environment_counts <- environments %>%
  count(ecosystem_type, name = "n") %>%
  arrange(desc(n))

noise <- split_categories(map, noise_source)
noise_counts <- noise %>%
  count(noise_source, name = "n") %>%
  arrange(desc(n))
noise_breadth <- noise %>%
  count(study_id, name = "categories") %>%
  count(
    breadth = if_else(categories == 1, "Single", "Multiple"),
    name = "n"
  )

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
  count(group, name = "n")

taxonomic_overlap <- taxonomic_membership %>%
  count(study_id) %>%
  summarise(n = sum(n == 2)) %>%
  pull(n)

# ---- Canvas helpers ----------------------------------------------------------

card <- function(xmin, xmax, ymin, ymax, fill) {
  annotation_custom(
    roundrectGrob(
      r = unit(0.045, "snpc"),
      gp = gpar(fill = fill, col = NA)
    ),
    xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax
  )
}

branch_data <- tribble(
  ~x, ~y, ~xend, ~yend,
  50, 40, 50, 57,
  44, 40, 28, 48,
  56, 40, 72, 48,
  45, 35, 30, 24,
  50, 34, 50, 24,
  55, 35, 70, 27
)

# Timeline coordinates inside the upper card.
timeline <- approach_by_year %>%
  mutate(
    x = scales::rescale(year, to = c(25, 75)),
    height = n * 0.78
  ) %>%
  arrange(year, approach) %>%
  group_by(year) %>%
  mutate(
    ymin = 59 + lag(cumsum(height), default = 0),
    ymax = ymin + height,
    fill = if_else(
      approach == "Quantitative",
      colours["navy"],
      colours["coral"]
    )
  ) %>%
  ungroup()

timeline_labels <- year_totals %>%
  filter(n > 0) %>%
  mutate(
    x = scales::rescale(year, to = c(25, 75)),
    y = 59 + n * 0.78 + 0.55
  )

# Environment mini bars.
environment_marks <- environment_counts %>%
  mutate(
    y = seq(20.8, 10.0, length.out = n()),
    x0 = 7.5,
    x1 = x0 + scales::rescale(n, to = c(4.5, 16.5))
  )

# Outcome mini bars.
outcome_marks <- outcome_counts %>%
  mutate(
    y = seq(17.0, 6.0, length.out = n()),
    x0 = 42.0,
    x1 = x0 + scales::rescale(n, to = c(2.5, 15.5))
  )

# Noise-source mini bars.
noise_marks <- noise_counts %>%
  mutate(
    y = seq(24.0, 6.0, length.out = n()),
    x0 = 79.0,
    x1 = x0 + scales::rescale(n, to = c(2.0, 14.0))
  )

# Mutually exclusive split bars.
outcome_split <- outcome_breadth %>%
  mutate(
    xmin = c(37.5, 37.5 + first(n[breadth == "Multiple"]) / 50 * 25),
    xmax = c(37.5 + first(n[breadth == "Multiple"]) / 50 * 25, 62.5),
    fill = c(colours["coral"], colours["pale_coral"]),
    text_colour = if_else(breadth == "Multiple", "white", colours["ink"])
  ) %>%
  arrange(desc(breadth))

noise_split <- noise_breadth %>%
  mutate(
    xmin = c(69.0, 69.0 + first(n[breadth == "Multiple"]) / 50 * 27),
    xmax = c(69.0 + first(n[breadth == "Multiple"]) / 50 * 27, 96.0),
    fill = c(colours["navy"], colours["pale_navy"]),
    text_colour = if_else(breadth == "Multiple", "white", colours["ink"])
  ) %>%
  arrange(desc(breadth))

# ---- Draw one integrated figure ---------------------------------------------

figure_1_mindmap <- ggplot() +
  # Paper and cards
  theme_void(base_size = 12) +
  theme(
    plot.background = element_rect(fill = colours["paper"], colour = NA),
    plot.margin = margin(12, 12, 12, 12)
  ) +
  coord_cartesian(xlim = c(0, 100), ylim = c(0, 72), clip = "off") +
  card(19, 81, 56.5, 70.5, "white") +
  card(2, 30, 42.0, 54.5, colours["pale_coral"]) +
  card(70, 98, 42.0, 54.5, colours["pale_plum"]) +
  card(2, 32, 4.0, 29.5, colours["pale_teal"]) +
  card(34, 65, 3.0, 26.5, "white") +
  card(67, 98, 3.0, 36.0, "white") +
  # Connecting branches
  geom_curve(
    data = branch_data,
    aes(x = x, y = y, xend = xend, yend = yend),
    curvature = 0.10,
    colour = colours["line"],
    linewidth = 1.1,
    lineend = "round"
  ) +
  # Central synthesis node
  geom_point(
    aes(x = 50, y = 40),
    shape = 21,
    size = 42,
    stroke = 1.3,
    fill = colours["ink"],
    colour = "white"
  ) +
  annotate(
    "text", x = 50, y = 41.1, label = n_syntheses,
    size = 8.0, fontface = "bold", colour = "white"
  ) +
  annotate(
    "text", x = 50, y = 38.4, label = "syntheses",
    size = 4.25, colour = "white"
  ) +
  # Publication timeline
  annotate(
    "text", x = 22, y = 68.5, label = "PUBLICATION YEARS",
    hjust = 0, size = 4.7, fontface = "bold", colour = colours["ink"]
  ) +
  geom_rect(
    data = timeline,
    aes(xmin = x - 0.58, xmax = x + 0.58, ymin = ymin, ymax = ymax),
    fill = timeline$fill,
    colour = NA
  ) +
  geom_text(
    data = timeline_labels,
    aes(x = x, y = y, label = n),
    size = 4.25,
    colour = colours["ink"]
  ) +
  annotate(
    "text", x = c(25, 75), y = 58.0,
    label = c(min(map$year), max(map$year)),
    hjust = c(0.5, 0.5), size = 4.25, colour = colours["muted_ink"]
  ) +
  annotate(
    "point", x = c(48, 66), y = c(68.4, 68.4),
    shape = 15, size = 5,
    colour = c(colours["coral"], colours["navy"])
  ) +
  annotate(
    "text", x = c(49.2, 67.2), y = c(68.4, 68.4),
    label = c("Narrative/Descriptive 27", "Quantitative 23"),
    hjust = 0, size = 4.25, colour = colours["ink"]
  ) +
  # Synthesis approach
  annotate(
    "text", x = 5, y = 52.0, label = "SYNTHESIS APPROACH",
    hjust = 0, size = 4.7, fontface = "bold", colour = colours["ink"]
  ) +
  annotate(
    "point", x = c(10.5, 22.0), y = c(48.0, 48.0),
    size = 18, shape = 21, stroke = 0,
    fill = c(colours["coral"], colours["navy"])
  ) +
  annotate(
    "text", x = c(10.5, 22.0), y = c(48.0, 48.0),
    label = c("27", "23"),
    size = 5.2, fontface = "bold", colour = "white"
  ) +
  annotate(
    "text", x = c(10.5, 22.0), y = c(44.8, 44.8),
    label = c("Narrative/Descriptive", "Quantitative"),
    size = 4.25, colour = colours["ink"]
  ) +
  # Taxonomic scope
  annotate(
    "text", x = 73, y = 52.0, label = "TAXONOMIC SCOPE",
    hjust = 0, size = 4.7, fontface = "bold", colour = colours["ink"]
  ) +
  annotate(
    "point", x = c(78.5, 89.8), y = c(47.0, 47.0),
    size = c(26, 20), shape = 21, stroke = 0,
    fill = c(colours["plum"], colours["teal"])
  ) +
  annotate(
    "text", x = c(78.5, 89.8), y = c(47.0, 47.0),
    label = c("47", "24"),
    size = 5.0, fontface = "bold", colour = "white"
  ) +
  annotate(
    "text", x = c(78.5, 89.8), y = c(44.5, 44.5),
    label = c("Vertebrate", "Invertebrate"),
    size = 4.25, colour = colours["ink"]
  ) +
  annotate(
    "text", x = 84, y = 42.9,
    label = paste(taxonomic_overlap, "included both"),
    size = 4.25, colour = colours["muted_ink"]
  ) +
  # Environmental scope
  annotate(
    "text", x = 5, y = 27.2, label = "ENVIRONMENTS",
    hjust = 0, size = 4.7, fontface = "bold", colour = colours["ink"]
  ) +
  geom_segment(
    data = environment_marks,
    aes(x = x0, xend = x1, y = y, yend = y),
    linewidth = 8, lineend = "round", colour = colours["teal"]
  ) +
  geom_text(
    data = environment_marks,
    aes(x = 6.2, y = y, label = ecosystem_type),
    hjust = 1, size = 4.25, colour = colours["ink"]
  ) +
  geom_text(
    data = environment_marks,
    aes(x = x1 + 1.0, y = y, label = n),
    hjust = 0, size = 4.25, colour = colours["ink"]
  ) +
  annotate(
    "text", x = 5, y = 6.0,
    label = "78 category assignments  |  mean 1.56",
    hjust = 0, size = 4.25, colour = colours["muted_ink"]
  ) +
  # Outcome scope
  annotate(
    "text", x = 37, y = 24.2, label = "BIOLOGICAL OUTCOMES",
    hjust = 0, size = 4.7, fontface = "bold", colour = colours["ink"]
  ) +
  geom_rect(
    data = outcome_split,
    aes(xmin = xmin, xmax = xmax, ymin = 20.3, ymax = 22.4),
    fill = outcome_split$fill, colour = NA
  ) +
  geom_text(
    data = outcome_split,
    aes(x = (xmin + xmax) / 2, y = 21.35, label = paste(breadth, n)),
    size = 4.25,
    colour = outcome_split$text_colour
  ) +
  geom_segment(
    data = outcome_marks,
    aes(x = x0, xend = x1, y = y, yend = y),
    linewidth = 5.2, lineend = "round", colour = colours["coral"]
  ) +
  geom_text(
    data = outcome_marks,
    aes(x = 40.9, y = y, label = outcome_category),
    hjust = 1, size = 4.25, colour = colours["ink"]
  ) +
  geom_text(
    data = outcome_marks,
    aes(x = x1 + 0.65, y = y, label = n),
    hjust = 0, size = 4.25, colour = colours["ink"]
  ) +
  # Noise scope
  annotate(
    "text", x = 70, y = 33.6, label = "NOISE SOURCES",
    hjust = 0, size = 4.7, fontface = "bold", colour = colours["ink"]
  ) +
  geom_rect(
    data = noise_split,
    aes(xmin = xmin, xmax = xmax, ymin = 29.4, ymax = 31.8),
    fill = noise_split$fill, colour = NA
  ) +
  geom_text(
    data = noise_split,
    aes(x = (xmin + xmax) / 2, y = 30.6, label = paste(breadth, n)),
    size = 4.25,
    colour = noise_split$text_colour
  ) +
  geom_segment(
    data = noise_marks,
    aes(x = x0, xend = x1, y = y, yend = y),
    linewidth = 4.3, lineend = "round", colour = colours["navy"]
  ) +
  geom_text(
    data = noise_marks,
    aes(x = 77.9, y = y, label = noise_source),
    hjust = 1, size = 4.25, colour = colours["ink"]
  ) +
  geom_text(
    data = noise_marks,
    aes(x = x1 + 0.55, y = y, label = n),
    hjust = 0, size = 4.25, colour = colours["ink"]
  ) +
  annotate(
    "text", x = 50, y = 0.6,
    label = paste0(
      "Taxonomic, environmental, outcome-category, and noise-source counts ",
      "are non-exclusive."
    ),
    size = 4.25, colour = colours["muted_ink"]
  )

figure_1_mindmap

# Preserve the minimum 12-point typography by exporting at the dimensions below.
ggsave(
  here("Figures", "raw", "Figure_1_systematic_map_mindmap.pdf"),
  figure_1_mindmap,
  width = 14,
  height = 10,
  units = "in"
)

ggsave(
  here("Figures", "raw", "Figure_1_systematic_map_mindmap.png"),
  figure_1_mindmap,
  width = 14,
  height = 10,
  units = "in",
  dpi = 300
)
