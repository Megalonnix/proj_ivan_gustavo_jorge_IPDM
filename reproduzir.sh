#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
for script in estrutura/codigos/[0-9]*.R; do
  echo "Executando $script"
  Rscript "$script"
done
(cd entregas/entrega-1 && Rscript entrega-1-pergunta.R)
