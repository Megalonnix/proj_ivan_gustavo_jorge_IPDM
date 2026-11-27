#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
for script in estrutura/codigos/[0-9]*.R; do
  echo "Executando $script"
  Rscript "$script"
done
(cd entregas/entrega-1-parcial && Rscript entrega-1-pergunta.R)
Rscript entregas/entrega-2-final/artigo-final/entrega-2-banco.R
