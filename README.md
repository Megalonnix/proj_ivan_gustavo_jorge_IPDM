# Teoria do Aprendizado Estatístico — Projeto IPDM (Baixada Santista)

**Ciência de Dados · Fatec Rubens Lara - Baixada Santista**

Estimar e avaliar modelos de aprendizado estatístico sobre a mortalidade de 60 a 69 anos
nos nove municípios da Região Metropolitana da Baixada Santista (IPDM / Fundação SEADE,
2014–2024) — da análise exploratória à validação cruzada, regularização, suavização,
árvores e agrupamento — com implementação em **R**.

![R](https://img.shields.io/badge/R-base-276DC3?style=flat&logo=r&logoColor=white)
![Status](https://img.shields.io/badge/status-concluído-success)
![Equipe](https://img.shields.io/badge/equipe-Ivan%20·%20Gustavo%20·%20Jorge-0B3954)
![Banco](https://img.shields.io/badge/banco-IPDM%20%2F%20SEADE-lightgrey)

---

## Entrega final (pacote)

| Peça | Arquivo |
|---|---|
| Artigo final (8 p., MQO + comparação controlada) | [`entregas/entrega-2-final/artigo-final/artigo-final.pdf`](entregas/entrega-2-final/artigo-final/artigo-final.pdf) |
| Apresentação final (15 slides) | [`entregas/entrega-2-final/apresentacao-final/apresentacao.pdf`](entregas/entrega-2-final/apresentacao-final/apresentacao.pdf) |
| Entrega 1 (parcial) | [`entregas/entrega-1-parcial/entrega-1-pergunta.pdf`](entregas/entrega-1-parcial/entrega-1-pergunta.pdf) |

**Pergunta do projeto:** quanto a mortalidade de 60 a 69 anos na Baixada Santista depende de onde (município) e de quando (ano)?

| Item | Valor |
|---|---|
| Recorte | 9 municípios da Baixada Santista, 6 edições bienais (2014–2024), painel equilibrado |
| n | 54 observações município–ano (38 treino / 16 teste reservado na Entrega 2) |
| Entrega 1 | `lm` (`municipio + ano`) RMSE CV(5) **2,20** vs média **3,84** (MAE 1,71 vs 2,97) |
| Entrega 2 | MQO (`municipio + ano`) RMSE **2,38** (CV5 no treino, vs média **3,40**) e **2,51** no teste reservado (vs média **5,15**) |
| Comparação controlada (CV5 treino) | média 3,40 → árvore podada 3,17 → floresta aleatória 2,70 → bagging 2,62 → **MQO 2,38** |

Artigo e apresentação contam a mesma história: recorte do IPDM na Baixada Santista, exclusão de `longevidade` e `ipdm` para evitar vazamento de informação, contraste regional e temporal, comparação controlada entre métodos da disciplina e escolha do MQO aditivo como modelo final.

---

## Sobre a disciplina

**Objetivo:**  
Utilizar conhecimentos estatísticos para análise e projeto de algoritmos de aprendizado de máquina para modelar, compreender e analisar conjuntos de dados complexos. Escrever esses algoritmos em pseudocódigo e executá-los por meio de linguagens de programação. Utilizar os conhecimentos adquiridos em problemas de Ciência de Dados para fundamentar a tomada de decisões baseadas em informações obtidas por meio de algoritmos de aprendizado de máquina.

**Ementa:**  
Teoria da aprendizagem estatística. Métodos de reamostragem. Expansão e regularização. Métodos de suavização. Método EM (Expectation-Maximization). Avaliação e seleção de modelos. Árvores de decisão. Redes neurais e aprendizado de máquina (redes Adaline, Madaline, Perceptron e Multilayer Perceptron - MLP). Máquina de vetores suporte. Agrupamentos. Componentes principais e independentes. Aplicação desses conhecimentos para solução dos problemas de Ciência de Dados, utilizando linguagem de programação.

**Professor:**  
Prof. Dr. João Paulo Ferreira de Mello  
([joao.mello12@fatec.sp.gov.br](mailto:joao.mello12@fatec.sp.gov.br))

**Equipe:** Ivan, Gustavo e Jorge

**Alunos:**  
Ivan Guimarães dos Santos da Silva — RA `0051352421038`  
Gustavo Nascimento Geminiano — RA `0051352511009`  
Jorge Sugano Suzart — RA `0051352511005`

**Linguagem das entregas:**  
Sempre **R base** (com pacotes específicos do laboratório apenas nas aulas de regularização, GAM e árvores/florestas: `glmnet`, `mgcv`, `rpart`, `randomForest`, `cluster`, `knitr`).

**Banco de trabalho:**  
O recorte do Índice Paulista de Desenvolvimento Municipal (IPDM / Fundação SEADE) está em [`estrutura/bancoDeDados/`](estrutura/bancoDeDados/): base estadual paulista ([`dados_ipdm.csv`](estrutura/bancoDeDados/dados_ipdm.csv)), dicionário original ([`0_dicionario_ipdm_ORIGINAL.csv`](estrutura/bancoDeDados/0_dicionario_ipdm_ORIGINAL.csv)) e o painel da Baixada Santista ([`df_ipdm_baixada_por_municipio.csv`](estrutura/bancoDeDados/df_ipdm_baixada_por_municipio.csv), $n = 54$, sem valores ausentes). As dimensões `longevidade` e `ipdm` são excluídas da modelagem supervisionada por incorporarem a própria taxa de mortalidade em seu cálculo (evitando *data leakage*).

---

## Cinco blocos do curso

| Bloco | Conteúdo                                          |
| ----- | ------------------------------------------------- |
| I     | Fundamentos do aprendizado estatístico            |
| II    | Supervisionado: avaliação e regularização         |
| III   | Modelos flexíveis: suavização, árvores, ensembles |
| IV    | Redes neurais e SVM                               |
| V     | Não supervisionado: agrupamento, EM, PCA/ICA      |

Neste repositório o funil entregue cobre os Blocos I–III e o início do V
(até agrupamento/PCA na Aula 12). Redes neurais e SVM (Bloco IV) não entram
nas atividades desta turma.

---

## Estrutura do repositório

```
.
├── README.md
├── reproduzir.sh
├── estrutura/
│   ├── comum.R
│   ├── relatorios.R
│   ├── bancoDeDados/             # base estadual, dicionário e recorte Baixada Santista
│   └── codigos/                  # scripts .R, auditorias *-numeros.txt e CSVs
│       ├── 01-dicionario-variaveis.R
│       ├── ...
│       ├── 09-splines-modelos-aditivos.R
│       ├── 10-arvores-florestas.R
│       └── 11-agrupamento-pca.R
├── consolidados-aulas/           # relatórios técnicos + dicionario/ + graficos/
├── entregas/
│   ├── entrega-1-parcial/        # Entrega 1: escolha da pergunta + lm
│   └── entrega-2-final/
│       ├── artigo-final/         # Rnw + PDF (8 p., MQO) + entrega-2-banco.R + dados
│       └── apresentacao-final/   # apresentacao.pdf (15 slides)
└── materiais-aulas/              # PDFs das aulas 01 a 12
```

| Pasta | Conteúdo |
|---|---|
| [`estrutura/bancoDeDados`](estrutura/bancoDeDados/) | Base estadual SEADE, dicionário original e recorte longitudinal da Baixada Santista ($n = 54$) |
| [`estrutura/codigos`](estrutura/codigos/) | Scripts R das atividades (`01` a `11`), auditorias `*-numeros.txt` e tabelas `.csv` geradas |
| [`consolidados-aulas`](consolidados-aulas/) | Relatórios técnicos das atividades, [`dicionario/`](consolidados-aulas/dicionario/dicionario_ipdm_baixada.pdf) e `graficos/` por etapa |
| [`entregas/entrega-1-parcial`](entregas/entrega-1-parcial/) | Entrega 1: pergunta norteadora ([`escolha-da-pergunta.md`](entregas/entrega-1-parcial/escolha-da-pergunta.md)), script R, artigo Rnw/PDF e modelo do professor |
| [`entregas/entrega-2-final`](entregas/entrega-2-final/) | Artigo acadêmico final (`artigo-final/`) + apresentação final (`apresentacao-final/`) |
| [`materiais-aulas`](materiais-aulas/) | Slides/PDFs das Aulas 01 a 12 |

---

## Atividades × Aulas

Os prefixos identificam as atividades; a atividade 02 foi dividida em exploração ampla e segmentada, e a comparação controlada da atividade 10 consolida os modelos nas mesmas cinco dobras externas.

| # | Entrega (atividade) | Script | Resultado ou diagnóstico | Aula |
|---|---|---|---|---|
| 01 | [01-dicionario-variaveis.md](consolidados-aulas/01-dicionario-variaveis.md) | [`01-dicionario-variaveis.R`](estrutura/codigos/01-dicionario-variaveis.R) | 54 observações; sem faltantes | Aula 02 |
| 02a | [02a-analise-exploratoria-ampla.md](consolidados-aulas/02a-analise-exploratoria-ampla.md) | [`02a-analise-exploratoria-ampla.R`](estrutura/codigos/02a-analise-exploratoria-ampla.R) | Mortalidade média 19,91 por mil (DP = 3,85) | Aula 03 |
| 02b | [02b-analise-exploratoria-segmentada.md](consolidados-aulas/02b-analise-exploratoria-segmentada.md) | [`02b-analise-exploratoria-segmentada.R`](estrutura/codigos/02b-analise-exploratoria-segmentada.R) | Médias por município e ano; trajetórias do painel | Aula 03 |
| 03 | [03-regressao-linear.md](consolidados-aulas/03-regressao-linear.md) | [`03-regressao-linear.R`](estrutura/codigos/03-regressao-linear.R) | Diagnósticos e intervalos por bootstrap | Aula 04 |
| 04 | [04-regressao-logistica.md](consolidados-aulas/04-regressao-logistica.md) | [`04-regressao-logistica.R`](estrutura/codigos/04-regressao-logistica.R) | Classificação e curva ROC; métricas de ajuste não são CV | Aula 05 |
| 05 | [05-avaliacao-selecao-modelos.md](consolidados-aulas/05-avaliacao-selecao-modelos.md) | [`05-avaliacao-selecao-modelos.R`](estrutura/codigos/05-avaliacao-selecao-modelos.R) | Base RMSE CV5 = 3,8599; compara regressão e classificação | Aula 06 |
| 06 | [06-metodos-reamostragem.md](consolidados-aulas/06-metodos-reamostragem.md) | [`06-metodos-reamostragem.R`](estrutura/codigos/06-metodos-reamostragem.R) | Grau 1 RMSE CV5 = 3,8945; IC bootstrap de β inclui zero | Aula 07 |
| 07 | [07-expansao-regularizacao.md](consolidados-aulas/07-expansao-regularizacao.md) | [`07-expansao-regularizacao.R`](estrutura/codigos/07-expansao-regularizacao.R) | Elastic Net p = 19: RMSE CV = 2,3121; seleção interna | Aula 08 |
| 08 | [08-metodos-suavizacao.md](consolidados-aulas/08-metodos-suavizacao.md) | [`08-metodos-suavizacao.R`](estrutura/codigos/08-metodos-suavizacao.R) | Kernel: MSE CV5 = 12,4573 (escolha de h nas mesmas dobras) | Aula 09 |
| 09 | [09-splines-modelos-aditivos.md](consolidados-aulas/09-splines-modelos-aditivos.md) | [`09-splines-modelos-aditivos.R`](estrutura/codigos/09-splines-modelos-aditivos.R) | GAM estrutural RMSE CV5 ≈ 2,35 | Aula 10 |
| 10 | [10-arvores-florestas.md](consolidados-aulas/10-arvores-florestas.md) | [`10-arvores-florestas.R`](estrutura/codigos/10-arvores-florestas.R) | MQO estrutural RMSE 2,2022; floresta 3,1419 | Aula 11 |
| 11 | [11-agrupamento-pca.md](consolidados-aulas/11-agrupamento-pca.md) | [`11-agrupamento-pca.R`](estrutura/codigos/11-agrupamento-pca.R) | PC1+PC2: 75,64%; K = 2; silhueta 0,3546 | Aula 12 |

Funil: dicionário → EDA → regressão/logística → CV/bootstrap → regularização → suavização → splines/GAM → árvores/RF → agrupamento/PCA.

### Entregas avaliadas

| Entrega | Documento | Script / gerador |
|---|---|---|
| 1 - A pergunta | [entrega-1-pergunta.pdf](entregas/entrega-1-parcial/entrega-1-pergunta.pdf) | [entrega-1-pergunta.R](entregas/entrega-1-parcial/entrega-1-pergunta.R) · [.Rnw](entregas/entrega-1-parcial/entrega-1-pergunta.Rnw) |
| 2 - Artigo final | [artigo-final.pdf](entregas/entrega-2-final/artigo-final/artigo-final.pdf) (8 p.) | [entrega-2-banco.R](entregas/entrega-2-final/artigo-final/entrega-2-banco.R) · [.Rnw](entregas/entrega-2-final/artigo-final/artigo-final.Rnw) |
| Apresentação final | [apresentacao.pdf](entregas/entrega-2-final/apresentacao-final/apresentacao.pdf) (15 slides) | Arquivo PDF enviado pela equipe |

---

## Como regenerar (se precisar)

Pré-requisitos de sistema: **R** (com os pacotes abaixo, além de `splines` que já acompanha o R) e, caso queira recompilar os artigos em PDF a partir dos `.Rnw`, uma distribuição **LaTeX** (TeX Live, MiKTeX ou TinyTeX) com **BibTeX** e a classe **`abnTeX2`**.

```r
install.packages(c("rpart", "randomForest", "glmnet", "mgcv", "cluster", "knitr"))
```

Na raiz do repositório, o lote executa todos os scripts R das atividades (`01`–`11`) e os scripts numéricos das Entregas 1 e 2, regenerando gráficos, CSVs e auditorias `*-numeros.txt` (sem recompilar os PDFs LaTeX):

```bash
bash reproduzir.sh
```

Ou execute uma atividade individualmente (a partir da raiz):

```bash
Rscript estrutura/codigos/01-dicionario-variaveis.R
# ... até 11-agrupamento-pca.R
```

Entrega 1 (compilação LaTeX opcional em `entregas/entrega-1-parcial/`):

```bash
cd entregas/entrega-1-parcial
Rscript entrega-1-pergunta.R
Rscript -e "knitr::knit2pdf('entrega-1-pergunta.Rnw', bib_engine = 'bibtex')"
```

Artigo final (na raiz do repositório; MQO + comparação controlada em `abnTeX2`):

```bash
Rscript entregas/entrega-2-final/artigo-final/entrega-2-banco.R
cd entregas/entrega-2-final/artigo-final
Rscript -e "knitr::knit2pdf('artigo-final.Rnw', bib_engine = 'bibtex')"
```

Os scripts leem [`estrutura/bancoDeDados/df_ipdm_baixada_por_municipio.csv`](estrutura/bancoDeDados/df_ipdm_baixada_por_municipio.csv), gravam auditorias em `estrutura/codigos/*-numeros.txt` e salvam os gráficos em `consolidados-aulas/graficos/`. O dicionário formal das variáveis também está disponível em [`consolidados-aulas/dicionario/dicionario_ipdm_baixada.pdf`](consolidados-aulas/dicionario/dicionario_ipdm_baixada.pdf).
