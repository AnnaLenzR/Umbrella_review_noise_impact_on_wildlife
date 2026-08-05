# Final submission audit

Audit date: 31 July 2026

## Files examined

- `final_ms/Noise_SysMap_MS_200726_aligned.docx`
- `final_ms/Online_Resource1_200726_aligned.docx`
- `final_ms/Reviewers_Responses_200726_aligned.docx`
- `R/Overview_figures copy.Rmd`
- `R/Figure_1_systematic_map_evidence_matrix.R`
- `R/Figure_3_bibliometric_map_chord.R`
- all files in `Figures/`, `Data/`, and `Metadata/`
- `README.md`

These were the only three aligned DOCX files and the only exact `Overview_figures copy` file. The standalone Figure 1 and Figure 3 scripts were also the most recently modified matching implementations.

## Figure and table register

| Item | Intended number | Short description | Caption location | First in-text citation | Citation order | Source script/chunk | Output filename | Status |
|---|---:|---|---|---|---|---|---|---|
| Main figure | 1 | Systematic-map evidence matrix and coverage | Manuscript, p. 11, lines 223–232 | Manuscript, p. 10, Fig. 1A | Correct | Inline Figure 1 chunks in `Overview_figures copy.Rmd`; standalone script retained | `Figures/raw/Figure_1_systematic_map_evidence_matrix.{pdf,png}` | Present and embedded |
| Main figure | 2 | Taxonomic treemap | Manuscript, p. 13 | Manuscript, p. 13 | Correct | Overview Figure 2 section | existing embedded figure; `Figures/Figure_2_taxonomic_scope.png` | Present and cited |
| Main figure | 3 | First-author geography and country co-authorship chord diagram | Manuscript, p. 16 | Manuscript, p. 16 | Correct | Inline Figure 3 chunks in `Overview_figures copy.Rmd`; standalone script retained | `Figures/raw/Figure_3_bibliometric_map_chord.png` | Author-supplied PNG embedded; chord retained |
| Main figure | 4 | Policy-scope alluvial plot | Manuscript, p. 19 | Manuscript, p. 19 | Correct | Overview Figure 4 section | existing embedded figure | Present and cited |
| Main figure | 5 | CEESAT item scores | Manuscript, p. 21 | Manuscript, p. 21 | Correct | Overview Figure 5 section | `Figures/Figure_5_CEESAT_assessment_syntheses.png` | Existing PNG retained and cited |
| Supplementary figure | S1 | PRISMA flow diagram | Online Resource 1, p. 6 | Manuscript Methods | Correct | Embedded supplementary figure | embedded | Present |
| Supplementary figure | S2 | Eligibility decision tree | Online Resource 1, p. 7 | Manuscript Methods | Correct | Embedded supplementary figure | embedded | Present |
| Supplementary figure | S3 | Synthesis characteristics/content mapping | Online Resource 1, pp. 8–9 | Manuscript Results | Correct | Inline overview Figure S3 section, beginning under Supplementary figures | `Figures/raw/figure_s3.png` | Existing Online Resource figure retained and cited |
| Supplementary figure | S4 | Keyword analysis | Online Resource 1, p. 10 | Manuscript bibliometric results | Correct | Overview Figure S4 section | S4 output references | Present in DOCX |
| Supplementary figure | S5 | Academic citations | Online Resource 1, p. 11 | Manuscript bibliometric results | Correct | Overview Figure S5 section | S5 output references | Present in DOCX |
| Supplementary figure | S6 | Full policy alluvial plot | Online Resource 1, p. 12 | Manuscript policy results | Correct | Overview Figure S6 section | S6 output references | Present in DOCX |
| Supplementary figure | S7 | Policy citation counts | Online Resource 1, p. 13 | Manuscript policy results | Correct | Overview Figure S7 section | S7 output references | Existing embedded figure retained and cited |
| Supplementary figure | S8 | Policy-document annual trends | Online Resource 1, p. 14 | Manuscript policy results | Correct | Overview Figure S8 section | S8 output references | Existing embedded figure retained and cited |
| Supplementary figure | S9 | Annual trends, policy-cited vs non-cited syntheses | Online Resource 1, p. 15 | Manuscript policy results | Correct | Overview Figure S9 section | S9 output references | Existing embedded figure retained and cited |
| Supplementary figure | S10 | Policy geography | Online Resource 1, p. 16 | Manuscript policy results | Correct | Overview Figure S10 section | S10 output references | Existing embedded figure retained and cited |
| Supplementary figure | S11 | CEESAT comparison by policy citation | Online Resource 1, p. 17 | Manuscript critical appraisal | Correct | Overview Figure S11 section | S11 output references | Present in DOCX and correctly cited |
| Supplementary tables | S1–S10 | PECOS, criteria, benchmark, searches, exclusions, workflow, codebooks, variables, included syntheses | Online Resource 1, pp. 18–49 | Manuscript Methods/Results | Correct | Online Resource 1 | embedded tables | Present; no skipped or duplicated numbers |

## Corrections made

- Retained the author-approved Figure 3 chord diagram and its matching caption; the author-supplied PNG is embedded in the manuscript and stored as the Figure 3 PNG output.
- Corrected `Fig S3` to `Fig. S3` and one missing comma after `e.g.` in author prose.
- Corrected two grammar/duplication errors in the authors' response prose (`limitations, we identified`; `but but`). Reviewers' original comments were left verbatim.
- Corrected the response letter’s stale publication-year cross-reference from Fig. S3 to Fig. 1A.
- Confirmed that the manually reordered supplementary figures now follow their first-citation order in the manuscript and run continuously from Fig. S1 to Fig. S11 in Online Resource 1.
- Integrated the complete Figure 1 and chord-diagram Figure 3 implementations directly into named R Markdown chunks; no figure section now relies on a `source()` call.
- Placed Figure S3 at the start of the Supplementary figures section and restored Panel A to the intended `review_type` categories (systematic review, meta-analysis, and systematic map).
- Removed the obsolete Figure 3 map/chord blocks and placed the overall annual-trend diagnostics inside the Figure S10 section, separate from Figure S3.
- Updated the main-figure workflow numbering from 1–5 and reordered the supplementary workflow as S3 synthesis mapping, S4 keywords, S5 academic citations, S6 policy alluvial, S7 policy-citation counts, S8 policy trends, S9 cited/not-cited trends, S10 geography, and S11 CEESAT; matching object and output names follow the same sequence.
- Corrected the policy-figure range in the authors' response to Figures S6–S10. The associated reviewer comment was not edited.

## Count consistency results

- Systematic map: 50 unique `study_id` values in Dataset 1; manuscript and captions agree.
- CEESAT: 50 unique appraisals in Datasets 4 and 5; manuscript and captions agree.
- Bibliometric analysis: 47 rows in Dataset 2; manuscript, Online Resource 1, and Figure 3 agree.
- Policy attention: all 50 mapped syntheses have a yes/no policy field; 23 are marked yes. Dataset 3 contains 537 policy-document records across those 23 syntheses; manuscript and captions agree.
- Publication range: 2008–2025. Quantitative/narrative-descriptive split: 23/27. Peak years 2021, 2023, and 2024 each contain eight syntheses. These statements agree with Dataset 1.
- `Dataset_3.1_policy_citation_counts_PlumX.csv` contains 50 synthesis rows plus one summary row labelled `Total`; this explains its physical 51-row count and is not a conflict.

## British-English and typo audit

Author prose uses British forms including `behavioural`, `characterise`, `harmonised`, `summarising`, and `visualised`. No British-English spelling substitutions were required in this pass. Matches in published titles, reviewer comments, reference titles, or identifiers were not changed. The only direct prose corrections are listed above.

## Reviewer-response alignment and page/line locations

Quoted revisions were compared against a fresh render of the current manuscript with visible continuous line numbers. All stale page/line locations in the response letter were updated, including Methods passages on pages 5–9, Results passages on pages 9 and 14, and Discussion passages on pages 22–25. The Figure S3 caption location was confirmed as Online Resource 1, page 8. Supplementary-figure references in the response were aligned to the current numbering (PRISMA Fig. S1, decision tree Fig. S2, and policy figures S6–S10). Reviewers' original comments were left verbatim.

## R execution and generated outputs

- `R/Figure_1_systematic_map_evidence_matrix.R`: completed from `Rscript --vanilla`. Warning: the PDF device substituted a hyphen for the em dash in one plot title; the PNG rendered correctly.
- The Figure 3 workflow now uses `R/Figure_3_bibliometric_map_chord.R`. Its direct Scopus-affiliation route avoids the installed bibliometrix version's `bibtag` import failure while retaining the chord analysis.
- Figure 3 completed successfully in a redirected temporary-output test using only installed dependencies; the integrated implementation no longer requires `ggplotify`.
- `Overview_figures copy.Rmd` was extracted with `knitr::purl()` and parsed successfully. The Figure S3 Panel A chunk also ran separately and reproduced the intended `review_type` totals (28 systematic reviews, 19 meta-analyses, and 3 systematic maps).
- A prior full-workflow verification run unnecessarily regenerated Figure 5 and several supplementary outputs. Those extra generated files were removed; the existing author-approved PNGs and embedded figures were not replaced. The final validation used code extraction/parsing and targeted data checks instead of rerunning the complete output-writing workflow.

## Render and structural verification

- All three DOCX files were re-opened structurally and rendered: manuscript 42 pages, Online Resource 1 49 pages, responses 23 pages.
- Every rendered page was reviewed via contact sheets; edited pages were additionally inspected at full resolution.
- No clipping, overlap, shifted tables, missing figures, or corrupted captions were observed.
- The manuscript’s one existing Word comment was preserved. Two pre-existing tracked numeric location edits in the response letter were accepted locally after their old deleted digits remained visible in the render; no other content was affected. Line-number settings, field-code XML, relationships, styles, and embedded objects were preserved by targeted OOXML edits.

## Remaining author decisions

None identified in this correction pass. The README abstract and repository outline now reflect 50 appraisals, 47 bibliometric syntheses, 23 policy-cited syntheses, and the final five-main-figure workflow.

## Manual checks still recommended

- Open the three DOCX files once in the submission version of Microsoft Word and update fields only if the journal requires Word-native field refresh. LibreOffice preserved and displayed the continuous line numbers, but Word can paginate differently when fonts or printer metrics differ.
- Use the PNG figure files for submission, as confirmed by the author.
