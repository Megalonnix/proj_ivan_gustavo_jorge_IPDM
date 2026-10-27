# Teoria do Aprendizado Estatístico — Projeto IPDM

**Ciência de Dados · Fatec Rubens Lara - Baixada Santista**

Estimar e avaliar modelos de aprendizado a partir de dados — da análise exploratória e regressão linear/logística à validação treino/teste, reamostragem, regularização ($L_1$/$L_2$/Elastic Net), métodos não-paramétricos de suavização (KNN e Nadaraya–Watson), *splines* e Modelos Aditivos Generalizados (GAM) — com implementação reprodutível em **R** e **LaTeX/knitr**.

![Equipe](https://img.shields.io/badge/equipe-Ivan%2C%20Gustavo%20e%20Jorge-0B3954)
![Banco](https://img.shields.io/badge/banco-IPDM%20Seade-lightgrey)

---

## Sobre a disciplina

**Objetivo:**  
Utilizar conhecimentos estatísticos para análise e projeto de algoritmos de aprendizado de máquina para modelar, compreender e analisar conjuntos de dados complexos. Escrever esses algoritmos em pseudocódigo e executá-los por meio de linguagens de programação. Utilizar os conhecimentos adquiridos em problemas de Ciência de Dados para fundamentar a tomada de decisões baseadas em informações obtidas por meio de algoritmos de aprendizado de máquina.

**Ementa:**  
Teoria da aprendizagem estatística. Métodos de reamostragem. Expansão e regularização. Métodos de suavização. Método EM (Expectation-Maximization). Avaliação e seleção de modelos. Árvores de decisão. Redes neurais e aprendizado de máquina (redes Adaline, Madaline, Perceptron e Multilayer Perceptron - MLP). Máquina de vetores suporte. Agrupamentos. Componentes principais e independentes. Aplicação desses conhecimentos para solução dos problemas de Ciência de Dados, utilizando linguagem de programação.

**Professor:**  
Prof. Dr. João Paulo Ferreira de Mello  
([joao.mello12@fatec.sp.gov.br](mailto:joao.mello12@fatec.sp.gov.br))

**Equipe:**  
Ivan, Gustavo e Jorge

**Linguagem das entregas:**  
Sempre **R** (com relatórios técnicos em Markdown e entregas formais em LaTeX/`knitr`).

**Banco de trabalho:**  
Fundação Seade — IPDM (Índice Paulista de Desenvolvimento Municipal), recorte em painel balanceado dos 9 municípios da Região Metropolitana da Baixada Santista em 6 edições bienais (2014, 2016, 2018, 2020, 2022, 2024), totalizando $n = 54$ observações e $p = 9$ variáveis documentadas. O banco vive em `estrutura/bancoDeDados/` do próprio repositório, com cópia local usada prioritariamente pelos scripts em R.

---

## Cinco blocos do curso

O curso é dividido em cinco blocos temáticos, conforme apresentado na **Aula 01 (slide 2, "Os cinco blocos do curso")** e no cronograma de avaliações (**slide 3 da Aula 01**):

| Bloco | Conteúdo (texto literal do slide) | Aulas que cobrem | Atividades e Entregas do Projeto |
|---|---|---|---|
| **I** | Fundamentos do aprendizado estatístico | Aulas 01, 02, 03 | `01-dicionario-variaveis.R`, `02-analise-exploratoria.R`, `dicionario_ipdm_baixada.pdf` |
| **II** | Supervisionado: avaliação e regularização | Aulas 04, 05, 06, 07, 08 | `03-regressao-linear.R`, `04-regressao-logistica.R`, `05-regressao-linear-treino-teste.R`, `06-regressao-logistica-treino-teste.R`, `07-reamostragem.R`, `08-regularizacao.R` |
| **III** | Modelos flexíveis: suavização, árvores, ensembles | Aulas 09 e 10 | `09-metodos-suavizacao.R`, `10-splines-gam.R`, `09-escolha-da-pergunta.R`, `entrega-1-pergunta.pdf` |
| **IV** | Redes neurais e SVM | Próximas aulas | *Em andamento conforme avanço do semestre* |
| **V** | Não supervisionado: agrupamento, EM, PCA/ICA | Próximas aulas | *Em andamento conforme avanço do semestre* |

**Síntese da progressão metodológica nos Blocos I a III:**

- **Bloco I (Aulas 01–03):** Estruturação do dicionário de variáveis (separando tipo estatístico e representação em R), verificação de integridade (zero dados faltantes) e análise exploratória da resposta `mortalidade_60_69` ($\bar{y} = 19{,}90$, $s_y = 3{,}8504$, assimetria positiva puxada pelo choque pandêmico de 2020–2022).
- **Bloco II (Aulas 04–08):** Modelagem paramétrica supervisionada (MQO e Logística), validação honesta fora da amostra (divisão 70/30 e CV 5-fold), quantificação de incerteza via *Bootstrap* ($B=2.000$) e regularização penalizada ($L_2$ Ridge, $L_1$ Lasso e Elastic Net). Na Parte B da Atividade 08 ($p = 19$ com efeitos fixos municipais e de ano), o Elastic Net reduz o erro fora da amostra para $\text{RMSE}_{CV} = 2{,}1815$ ($-43{,}3\%$ vs. baseline).
- **Bloco III (Aulas 09–10 e Entrega Formal 1):** Comparação formal de perguntas candidatas (regressão vs. classificação, demonstrando que prever a taxa contínua e cortar na mediana atinge $\text{AUC} = 0{,}890$ contra $0{,}679$ da logística direta), suavizadores locais (KNN e Nadaraya–Watson) e modelos semiparamétricos com *splines* e GAM (`mgcv::gam`, atingindo $\text{RMSE}_{CV} = 2{,}3519$ ao capturar a onda não-linear temporal $\text{edf}_{\text{ano}} = 3{,}91$).

---

## Estrutura do repositório

```
proj_ivan_gustavo_jorge_(IPDM)/
├── README.md
├── .gitignore
├── consolidado/
│   ├── 01-dicionario-variaveis.md
│   ├── 02-analise-exploratoria.md
│   ├── 03-regressao-linear.md
│   ├── 04-regressao-logistica.md
│   ├── 05-regressao-linear-treino-teste.md
│   ├── 06-regressao-logistica-treino-teste.md
│   ├── 07-reamostragem.md
│   ├── 08-regularizacao.md
│   ├── 09-metodos-suavizacao.md
│   ├── 10-splines-gam.md
│   ├── 09-escolha-da-pergunta.md
│   ├── entrega-1-pergunta.Rnw
│   ├── entrega-1-pergunta.pdf
│   └── referencias.bib
├── estrutura/
│   ├── codigo/
│   │   ├── 09-escolha-da-pergunta.R
│   │   ├── 09-metodos-suavizacao.R
│   │   └── 10-splines-gam.R
│   ├── bancoDeDados/
│   │   ├── 0_dicionario_ipdm_ORIGINAL.csv
│   │   ├── dados_ipdm.csv
│   │   └── df_ipdm_baixada_por_municipio.csv
│   ├── dicionario/
│   │   ├── dicionario_ipdm_baixada.pdf
│   │   └── dicionario_ipdm_baixada.tex
│   ├── notebooks/
│   │   ├── 01-dicionario-variaveis.ipynb
│   │   ├── 02-analise-exploratoria.ipynb
│   │   ├── 03-regressao-linear.ipynb
│   │   ├── 04-regressao-logistica.ipynb
│   │   ├── 05-regressao-linear-treino-teste.ipynb
│   │   ├── 06-regressao-logistica-treino-teste.ipynb
│   │   ├── 07-reamostragem.ipynb
│   │   ├── 08-regularizacao.ipynb
│   │   ├── 09-metodos_suavizacao.ipynb
│   │   └── 10-splines-gam.ipynb
│   └── scriptsR/
│       ├── 01-dicionario-variaveis.R
│       ├── 01-dicionario-variaveis.md
│       ├── 02-analise-exploratoria.R
│       ├── 02-analise-exploratoria.md
│       ├── 03-regressao-linear.R
│       ├── 03-regressao-linear.md
│       ├── 04-regressao-logistica.R
│       ├── 04-regressao-logistica.md
│       ├── 05-regressao-linear-treino-teste.R
│       ├── 05-regressao-linear-treino-teste.md
│       ├── 06-regressao-logistica-treino-teste.R
│       ├── 06-regressao-logistica-treino-teste.md
│       ├── 07-reamostragem.R
│       ├── 07-reamostragem.md
│       ├── 08-regularizacao.R
│       ├── 08-regularizacao.md
│       ├── 09-metodos-suavizacao.R
│       ├── 09-metodos-suavizacao.md
│       ├── 10-splines-gam.R
│       ├── 10-splines-gam.md
│       └── figuras/
│           ├── 02-analise-exploratoria_img1..3.png
│           ├── 03-regressao-linear_img1..6.png
│           ├── 04-regressao-logistica_img1..2.png
│           ├── 05-regressao-linear-treino-teste_img1..3.png
│           ├── 06-regressao-logistica-treino-teste_img1..2.png
│           ├── 07-reamostragem_img1..2.png
│           ├── 08-regularizacao_img1..3.png
│           ├── 09-metodos-suavizacao_img1..4.png
│           └── 10-splines-gam_img1..4.png
└── slides_aulas/
    ├── TAE_aula01.PDF
    ├── TAE_aula02.PDF
    ├── TAE_aula03.PDF
    ├── TAE_aula04.PDF
    ├── TAE_aula05.PDF
    ├── TAE_aula06.PDF
    ├── TAE_aula07.PDF
    ├── TAE_aula08.PDF
    ├── TEA_aula09.PDF
    ├── TAE_aula09_suavizacao.PDF
    └── TAE_aula10.PDF
```

| Pasta | O que é |
|---|---|
| `consolidado/` | Relatórios didáticos e matemáticos das atividades (com equações em LaTeX e resolução dos exercícios dos slides); inclui a análise comparativa da Atividade 09 (`09-escolha-da-pergunta.md`) e a entrega formal compilada em PDF (`entrega-1-pergunta.pdf`) a partir de `entrega-1-pergunta.Rnw` |
| `estrutura/codigo/` | Scripts de geração da Entrega 1 (`09-escolha-da-pergunta.R`) e espelhos das análises do Bloco III |
| `estrutura/bancoDeDados/` | Arquivos `.csv` utilizados nas análises (`df_ipdm_baixada_por_municipio.csv` e base original Seade) |
| `estrutura/dicionario/` | Dicionário formal de variáveis em LaTeX (`dicionario_ipdm_baixada.tex`) e documento compilado (`dicionario_ipdm_baixada.pdf`) |
| `estrutura/notebooks/` | Notebooks `.ipynb` com kernel R para execução direta em nuvem via Google Colab |
| `estrutura/scriptsR/` | Scripts reprodutíveis `.R` de todas as 10 atividades, outputs técnicos `.md` e diretório `figuras/` |
| `slides_aulas/` | Slides das aulas do Prof. Dr. João Paulo Ferreira de Mello (PDFs) |

---

## Atividades × aulas

Os números de página referem-se aos marcadores do PDF das aulas em `slides_aulas/`. Todos os relatórios em `consolidado/` incluem, além da análise aplicada ao IPDM, a fundamentação matemática e a resolução completa dos exercícios de cálculo e conceituais dos slides correspondentes.

| # | Entrega Consolidada | Script Fonte | Aula | Slide (PDF) | Foco Técnico e Teórico |
|---|---|---|---|---|---|
| 01 | [01-dicionario-variaveis.md](consolidado/01-dicionario-variaveis.md) | `estrutura/scriptsR/01-dicionario-variaveis.R` | Aulas 01 e 02 | pág. 20 | Dicionário de variáveis, separação entre Tipo Estatístico e Tipo no R (`cod_ibge` como identificador nominal) e decomposição $\mathbb{E}[(y_0-\hat{f}(x_0))^2]$ |
| 02 | [02-analise-exploratoria.md](consolidado/02-analise-exploratoria.md) | `estrutura/scriptsR/02-analise-exploratoria.R` | Aula 03 | pág. 23 | EDA univariada e bivariada, comparação média vs. mediana, sobreposição de densidade Normal $\mathcal{N}(\bar{y}, s^2)$ e auditoria de dados faltantes |
| 03 | [03-regressao-linear.md](consolidado/03-regressao-linear.md) | `estrutura/scriptsR/03-regressao-linear.R` | Aula 04 | pág. 18 | Estimação MQO ($\hat{\boldsymbol{\beta}} = (\mathbf{X}^\top\mathbf{X})^{-1}\mathbf{X}^\top\mathbf{y}$), decomposição $\text{SQT}=\text{SQE}+\text{SQR}$, regressão simples vs. múltipla e diagnóstico de resíduos |
| 04 | [04-regressao-logistica.md](consolidado/04-regressao-logistica.md) | `estrutura/scriptsR/04-regressao-logistica.R` | Aula 05 | pág. 29 | Função logística $\sigma(\eta)$, log-chances (*logit*), Razão de Chances ($\text{OR}=e^{\beta_j}$), matrizes de confusão em limiares $0{,}3/0{,}5/0{,}7$ e curva ROC/AUC |
| 05 | [05-regressao-linear-treino-teste.md](consolidado/05-regressao-linear-treino-teste.md) | `estrutura/scriptsR/05-regressao-linear-treino-teste.R` | Aula 06 | pág. 27 | Protocolo 70/30 treino/teste, compromisso viés–variância, $\text{RMSE}_{\text{teste}}$ vs. baseline e simulação de volatilidade em 200 *splits* |
| 06 | [06-regressao-logistica-treino-teste.md](consolidado/06-regressao-logistica-treino-teste.md) | `estrutura/scriptsR/06-regressao-logistica-treino-teste.R` | Aula 06 | pág. 27 | Classificação honesta fora da amostra com binarização estrita pela mediana do treino (prevenção de *data leakage*) em split 70/30 e CV 5-fold |
| 07 | [07-reamostragem.md](consolidado/07-reamostragem.md) | `estrutura/scriptsR/07-reamostragem.R` | Aula 07 | pág. 23 | Validação cruzada $k$-fold para seleção de grau polinomial ($d \in \{1, 3, 12\}$) e *Bootstrap* não-paramétrico ($B=2.000$) para $\text{EP}_{\text{boot}}$ e $\text{IC}_{95\%}$ |
| 08 | [08-regularizacao.md](consolidado/08-regularizacao.md) | `estrutura/scriptsR/08-regularizacao.R` | Aula 08 | pág. 29 | Regularização Ridge ($\alpha=0$), Lasso ($\alpha=1$) e Elastic Net ($\alpha=0{,}5$), regra de 1 erro-padrão ($\lambda_{1se}$) e seleção esparsa em espaço expandido ($p=19$) |
| 09 | [09-metodos-suavizacao.md](consolidado/09-metodos-suavizacao.md) | `estrutura/scriptsR/09-metodos-suavizacao.R` | Aula 09 | pág. 26 | Suavizadores lineares locais $\hat{\mathbf{y}}=\mathbf{S}\mathbf{y}$: KNN regressão e Nadaraya–Watson com kernel Gaussiano, calibrados por CV 5-fold |
| 10 | [10-splines-gam.md](consolidado/10-splines-gam.md) | `estrutura/scriptsR/10-splines-gam.R` | Aula 10 | pág. 35 | *Splines* cúbicos naturais (`splines::ns`), *smoothing splines* ($\lambda\int[f''(t)]^2dt$, $\text{edf}=\text{tr}(\mathbf{S}_\lambda)$) e GAM semiparamétrico (`mgcv::gam`) |
| 11 | [09-escolha-da-pergunta.md](consolidado/09-escolha-da-pergunta.md) e [entrega-1-pergunta.pdf](consolidado/entrega-1-pergunta.pdf) | `estrutura/codigo/09-escolha-da-pergunta.R` e `consolidado/entrega-1-pergunta.Rnw` | Aula 09 (Oficina) | pág. 17 | Comparação empírica e teórica entre duas perguntas candidatas (regressão vs. classificação) e artigo técnico compilado via `knitr::knit2pdf` |

---

## Entrega 1 — Escolha da Pergunta de Pesquisa (dois documentos complementares)

A entrega de definição da pergunta de pesquisa possui dois documentos complementares em `consolidado/`:

- **[09-escolha-da-pergunta.md](consolidado/09-escolha-da-pergunta.md):** relatório analítico gerado por [09-escolha-da-pergunta.R](estrutura/codigo/09-escolha-da-pergunta.R). Compara a Pergunta 1 (regressão contínua) e a Pergunta 2 (classificação pela mediana) sob as mesmas 5 dobras de validação cruzada, incluindo o teste de dominância em que o modelo linear contínuo, binarizado *a posteriori* na mediana do treino, atinge $\text{AUC} = 0{,}890$ ($\text{Acc} = 86{,}7\%$) contra $\text{AUC} = 0{,}679$ ($\text{Acc} = 64{,}4\%$) da regressão logística direta.
- **[entrega-1-pergunta.pdf](consolidado/entrega-1-pergunta.pdf):** artigo técnico formal em duas colunas (padrão `knitr` + LaTeX + BibTeX), gerado a partir de [entrega-1-pergunta.Rnw](consolidado/entrega-1-pergunta.Rnw) e [referencias.bib](consolidado/referencias.bib), onde 100% das métricas de texto e tabelas são interpoladas dinamicamente via `\Sexpr{}`.

### Como compilar os documentos em PDF (Entrega 1 e Dicionário)

A partir da raiz do repositório, com **R** (pacote `knitr`) e uma distribuição **LaTeX** (MiKTeX ou TeX Live) instalados:

```bash
# 1. Atualizar o relatório Markdown da escolha da pergunta
Rscript estrutura/codigo/09-escolha-da-pergunta.R

# 2. Compilar o artigo formal entrega-1-pergunta.pdf via knitr
cd consolidado
Rscript -e "knitr::knit2pdf('entrega-1-pergunta.Rnw')"
cd ..

# 3. Compilar o dicionário de variáveis em LaTeX
cd estrutura/dicionario
pdflatex -interaction=nonstopmode dicionario_ipdm_baixada.tex
cd ../..
```

---

## 🚨 **Como executar o projeto:**

> [!IMPORTANT]
> **Esta seção é o guia de execução do projeto.**
> Ela explica como rodar as análises de **duas formas**: (1) **localmente**, pelos scripts `.R`, com saída completa (figuras + outputs técnicos); ou (2) **na nuvem**, pelos notebooks `.ipynb` via **Google Colab**, sem instalar nada.
> As duas formas **produzem os mesmos resultados** — os notebooks são cópias dos scripts.

| Forma | Onde roda | Para quê |
|---|---|---|
| `.R` (scripts) | Localmente, no seu PC | Execução completa, com detecção automática de pastas e geração de figuras `.png` |
| `.ipynb` (notebooks) | Na nuvem, via **Google Colab** | Reprodução sem instalar nada, útil quando não há R local |

---

### 🚨 **Método 1:** Rodar os scripts `.R` localmente

**Pré-requisitos:**

1. **R instalado** ([cran.r-project.org](https://cran.r-project.org/)).
2. **RStudio** (opcional, mas recomendado) — [posit.co/download/rstudio-desktop](https://posit.co/download/rstudio-desktop/).
3. **Pacotes usados:** `glmnet` (Atividade 08), `splines` e `mgcv` (Atividade 10, já inclusos na instalação padrão do R *recommended*) e `knitr` (para compilar o `.Rnw`). Para instalar:
   ```r
   install.packages(c("glmnet", "mgcv", "knitr"))
   ```
4. **Clone o repositório** (ou baixe o `.zip` e extraia):
   ```bash
   git clone https://github.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM.git
   ```

**Como rodar:**

1. Abra um terminal (ou o Console do RStudio) **na raiz do repositório**.
2. Execute os scripts em ordem:
   ```bash
   Rscript estrutura/scriptsR/01-dicionario-variaveis.R
   Rscript estrutura/scriptsR/02-analise-exploratoria.R
   Rscript estrutura/scriptsR/03-regressao-linear.R
   Rscript estrutura/scriptsR/04-regressao-logistica.R
   Rscript estrutura/scriptsR/05-regressao-linear-treino-teste.R
   Rscript estrutura/scriptsR/06-regressao-logistica-treino-teste.R
   Rscript estrutura/scriptsR/07-reamostragem.R
   Rscript estrutura/scriptsR/08-regularizacao.R
   Rscript estrutura/scriptsR/09-metodos-suavizacao.R
   Rscript estrutura/scriptsR/10-splines-gam.R
   Rscript estrutura/codigo/09-escolha-da-pergunta.R
   ```
3. Cada script imprime o output no terminal, grava as figuras em `estrutura/scriptsR/figuras/` e gera um `.md` de output na mesma pasta.

**Não é preciso configurar caminhos manualmente.** Os scripts:

- Detectam a própria pasta via `rstudioapi` ou `--file=` (quando rodados via `Rscript`);
- Buscam o CSV primeiro localmente em `estrutura/bancoDeDados/`;
- Se não encontrarem, baixam do GitHub como fallback.

Ou seja: com o repositório clonado, basta rodar.

---

### 🚨 **Método 2:** — Rodar os notebooks `.ipynb` no Google Colab

Os notebooks podem ser abertos diretamente no **Google Colab**, sem instalar nada e sem fazer upload manual. Basta clicar em um dos links abaixo — cada um abre o notebook correspondente já no Colab. Depois de aberto, selecione o runtime R.

| # | Abrir no Colab |
|---|---|
| 01 | [01-dicionario-variaveis.ipynb](https://colab.research.google.com/github/Megalonnix/proj_ivan_gustavo_jorge_IPDM/blob/main/estrutura/notebooks/01-dicionario-variaveis.ipynb) |
| 02 | [02-analise-exploratoria.ipynb](https://colab.research.google.com/github/Megalonnix/proj_ivan_gustavo_jorge_IPDM/blob/main/estrutura/notebooks/02-analise-exploratoria.ipynb) |
| 03 | [03-regressao-linear.ipynb](https://colab.research.google.com/github/Megalonnix/proj_ivan_gustavo_jorge_IPDM/blob/main/estrutura/notebooks/03-regressao-linear.ipynb) |
| 04 | [04-regressao-logistica.ipynb](https://colab.research.google.com/github/Megalonnix/proj_ivan_gustavo_jorge_IPDM/blob/main/estrutura/notebooks/04-regressao-logistica.ipynb) |
| 05 | [05-regressao-linear-treino-teste.ipynb](https://colab.research.google.com/github/Megalonnix/proj_ivan_gustavo_jorge_IPDM/blob/main/estrutura/notebooks/05-regressao-linear-treino-teste.ipynb) |
| 06 | [06-regressao-logistica-treino-teste.ipynb](https://colab.research.google.com/github/Megalonnix/proj_ivan_gustavo_jorge_IPDM/blob/main/estrutura/notebooks/06-regressao-logistica-treino-teste.ipynb) |
| 07 | [07-reamostragem.ipynb](https://colab.research.google.com/github/Megalonnix/proj_ivan_gustavo_jorge_IPDM/blob/main/estrutura/notebooks/07-reamostragem.ipynb) |
| 08 | [08-regularizacao.ipynb](https://colab.research.google.com/github/Megalonnix/proj_ivan_gustavo_jorge_IPDM/blob/main/estrutura/notebooks/08-regularizacao.ipynb) |
| 09 | [09-metodos_suavizacao.ipynb](https://colab.research.google.com/github/Megalonnix/proj_ivan_gustavo_jorge_IPDM/blob/main/estrutura/notebooks/09-metodos_suavizacao.ipynb) |
| 10 | [10-splines-gam.ipynb](https://colab.research.google.com/github/Megalonnix/proj_ivan_gustavo_jorge_IPDM/blob/main/estrutura/notebooks/10-splines-gam.ipynb) |

**Como rodar depois que o notebook abrir:**

1. Se o kernel não estiver em R, troque: **Runtime → Change runtime type → Runtime type: R**.
2. **Runtime → Run all** (ou `Ctrl+F9`).

**Sobre os dados:** os notebooks buscam o CSV automaticamente no repositório do GitHub. Não é preciso subir o arquivo manualmente. As análises 09 e 10 também foram preparadas para exibir seus gráficos como saída das células no Colab.

**Sobre pacotes:** o Colab já vem com a maioria dos pacotes base. Se algum faltar (ex.: `glmnet`), adicione uma célula no topo:
```r
install.packages("glmnet")
```

### Resumo em uma frase

**Local (`.R`) = projeto completo, com figuras e output técnico. Colab (`.ipynb`) = mesma análise, sem instalar nada, útil para verificação rápida.**
