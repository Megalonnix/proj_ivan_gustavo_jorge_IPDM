# Projeto IPDM - Baixada Santista

- **Disciplina:** Teoria do Aprendizado Estatístico
- **Integrantes:** Ivan, Gustavo, Jorge
- **Fonte de dados:** Fundação Seade - IPDM (Índice Paulista de Desenvolvimento Municipal)
- **Recorte:** 9 municípios da Região Metropolitana da Baixada Santista, 6 anos (2014, 2016, 2018, 2020, 2022, 2024) - 54 observações

---

## ⚠️ AVISO — BRANCH EXPERIMENTAL ARQUIVADO

> **Este projeto foi conduzido como exercício experimental da disciplina.**
> O trabalho principal do grupo seguiu por outra trilha. Este repositório foi
> **arquivado em um branch secundário** por dois motivos:
>
> 1. **Preservar a memória do experimento.** Os resultados são modestos
>    (sinal fraco, amostra pequena, outlier dominante), mas a **organização
>    interna** — estrutura de diretórios, pipeline modular, convenções de
>    documentação, micro-relatórios embutidos nos `.R` — foi considerada
>    valiosa o suficiente para virar **alicerce de análises futuras**.
>
> 2. **Servir como referência de estrutura.** A forma como cada etapa foi
>    documentada (decisões explícitas, limitações declaradas, diagnósticos
>    numéricos para figuras, autocrítica retroativa) é o que se pretende
>    reaproveitar em projetos subsequentes — não o conteúdo substantivo.
>
> **Leitura recomendada:** este repositório não deve ser lido como "estudo
> sobre a Baixada Santista" e sim como **modelo de organização de projeto
> analítico reprodutível**.

---

## ☢️ **IMPORTANTE — LEIA ANTES DE EXECUTAR!**

> **Este projeto é multi-arquivo e usa caminhos relativos entre os módulos.**
> A execução **só funciona** se as duas regras abaixo forem seguidas à risca.

### ☢️ **Regra 1 — Clone ou baixe o repositório inteiro!**

**Não rode arquivos isolados.** O projeto depende da estrutura completa de pastas
(`estrutura/scriptsR/`, `estrutura/bancoDeDados/`, etc.).

**Via Git:**
```bash
git clone https://github.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM
```

---

## Resumo

Projeto de aprendizado estatístico focado em Regressão Linear e Logística aplicadas ao Índice Paulista de Desenvolvimento Municipal (IPDM). O pipeline cobre desde a análise exploratória até o ajuste de modelos (com e sem separação de treino/teste), protocolo de avaliação e seleção de modelos, e diagnóstico de viés-variância. O par central modelado é mortalidade 60–69 em função do PIB per capita na Baixada Santista.

---

## Estrutura do projeto

```text
proj_ivan_gustavo_jorge_(IPDM)/
├── README.md
├── consolidado/
│   ├── 0_analiseExploratoria.md
│   ├── 1_regressao_linear.md
│   ├── 2_regressao_logistica.md
│   ├── 3_regressao_linear_treino_teste.md
│   ├── 4_regressao_logistica_treino_teste.md
│   ├── 5_avaliacao_selecao_modelos.md
│   └── 6_relatorio_final.md
├── estrutura/
│   ├── bancoDeDados/
│   │   ├── 0_dicionario_ipdm_ORIGINAL.csv
│   │   ├── dados_ipdm.csv
│   │   └── df_ipdm_baixada_por_municipio.csv
│   ├── dicionario/
│   │   ├── dicionario_ipdm_baixada.pdf
│   │   └── dicionario_ipdm_baixada.tex
│   ├── notebooks/
│   └── scriptsR/
│       ├── 0_analiseExploratoria.R
│       ├── 1_regressao_linear.R
│       ├── 2_regressao_logistica.R
│       ├── 3_regressao_linear_treino_teste.R
│       ├── 4_regressao_logistica_treino_teste.R
│       ├── 5_avaliacao_selecao_modelos.R
│       └── figuras/
└── to.delete/
```

---

## Pipeline

| Módulo | Arquivo | O que faz |
|--------|---------|-----------|
| 0 | `0_analiseExploratoria.R` | Análise exploratória, tipagem de variáveis e construção do banco consolidado |
| 1 | `1_regressao_linear.R` | Regressão linear simples e múltipla; análise de sensibilidade ao outlier (Cubatão) |
| 2 | `2_regressao_logistica.R` | Regressão logística na amostra completa; três limiares de decisão (0,3 / 0,5 / 0,7) e AUC |
| 3 | `3_regressao_linear_treino_teste.R` | Regressão linear com split treino (70%) / teste (30%); RMSE, MAE e R² out-of-sample |
| 4 | `4_regressao_logistica_treino_teste.R` | Regressão logística com split, matriz de confusão, três limiares e curva ROC |
| 5 | `5_avaliacao_selecao_modelos.R` | Protocolo treino/validação/teste, viés-variância (curva do U) e seleção entre candidatos |

**Dependências entre módulos:**
Os scripts são autocontidos para execução dos modelos, mas assumem que os dados em `estrutura/bancoDeDados/` já estão íntegros e que a exploração inicial (`0_analiseExploratoria.R`) contextualiza as escolhas.

---

## Convenções de documentação

Este projeto adota três convenções internas que devem ser preservadas em
qualquer reuso da estrutura:

1. **Micro-relatório em cada `.R`.** Todo script termina com um bloco
   comentado contendo decisões metodológicas, leitura esperada dos
   resultados, limitações e amarração com os demais scripts. O bloco não é
   executado — serve para leitura humana e de LLM.

2. **Bloco `DIAGNÓSTICO VISUAL` antes de cada figura.** Antes de gerar uma
   imagem, o script imprime no console os números necessários para
   **descrevê-la sem vê-la** (faixas, amplitudes, correlações, posição de
   outliers). Isso permite auditoria e redação do consolidado sem acesso
   às imagens.

3. **Consolidado em `.md` com tabelas, não prosa.** Cada módulo tem um
   arquivo Markdown próprio em `consolidado/`, com seções numeradas,
   tabelas para qualquer valor numérico, e limitações declaradas no mesmo
   nível hierárquico das conclusões.

---

## Como explorar o projeto

1. **Clone o repositório** (instruções no topo deste README).

2. **Abra o R (ou RStudio)** e defina o diretório de trabalho como a **raiz do projeto** — a pasta que contém este `README.md`. 

   ```r
   setwd("caminho/para/proj_ivan_gustavo_jorge_(IPDM)")
   ```

3. **Navegue até `estrutura/scriptsR/`** e escolha um script para explorar.

4. Você pode utilizar o comando `source()` ou executar o script linha por linha para reproduzir as análises. Todos os gráficos gerados são salvos automaticamente na pasta `estrutura/scriptsR/figuras/`.

### Documentação detalhada

Cada modelo tem um relatório próprio em `consolidado/`, contendo objetivo, especificação técnica, interpretação dos resultados (em Markdown) e diagnósticos:

- [`0_analiseExploratoria.md`](consolidado/0_analiseExploratoria.md)
- [`1_regressao_linear.md`](consolidado/1_regressao_linear.md)
- [`2_regressao_logistica.md`](consolidado/2_regressao_logistica.md)
- [`3_regressao_linear_treino_teste.md`](consolidado/3_regressao_linear_treino_teste.md)
- [`4_regressao_logistica_treino_teste.md`](consolidado/4_regressao_logistica_treino_teste.md)
- [`5_avaliacao_selecao_modelos.md`](consolidado/5_avaliacao_selecao_modelos.md)
- [`6_relatorio_final.md`](consolidado/6_relatorio_final.md) — síntese reflexiva

Leia-os preferencialmente em ordem para entender o fluxo de modelagem, do ajuste simples às métricas de validação out-of-sample e ao protocolo de seleção.