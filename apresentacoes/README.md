# Apresentações (Beamer)

Slides em **português (pt-BR)** para apresentação do **artigo** sobre *Infrastructure-as-Code* para *Data Lake* Hadoop no **Oracle Cloud Infrastructure Free Tier** (ARM), alinhados ao manuscrito na raiz do repositório (`main.tex` + `content/`).

## Estrutura

- **CWD de compilação** = esta pasta: `main.tex` + fragmentos em `sections/`.
- Tema **`cefetmg`** (`beamerthemecefetmg.sty`): cores, tipografia, capa sem logomarca (só texto institucional).
- Figuras reutilizadas do artigo via `\graphicspath{{../content/assets/}}` (PDFs em `../content/assets/`).

## Compilação

Na raiz do repositório:

```bash
./compile-apresentacoes.sh
```

Saída: `apresentacoes/main.pdf`.

## Notas

- Código nos slides: `listings` (sem `minted`, para não exigir `-shell-escape`).
- Na capa, a linha de **coorientador** só aparece se `\coorientadorlinha{...}` for definida no `main.tex`.
