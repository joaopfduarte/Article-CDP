#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
AP="$ROOT/apresentacoes"
cd "$AP"

rm -f main.aux main.nav main.snm main.toc main.out main.log main.pdf main.vrb main.lof main.lot texput.log texput.pdf

texcount -1 -sum -inc main.tex > wordcount.txt 2>/dev/null || true

pdflatex -interaction=nonstopmode main.tex
pdflatex -interaction=nonstopmode main.tex
