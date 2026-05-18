---
name: article-latex-debug-workflow
description: >-
  Requires compile-and-log evidence before claiming LaTeX fixes for manuscript or
  slides in Article-CDP.
---

# LaTeX debug workflow

## Role

Do not report TeX issues as solved without compile evidence and log inspection.

## Steps

1. For slides, run `./compile-apresentacoes.sh` and inspect the resulting log output.
2. For manuscript edits, run an explicit LaTeX build flow for `main.tex` (for example `pdflatex`/`bibtex` cycles) and inspect logs.
3. After reference-related changes, ensure bibliography resolution is complete and warnings are understood.
4. If unresolved warnings remain, report them clearly instead of masking uncertainty.

## Anti-pattern

Editing TeX blindly without validating build behaviour and logs.
