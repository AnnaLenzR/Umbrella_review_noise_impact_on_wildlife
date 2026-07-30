# Figure 1: systematic-map evidence landscape
# Standalone, reproducible R script.
#
# Panel A  publication year and synthesis approach
# Panel B  evidence matrix, noise source x biological outcome
# Panel C  taxonomic scope
# Panel D  environmental scope
# Panel E  coverage breadth (single vs multiple categories per synthesis)
#
# All interpretation lives in the caption; the figure states only what was measured.

library(tidyverse)
library(here)
library(patchwork)

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
  moss = "#6E7F5B",
  slate = "#8A8F98",
  pale_navy = "#DCE7ED",
  pale_tile = "#EDF2F5",
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

# Label helper: "Transportation (37)".
with_total <- function(label, n) paste0(label, " (", n, ")")

# ---- Shared theme -----------------------------------------------------------

base_size <- 12

theme_map <- function() {
  theme_minimal(base_size = base_size) +
    theme(
      plot.background = element_rect(fill = colours["paper"], colour = NA),
      panel.background = element_rect(fill = colours["paper"], colour = NA),
      panel.grid = element_blank(),
      plot.title = element_text(
        face = "bold", size = base_size + 1, colour = colours["ink"],
        margin = margin(b = 10)
      ),
      plot.tag = element_text(
        face = "bold", size = base_size + 6, colour = colours["ink"]
      ),
      plot.tag.position = c(0, 1),
      axis.text = element_text(colour = colours["ink"], size = base_size - 0.5),
      axis.title = element_text(colour = colours["muted_ink"], size = base_size - 1),
      legend.text = element_text(colour = colours["muted_ink"], size = base_size - 1.5),
      legend.title = element_text(colour = colours["muted_ink"], size = base_size - 1.5),
      plot.margin = margin(10, 12, 10, 12)
    )
}

# ---- Panel A: publication year and synthesis approach -----------------------

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

approach_counts <- approach_by_year %>%
  summarise(n = sum(n), .by = approach)

approach_labels <- set_names(
  with_total(approach_counts$approach, approach_counts$n),
  approach_counts$approach
)

year_totals <- approach_by_year %>%
  summarise(n = sum(n), .by = year) %>%
  filter(n > 0)

panel_a <- ggplot(approach_by_year, aes(x = year, y = n, fill = approach)) +
  geom_col(width = 0.62) +
  geom_text(
    data = year_totals,
    aes(x = year, y = n, label = n),
    inherit.aes = FALSE,
    vjust = -0.6,
    size = base_size / .pt * 0.92,
    colour = colours["muted_ink"]
  ) +
  scale_fill_manual(
    values = c(
      "Narrative/Descriptive" = unname(colours["coral"]),
      "Quantitative" = unname(colours["navy"])
    ),
    labels = approach_labels,
    name = NULL
  ) +
  scale_x_continuous(
    breaks = seq(min(approach_by_year$year), max(approach_by_year$year), by = 1),
    expand = expansion(mult = 0.015)
  ) +
  scale_y_continuous(
    breaks = c(0, 5, 10),
    expand = expansion(mult = c(0, 0.22))
  ) +
  labs(tag = "A", title = "PUBLICATION YEAR AND SYNTHESIS APPROACH", y = "Syntheses", x = NULL) +
  theme_map() +
  theme(
    panel.grid.major.y = element_line(colour = colours["line"], linewidth = 0.3),
    legend.position = c(0.01, 1.06),
    legend.justification = c(0, 1),
    legend.direction = "horizontal",
    legend.key.size = unit(11, "pt"),
    plot.title = element_text(
      face = "bold", size = base_size + 1, colour = colours["ink"],
      margin = margin(b = 22)
    )
  )

# ---- Panel B: evidence matrix ----------------------------------------------

noise_long <- split_categories(map, noise_source)
outcome_long <- split_categories(map, outcome_category)

noise_totals <- noise_long %>%
  count(noise_source, name = "total") %>%
  arrange(desc(total))

outcome_totals <- outcome_long %>%
  count(outcome_category, name = "total") %>%
  arrange(desc(total))

crosstab <- noise_long %>%
  inner_join(outcome_long, by = "study_id", relationship = "many-to-many") %>%
  count(noise_source, outcome_category, name = "n") %>%
  complete(
    noise_source = noise_totals$noise_source,
    outcome_category = outcome_totals$outcome_category,
    fill = list(n = 0)
  ) %>%
  left_join(noise_totals, by = "noise_source") %>%
  left_join(outcome_totals, by = "outcome_category") %>%
  mutate(
    noise_label = factor(
      with_total(noise_source, total.x),
      levels = rev(with_total(noise_totals$noise_source, noise_totals$total))
    ),
    outcome_label = factor(
      with_total(outcome_category, total.y),
      levels = with_total(outcome_totals$outcome_category, outcome_totals$total)
    ),
    # White numerals only where the tile is dark enough to carry them.
    label_colour = if_else(n >= 13, "#FFFFFF", unname(colours["ink"])),
    label_colour = if_else(n == 0, unname(colours["line"]), label_colour)
  )

panel_b <- ggplot(crosstab, aes(x = outcome_label, y = noise_label, fill = n)) +
  geom_tile(colour = colours["paper"], linewidth = 1.4) +
  geom_text(
    aes(label = n, colour = label_colour),
    size = base_size / .pt * 0.95
  ) +
  scale_colour_identity() +
  scale_fill_gradient(
    low = colours["pale_tile"],
    high = colours["ink"],
    name = "Syntheses per combination",
    guide = guide_colourbar(
      title.position = "left",
      title.vjust = 0.9,
      barwidth = unit(110, "pt"),
      barheight = unit(7, "pt"),
      ticks = FALSE
    )
  ) +
  scale_x_discrete(position = "top", expand = expansion(0)) +
  scale_y_discrete(expand = expansion(0)) +
  labs(tag = "B", title = "EVIDENCE MATRIX — NOISE SOURCE × BIOLOGICAL OUTCOME",
       x = NULL, y = NULL) +
  theme_map() +
  theme(
    axis.text.x.top = element_text(angle = 40, hjust = 0, vjust = 0,
                                   colour = colours["ink"]),
    legend.position = "bottom",
    legend.justification = "left",
    legend.direction = "horizontal",
    legend.margin = margin(t = 10)
  )

# ---- Panel C: taxonomic scope ----------------------------------------------

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

# "Mixed" is the overlap of the two groups, not a third exclusive group: those
# syntheses are also counted in the Vertebrate and Invertebrate bars.
taxonomic_overlap <- taxonomic_membership %>%
  count(study_id) %>%
  summarise(n = sum(n == 2)) %>%
  pull(n)

taxonomic_counts <- taxonomic_membership %>%
  count(group, name = "n") %>%
  bind_rows(tibble(group = "Mixed", n = taxonomic_overlap)) %>%
  mutate(group = factor(group, levels = c("Mixed", "Invertebrate", "Vertebrate")))

panel_c <- ggplot(taxonomic_counts, aes(x = n, y = group, fill = group)) +
  geom_col(width = 0.62) +
  geom_text(
    aes(label = n),
    hjust = -0.35,
    size = base_size / .pt * 0.95,
    colour = colours["ink"]
  ) +
  scale_fill_manual(
    values = c(
      "Vertebrate" = unname(colours["plum"]),
      "Invertebrate" = unname(colours["teal"]),
      "Mixed" = unname(colours["slate"])
    ),
    guide = "none"
  ) +
  scale_x_continuous(limits = c(0, n_syntheses), expand = expansion(mult = c(0, 0.02))) +
  scale_y_discrete(expand = expansion(add = 0.5)) +
  labs(tag = "C", title = "TAXONOMIC SCOPE", x = NULL, y = NULL) +
  theme_map() +
  theme(
    axis.text.x = element_blank(),
    plot.title = element_text(
      face = "bold", size = base_size + 1, colour = colours["ink"],
      margin = margin(b = 4)
    )
  )

# ---- Panel D: environmental scope -------------------------------------------

environment_counts <- split_categories(map, ecosystem_type) %>%
  count(ecosystem_type, name = "n") %>%
  arrange(n) %>%
  mutate(ecosystem_type = fct_inorder(ecosystem_type))

panel_d <- ggplot(environment_counts, aes(x = n, y = ecosystem_type, fill = ecosystem_type)) +
  geom_col(width = 0.62) +
  geom_text(
    aes(label = n),
    hjust = -0.35,
    size = base_size / .pt * 0.95,
    colour = colours["ink"]
  ) +
  scale_fill_manual(
    values = c(
      "Marine" = unname(colours["navy"]),
      "Terrestrial" = unname(colours["moss"]),
      "Freshwater" = unname(colours["teal"]),
      "Urban" = unname(colours["coral"])
    ),
    guide = "none"
  ) +
  scale_x_continuous(limits = c(0, n_syntheses), expand = expansion(mult = c(0, 0.02))) +
  scale_y_discrete(expand = expansion(add = 0.5)) +
  labs(tag = "D", title = "ENVIRONMENTAL SCOPE", x = NULL, y = NULL) +
  theme_map() +
  theme(
    axis.text.x = element_blank(),
    plot.title = element_text(
      face = "bold", size = base_size + 1, colour = colours["ink"],
      margin = margin(b = 4)
    )
  )

# ---- Panel E: coverage breadth ----------------------------------------------

breadth_of <- function(long_data, variable, label) {
  long_data %>%
    count(study_id, name = "categories") %>%
    summarise(
      Multiple = sum(categories > 1),
      Single = sum(categories == 1),
      assignments = sum(categories)
    ) %>%
    mutate(dimension = label, mean_categories = assignments / n_syntheses)
}

breadth <- bind_rows(
  breadth_of(noise_long, noise_source, "Noise sources"),
  breadth_of(outcome_long, outcome_category, "Outcomes"),
  breadth_of(split_categories(map, ecosystem_type), ecosystem_type, "Environments"),
  breadth_of(taxonomic_membership, group, "Taxon groups")
) %>%
  mutate(dimension = fct_inorder(dimension) %>% fct_rev())

breadth_long <- breadth %>%
  pivot_longer(c(Multiple, Single), names_to = "breadth", values_to = "n") %>%
  mutate(breadth = factor(breadth, levels = c("Multiple", "Single")))

panel_e <- ggplot(breadth_long, aes(x = n, y = dimension, fill = breadth)) +
  geom_col(width = 0.6, position = position_stack(reverse = TRUE)) +
  geom_text(
    aes(label = n, colour = breadth),
    position = position_stack(vjust = 0.5, reverse = TRUE),
    size = base_size / .pt * 0.88
  ) +
  scale_fill_manual(
    values = c(
      "Multiple" = unname(colours["ink"]),
      "Single" = unname(colours["pale_navy"])
    ),
    labels = c("Multiple" = "Multiple categories", "Single" = "Single"),
    name = NULL
  ) +
  scale_colour_manual(
    values = c("Multiple" = "#FFFFFF", "Single" = unname(colours["muted_ink"])),
    guide = "none"
  ) +
  scale_x_continuous(
    limits = c(0, n_syntheses),
    expand = expansion(mult = c(0, 0.02))
  ) +
  labs(tag = "E", title = "COVERAGE BREADTH", x = NULL, y = NULL) +
  theme_map() +
  theme(
    axis.text.x = element_blank(),
    legend.position = c(0.01, 1.10),
    legend.justification = c(0, 1),
    legend.direction = "horizontal",
    legend.key.size = unit(11, "pt"),
    plot.title = element_text(
      face = "bold", size = base_size + 1, colour = colours["ink"],
      margin = margin(b = 20)
    )
  )

# ---- Assemble ---------------------------------------------------------------

# The right-hand panels are nested as their own patchwork. Laying C, D and E out
# in the same grid as B would make patchwork align their plot areas to B's, and
# B's panel starts low because of its rotated column labels — which pushed the
# C bars far below their title.
right_column <- wrap_plots(
  panel_c, panel_d, panel_e,
  ncol = 1,
  heights = c(0.80, 1.00, 1.00)
) +
  plot_annotation(
    theme = theme(
      plot.background = element_rect(fill = colours["paper"], colour = NA),
      plot.margin = margin(0, 0, 0, 0)
    )
  )

# wrap_elements() seals the right column into a single grob. Without it patchwork
# aligns C's plot area to B's, and B's panel starts low because of its rotated
# column labels — which dropped the C bars well below their own title.
body <- wrap_plots(
  panel_b,
  wrap_elements(full = right_column),
  nrow = 1,
  widths = c(4, 3)
)

figure_1 <- wrap_plots(panel_a, body, ncol = 1, heights = c(0.85, 3.15)) +
  plot_annotation(
    theme = theme(
      plot.background = element_rect(fill = colours["paper"], colour = NA),
      plot.margin = margin(10, 10, 10, 10)
    )
  )

figure_1

# Preserve the minimum 12-point typography by exporting at the dimensions below.
ggsave(
  here("Figures", "raw", "Figure_1_systematic_map_evidence_matrix.pdf"),
  figure_1,
  width = 14,
  height = 11,
  units = "in"
)

ggsave(
  here("Figures", "raw", "Figure_1_systematic_map_evidence_matrix.png"),
  figure_1,
  width = 14,
  height = 11,
  units = "in",
  dpi = 300
)
