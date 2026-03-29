# Editorial Revision Plan — IJCC Manuscript (v2)

## Overview

Full editorial revision of the manuscript for submission to the **International Journal of Cloud Computing (Inderscience)**.

Current word count: **~5985 words** (within the 5000–7000 target).  
Approach: **soft-delete** — all removals are done by commenting out, never by deleting content.

---

## Resolved Items ✅

| # | Item | Action Taken |
|---|------|-------------|
| 1 | Author names, affiliations, emails | Commented out in `main.tex` with restore instructions |
| 2 | `\tresumo` and `\bnote` commands | **Kept as-is** — debug-only, controlled by flag in `singlecol-new.cls` |
| 3 | Flexera 2025 reference | Added as standalone `@misc{flexera2025stateofcloud}` in `references.bib` |
| 4 | Portuguese-language access notes | Converted to English in `hadoop_hdfs_design_2025` and `oci_docs` entries |

---

## Remaining Issues

### Structural & Framing
1. **Title overclaims "Secure and Scalable"** — security is not experimentally validated; scalability is not tested beyond 4 fixed nodes. Propose a more precise title.
2. **No explicit research questions or contributions list** in the Introduction.
3. **Section 2 ("Theoretical Reference") is purely definitional** — needs conversion to critical Related Work with gap analysis and comparison to prior work.
4. **Sections 3 and 4 overlap** — technology stack described twice. Recommend merging into a single *System Design and Methodology* section.

### Compliance
5. **Referencing style is numeric** — Inderscience requires Harvard (author-date). Requires `natbib` option change.
6. **"Cefet-MG Data Platform (CDP)"** in Section 3 — institutional name partially violates double-blind. Propose anonymising to "the proposed Data Platform" or similar.
7. **In-text Flexera citation** currently points to `deochake2026` — must be updated to cite `flexera2025stateofcloud` directly (or both, if Deochake is the intermediary source).
8. **Keywords use semicolons** — Inderscience typically uses commas.
9. **Only 12 references** — thin for a journal paper; mark gaps with `[TODO: add citation]` where appropriate.

### Technical Accuracy
10. **Queries 01 and 03 are identical SQL** — copy-paste error?
11. **No statistical reporting** despite 10 iterations per query — no means, SD, CI.
12. **SSB scale factor not stated** — essential for reproducibility.
13. **Apache Atlas** mentioned in architecture description but absent from all profile tables and only reappears as future work — inconsistency.
14. **Abstract/Conclusion claim NiFi+Kafka pipeline** but benchmark uses Data Science profile which excludes them.
15. **Data Science and Software Engineering profile tables** are commented out — should they be included?

### Prose Quality
16. AI-artefact phrases to remove: "leverages", "comprehensive", "it is important to note", "in this context", "encompasses the full spectrum", "robust".
17. Overly long sentences, especially in Sections 2 and 4.

---

## Revised Execution Plan

All edits use **soft-delete**: original text is commented out (LaTeX `%`), never removed.

| Batch | Sections | Key Focus | Estimated Changes |
|-------|----------|-----------|-------------------|
| **1** | Title, Abstract, Keywords, Introduction | Reframe title; tighten abstract to <150 words; add RQs and contribution list; fix Flexera citation; humanise prose | Medium |
| **2** | Related Work (current Sec 2) | Convert textbook definitions → critical review; add gap analysis; trim tutorial-style excess; mark missing citations | Heavy |
| **3** | System Design (merge Secs 3–4) | Merge into one section; remove duplication; fix profile inconsistencies; anonymise "CDP/CEFET-MG" | Heavy |
| **4** | Experimental Evaluation + Conclusion (Secs 5–6) | Fix methodology gaps; flag query duplication; flag missing stats; align conclusion claims with evidence | Medium |
| **5** | References + full compliance audit | Fix all bib entries; Blocks B–D summary for whole paper; final compliance checklist | Light |

---

## User Review Required

> [!IMPORTANT]
> **Referencing style**: Inderscience requires Harvard (author-date). Current setup uses numeric `[1]`. Switching requires changing `natbib` options from `[numbers,sort&compress]` to `[authoryear]` and the bibliography style. This affects every in-text citation rendering. **Approve this change?**

> [!IMPORTANT]
> **Section restructuring**: I recommend merging Sections 3 ("Technology Patterns") and 4 ("Architecture Design") into a single section. Section 3's content (hardware specs, software stack list) is repeated more thoroughly in Section 4. The merge would eliminate ~400 words of duplication and strengthen the narrative. **Approve?**

> [!WARNING]
> **Anonymisation of "CDP"**: The acronym "Cefet-MG Data Platform (CDP)" in Section 3 identifies the institution. For double-blind, I propose replacing with "the proposed Data Platform" or a generic acronym. The name can be restored for camera-ready. **Approve?**

## Open Questions (Author Validation Required)

1. **SSB scale factor**: What scale factor was used? (SF=1? SF=10? SF=100?)
2. **Query 01 vs Query 03**: Identical SQL — copy-paste error or intentional?
3. **Apache Atlas**: Was it actually deployed? It appears in the architecture figure description but not in any installation profile table and resurfaces only as future work.
4. **Profile tables**: Should the commented-out Data Science and Software Engineering tables be included?
5. **Run protocol**: Were there warm-up runs? Was the first iteration discarded?

## Verification Plan

### After Each Batch
- Compile with `bash compile.sh` to verify no broken references.
- Run `texcount main.tex` to verify word count stays within 5000–7000.

### After All Batches
- Full compliance checklist (Block D) in the final audit batch.
- Authors validate all Block C items.
