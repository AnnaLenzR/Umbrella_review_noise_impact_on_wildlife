# **A systematic map of systematic reviews on anthropogenic noise impacts on wildlife: evidence gaps, policy attention, and quality appraisal**

Anna Lenz1*, Ayumi Mizuno1, Erick Lundgren1, Kyle Morrison2, Santiago Ortega1, Malgorzata Lagisz 1, 2#, Shinichi Nakagawa 1, 2# </br>


1 Collaboration for Open Science and Synthesis in Ecology and Evolution (COSSEE), Department of Biological Sciences, University of Alberta, 11455 Saskatchewan Dr NW, Edmonton, Alberta, T6G 2E9, Canada  </br>
2 Evolution & Ecology Research Centre and the School of Biological, Earth and Environmental Sciences at the University of New South Wales, Sydney 2052, NSW, Australia </br>


#Senior authors: Malgorzata Lagisz - Email: losialagisz@gmail.com and Shinichi Nakagawa - Email: snakagaw@ualberta.ca  </br>

*Corresponding author: Anna Lenz </br>

---

## **Overview**
This repository contains the data, code, and figures supporting the paper: </br>

Lenz A., Mizuno A., Lundgren E., Morrison K., Ortega S., Lagisz M., & Nakagawa S. (2025). A systematic map of systematic reviews on anthropogenic noise impacts on wildlife: evidence gaps, policy attention, and quality appraisal [Preprint]. EcoEvoRxiv. https://doi.org/10.32942/X2435S </br>

The project systematically maps almost two decades of secondary syntheses (systematic reviews, maps, and meta-analyses) addressing the effects of anthropogenic noise on wildlife. It evaluates the methodological quality of these syntheses, examines their bibliometric patterns, and quantifies their influence in policy documents.


---

## **Abstract**
As systematic reviews on the effects of anthropogenic noise on wildlife increasingly inform policy, a critical evaluation of this secondary evidence is essential. We assessed the scope, quality, and policy relevance of existing syntheses in this field. Following a preregistered protocol, we conducted a systematic search in Scopus, Web of Science, and Google Scholar, identifying 50 syntheses (systematic reviews, maps, and meta-analyses). Of these syntheses, we included 47 in the bibliometric analysis, 23 in the policy attention analysis, and 44 in the critical appraisal. Syntheses were published between 2008 and 2025, focusing on behavioural, physiological, and communication outcomes in wildlife. Most examined transportation and energy-related noise and reviewed evidence from marine, followed by terrestrial ecosystems. We found critical gaps in taxonomic coverage, with notable underrepresentation of invertebrates, amphibians, and reptiles. Most syntheses were led by researchers from the United Kingdom, Canada, and the United States, with limited participation from non-English-speaking countries. Almost half were cited in policy documents, mainly government and regulatory submissions. Syntheses on marine environments received the most policy citations, while those on urban noise received the least. There was no significant difference in quality scores between policy-cited and non-cited syntheses, and most were rated low due to methodological and reporting shortcomings. Our findings highlight the need to fill synthesis gaps and improve methodological transparency to strengthen the evidence base for policy decisions on anthropogenic noise. </br>

Keywords: Bibliometric analysis; Umbrella review; CEESAT appraisal; Soundscape ecology; Environmental stressors; Conservation policy; Biodiversity management

---

## **Repository Structure**

<pre><code>
├── Umbrella_review_noise.Rproj     # R project file
├── LICENSE                         # MIT License
├── R/                              # Annotated R scripts for analyses and figures
│   └── umbrella_review_main.R      # Main script producing all figures and analyses
│
├── Data/                           # Final cleaned datasets used in analyses
│   ├── Dataset1_map_data_extraction.csv
│   ├── Dataset2_bibliometric_data.csv
│   ├── Dataset3_policy_data_extraction.csv
│   ├── Dataset3.1_policy_citation_counts_PlumX.csv
│   ├── Dataset4_cessat_assessments.csv
│   ├── Dataset5_cessat_processed.csv
│   └── bibliometric.bib            # Dataset2_bibliometric_data in .bib format
│
├── Metadata/                       # Codebooks describing each dataset
│   ├── Dataset1_map_data_extraction.csv
│   ├── Dataset2_bibliometric_data.csv
│   ├── Dataset3_policy_data_extraction.csv
│   ├── Dataset3.1_policy_citation_counts_PlumX.csv
│   ├── Dataset4_cessat_assessments.csv
│   └── Dataset5_cessat_assessments.csv
│
├── Figures/                        # Final publication figures (PNG)
│   ├── Figure_1_Review_characteristics_and_content_mapping.png
│   ├── Figure_2_taxonomic_scope.png
│   ├── Figure_3_authors_affiliation_collaboration.png
│   ├── Figure_4_scope_policy_documents_citing_syntheses.png
│   └── Figure_5_CEESAT_assessment_syntheses.png
</code></pre>

---

## **Datasets**

| File                                                      | Description                                                                                                                                                   |
| --------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Dataset1_map_data_extraction.csv**                      | Main dataset for the systematic map. Includes metadata and classification of 50 included syntheses by study type, taxa, outcomes, and noise source.           |
| **Dataset2_bibliometric_data.csv** / **bibliometric.bib** | Bibliometric information for all syntheses (authors, affiliations, journal, citation counts). The `.bib` version is the same document for analysis in R.      |
| **Dataset3_policy_data_extraction.csv**                   | Records of policy citations, including document type, level, country, and ecological context.                                                                 |
| **Dataset3.1_policy_citation_counts_PlumX.csv**           | Extracted policy citation counts and attention metrics from PlumX.                                                                                            |
| **Dataset4_cessat_assessments.csv**                       | Raw CEESAT 2.1 appraisal scores for each synthesis.                                                                                                           |
| **Dataset5_cessat_processed.csv**                         | Cleaned CEESAT dataset used in visualizations and statistical summaries.                                                                                      |

---

## **Reproducibility**

**Requirements:**
- R (≥ 4.3.0) </br>
- RStudio (Posit, ≥ 2024.12)

**Core Packages:**
tidyverse, ggplot2, patchwork, paletteer, treemapify, circlize, ComplexUpset, rphylopic, ggthemes, readxl, here, dplyr, stringr, bibliometrix, RColorBrewer, rnaturalearth, rnaturalearthdata

**To reproduce Figures and Analyses**
1. Clone this repository </br>
    <pre><code>
   git clone https://github.com/AnnaLenzR/Umbrella_review_noise.git
   cd Umbrella_review_noise </br>
    </code></pre>
2. Open Umbrella_review_noise.Rproj in RStudio. </br>
3. Run the main analysis script:

   source("R/umbrella_review_main.R")

4. The script will generate the six main figures and supplementary figures in the /Figures directory.

---

## **Script Outline**

- The main R script is organized by figure sections and analysis:
- Load packages and data </br>
**Figures:**
- Figure 1: Systematic map—quantitative and qualitative trends
- Figure 2: Taxonomic groups— treemap
- Figure 3: Annual trends in outcomes, noise sources, and environments
- Figure 4: Bibliometric maps and collaboration networks
- Figure 5: CEESAT scores: CEESAT question scores (all syntheses) </br>
**Statistical comparisons:**
- Analysis: Syntheses quality analysis— Cited vs not cited in policy </br>
**Supplementary figures:** </br>
- Keywords, citation counts, policy trends

---

## **Citation **
If you use **this repository** or its data, please cite: </br>

Lenz, A., Mizuno, A., Lundgren, E., Morrison, K., Ortega, S., Lagisz, M., & Nakagawa, S. (2025).
A systematic map of systematic reviews on anthropogenic noise impacts on wildlife: evidence gaps, policy attention, and quality appraisal.
University of Alberta. https://github.com/AnnaLenzR/Umbrella_review_noise

### Preprint and protocol

Find the **preprint** here: </br>
https://ecoevorxiv.org/repository/dashboard/10446/

The **protocol** is preregistered in OSF: </br>
https://osf.io/dmjc4/

---

## **Contact**

Corresponding author: </br>
Anna Lenz </br>
Collaboration for Open Science and Synthesis in Ecology and Evolution (COSSEE) </br>
University of Alberta, Edmonton, AB, Canada </br>
📧 lenzrive@ualberta.ca







