#!/usr/bin/env bash
# Build the Article-CDP manuscript (default) or slides.
# Usage: ./compile.sh [artigo|apresentacoes]
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
TARGET="${1:-artigo}"

regenerate_benchmark_macros() {
  mkdir -p "$ROOT/content/assets/generated"
  python3 "$ROOT/content/assets/scripts/compute_paper_metrics.py" \
    --check-consistency \
    --write-macros "$ROOT/content/assets/generated/benchmark_macros.tex"
}

compile_artigo() {
  regenerate_benchmark_macros
  cd "$ROOT"

  rm -f main.aux main.out main.log main.bbl main.blg main.fls main.fdb_latexmk \
    main.synctex.gz texput.log texput.pdf

  texcount -1 -sum -inc main.tex > wordcount.txt 2>/dev/null || true

  pdflatex -interaction=nonstopmode main.tex
  bibtex main
  pdflatex -interaction=nonstopmode main.tex
  pdflatex -interaction=nonstopmode main.tex
}

compile_apresentacoes() {
  exec "$ROOT/compile-apresentacoes.sh"
}

case "$TARGET" in
  artigo|article|manuscript|"")
    compile_artigo
    ;;
  apresentacoes|apresentacao|slides)
    compile_apresentacoes
    ;;
  -h|--help|help)
    cat <<'EOF'
Usage: ./compile.sh [TARGET]

Targets:
  artigo         Build main.tex (default)
  apresentacoes  Build slides via compile-apresentacoes.sh
EOF
    ;;
  *)
    echo "Unknown target: $TARGET" >&2
    echo "Run ./compile.sh --help for usage." >&2
    exit 1
    ;;
esac
