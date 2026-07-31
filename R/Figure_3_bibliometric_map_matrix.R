# Figure 3: bibliometric geography of the included syntheses
# Standalone, reproducible R script.
#
# Panel A  world map of first-author countries (Equal Earth projection)
# Panel B  country x country co-authorship matrix (all countries, unpooled)
#
# Country handling: UK constituent countries (England, Scotland, Wales,
# Northern Ireland) are collapsed to "United Kingdom" in BOTH panels so the two
# panels count the same way.

library(tidyverse)
library(here)
library(sf)
library(rnaturalearth)
library(patchwork)

# Panel B's co-authorship network comes from bibliometrix, matching the original
# Overview_figures.Rmd analysis. Set to FALSE to derive the same network directly
# from the Scopus affiliation strings instead (see build_edges_direct() below).
# Both routes return the same countries and country pairs.
USE_BIBLIOMETRIX <- TRUE

biblio <- read_csv(here("Data", "Dataset2_bibliometric_data.csv"), show_col_types = FALSE)

colours <- c(
  ink = "#243746",
  muted_ink = "#52636F",
  paper = "#FBFAF8",
  land = "#E3E6E4",
  border = "#FBFAF8",
  graticule = "#DBE2E6",
  pale_tile = "#EDF2F5",
  empty_tile = "#F5F3F0"
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

# Compact names for the matrix axes only; the map keeps full names for joining.
display_label <- function(x) {
  recode(
    x,
    "United States" = "USA",
    "United Kingdom" = "UK",
    "Trinidad and Tobago" = "Trinidad & Tob.",
    .default = x
  )
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
ne_lookup <- c("United States of America" = "United States")

world_first <- world %>%
  mutate(match_name = recode(admin, !!!ne_lookup)) %>%
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

# ---- Panel B: co-authorship matrix ------------------------------------------

# Every country credited on a record, one row per record x country.
record_countries <- biblio %>%
  mutate(record = row_number()) %>%
  select(record, affiliations) %>%
  separate_rows(affiliations, sep = ";") %>%
  filter(str_trim(affiliations) != "") %>%
  mutate(country = country_of(affiliations)) %>%
  distinct(record, country)

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

edges <- if (USE_BIBLIOMETRIX) build_edges_bibliometrix() else build_edges_direct()

# Every country is shown separately: a matrix has room for the long tail that
# the ring did not, so nothing is hidden behind an "Other" group.
#
# Rows and columns are ordered by CONNECTIVITY (number of distinct partner
# countries) rather than by record count. Ordering by records buries countries
# that appear on a single but heavily multinational paper.
country_stats <- bind_rows(
  edges %>% select(country = country.x, partner = country.y, n),
  edges %>% select(country = country.y, partner = country.x, n)
) %>%
  summarise(partners = n_distinct(partner), strength = sum(n), .by = country)

country_levels <- records_per_country %>%
  left_join(country_stats, by = "country") %>%
  mutate(across(c(partners, strength), ~ replace_na(.x, 0))) %>%
  arrange(desc(partners), desc(strength), desc(n_records), country) %>%
  mutate(label = paste0(display_label(country), " (", partners, ")"))

lev <- country_levels$country
axis_labels <- setNames(country_levels$label, country_levels$country)

# Strict lower triangle: each unordered pair appears exactly once.
matrix_cells <- expand_grid(row = lev, col = lev) %>%
  left_join(edges %>% rename(row = country.x, col = country.y), by = c("row", "col")) %>%
  left_join(edges %>% rename(row = country.y, col = country.x), by = c("row", "col"),
            suffix = c("", ".swap")) %>%
  mutate(n = coalesce(n, n.swap)) %>%
  select(row, col, n) %>%
  filter(match(row, lev) > match(col, lev)) %>%
  mutate(
    n = replace_na(n, 0),
    row = factor(row, levels = lev),
    col = factor(col, levels = lev)
  )

# The first row and last column of a strict lower triangle are always empty, so
# drop them: 24 x 24 instead of 25 x 25, and no orphan axis labels.
row_levels <- lev[-1]
col_levels <- lev[-length(lev)]
matrix_cells <- matrix_cells %>%
  mutate(
    row = factor(as.character(row), levels = row_levels),
    col = factor(as.character(col), levels = col_levels)
  )

max_pair <- max(matrix_cells$n)

panel_b <- ggplot(matrix_cells, aes(x = col, y = fct_rev(row))) +
  geom_tile(
    aes(fill = if_else(n > 0, n, NA_real_)),
    colour = colours["paper"],
    linewidth = 0.9
  ) +
  geom_text(
    data = filter(matrix_cells, n > 0),
    aes(label = n, colour = if_else(n >= 4, "light", "dark")),
    size = base_size / .pt * 0.62
  ) +
  scale_colour_manual(
    values = c(light = "#FFFFFF", dark = unname(colours["ink"])),
    guide = "none"
  ) +
  scale_fill_gradient(
    low = colours["pale_tile"],
    high = colours["ink"],
    na.value = colours["empty_tile"],
    limits = c(1, max_pair),
    breaks = seq(1, max_pair, by = 2),
    # Shading is a reading aid only; the exact count is printed in every cell,
    # so no colour legend is needed.
    guide = "none"
  ) +
  scale_x_discrete(labels = axis_labels, drop = FALSE) +
  scale_y_discrete(labels = axis_labels, drop = FALSE) +
  coord_fixed(clip = "off") +
  labs(tag = "B", x = NULL, y = NULL) +
  theme_minimal(base_size = base_size) +
  theme(
    plot.background = element_rect(fill = colours["paper"], colour = NA),
    panel.grid = element_blank(),
    axis.text.x = element_text(angle = 45, hjust = 1, vjust = 1,
                               size = base_size - 3.5, colour = colours["ink"]),
    axis.text.y = element_text(size = base_size - 3.5, colour = colours["ink"]),
    axis.ticks = element_blank(),
    plot.tag = element_text(face = "bold", size = base_size + 6, colour = colours["ink"]),
    plot.tag.position = c(0, 1),
    legend.position = "none",
    plot.margin = margin(0, 8, 4, 8)
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
  here("Figures", "raw", "Figure_3_bibliometric_map_matrix.pdf"),
  figure_3, width = 9, height = 12, units = "in"
)

ggsave(
  here("Figures", "raw", "Figure_3_bibliometric_map_matrix.png"),
  figure_3, width = 9, height = 12, units = "in", dpi = 300
)

# ---- Numbers for the caption ------------------------------------------------

n_pairs_possible <- choose(length(lev), 2)
n_pairs_observed <- sum(matrix_cells$n > 0)

message(
  "network source: ", if (USE_BIBLIOMETRIX) "bibliometrix" else "direct",
  " | records: ", n_records,
  " | countries: ", length(lev),
  " | collaborating pairs: ", n_pairs_observed, " of ", n_pairs_possible,
  " (", round(100 * n_pairs_observed / n_pairs_possible), "%)"
)

message("strongest pairs: ",
        edges %>%
          arrange(desc(n)) %>%
          head(5) %>%
          mutate(l = paste0(display_label(country.x), "-", display_label(country.y),
                            " ", n)) %>%
          pull(l) %>%
          paste(collapse = ", "))
