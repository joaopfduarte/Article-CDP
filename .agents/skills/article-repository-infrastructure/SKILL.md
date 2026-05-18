---
name: article-repository-infrastructure
description: >-
  Keeps the Article-CDP repository buildable and internally consistent across
  manuscript, slides, benchmark scripts, generated macros, and asset references.
---

# Repository infrastructure

## Role

Maintain structural and build coherence for this article repository.

## Checklist

1. Keep manuscript entry points coherent: `main.tex`, `structure/preamble.tex`, `content/*.tex`.
2. Keep slide workflow coherent: `compile-apresentacoes.sh`, `apresentacoes/main.tex`, `apresentacoes/sections/*.tex`.
3. Preserve generated artefact contract for benchmark metrics:
   - input scripts/data under `content/assets/scripts/` and `content/assets/data/`
   - generated output in `content/assets/generated/benchmark_macros.tex`
4. Avoid introducing references to non-existent legacy paths.
5. Respect `.gitignore` and avoid versioning transient build output.
