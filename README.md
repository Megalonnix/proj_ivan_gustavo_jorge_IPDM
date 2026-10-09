# Teoria do Aprendizado Estatístico — Projeto IPDM

**Ciência de Dados · Fatec Rubens Lara - Baixada Santista**

Estimar e avaliar modelos de aprendizado a partir de dados — da análise exploratória e regressão linear/logística à validação treino/teste, reamostragem e regularização — com implementação em **R**.

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
Sempre **R**.

**Banco de trabalho:**  
Fundação Seade — IPDM (Índice Paulista de Desenvolvimento Municipal), recorte dos 9 municípios da Região Metropolitana da Baixada Santista em 6 anos (2014, 2016, 2018, 2020, 2022, 2024), totalizando 54 observações. O banco vive em `estrutura/bancoDeDados/` do próprio repositório, com cópia local usada como fallback pelos scripts em R.

---

## Cinco blocos do curso

O curso é dividido em cinco blocos temáticos. Essa divisão **não é interpretação nossa** — está literalmente na **Aula 01 (slide 2, "Os cinco blocos do curso")** e é reforçada pela tabela de datas de prova no **slide 3 da mesma aula** (P1 cobre Blocos I–II; P2 cobre Blocos III–IV).

| Bloco | Conteúdo (texto literal do slide) | Aulas que cobrem | Atividades do projeto |
|---|---|---|---|
| **I** | Fundamentos do aprendizado estatístico | Aulas 01, 02, 03 | `01-dicionario-variaveis.R`, `02-analise-exploratoria.R` |
| **II** | Supervisionado: avaliação e regularização | Aulas 04, 05, 06, 07, 08 | `03-regressao-linear.R`, `04-regressao-logistica.R`, `05-regressao-linear-treino-teste.R`, `06-regressao-logistica-treino-teste.R`, `07-reamostragem.R`, `08-regularizacao.R` |
| **III** | Modelos flexíveis: suavização, árvores, ensembles | Aula 09 (início) | — |
| **IV** | Redes neurais e SVM | ainda não cursadas | — |
| **V** | Não supervisionado: agrupamento, EM, PCA/ICA | ainda não cursadas | — |

**Como montamos este mapeamento (para o leitor do futuro):**

- **Blocos I a V (nomes e conteúdo):** transcrição literal do slide 2 da Aula 01.
- **Datas de prova por bloco:** tabela do slide 3 da Aula 01 — P1 (29/09) cobre Blocos I–II; P2 (13/11) cobre Blocos III–IV.
- **Quais aulas pertencem a cada bloco:** deduzido da ordem cronológica dos slides disponíveis (`slides_aulas/`). As Aulas 01–08 vão de 04/08 a 18/09 e caem inteiramente antes da P1, logo são Blocos I–II. A Aula 09 (`TEA_aula09.PDF`) é a primeira do Bloco III.
- **Blocos III, IV e V sem atividade no projeto:** **inferência nossa**, não afirmação de slide. Evidências:
  1. As entregas do projeto param na Atividade 08, que cobre temas do Bloco II (regularização).
  2. A Aula 08 fecha com o aviso: *"Próxima aula: ... viramos a chave: modelos que não supõem forma fixa — suavização, splines e GAM"* — abertura do Bloco III, concretizada na Aula 09.
- **Atividades por bloco:** associação direta entre o tema da atividade e o tema da aula correspondente (ex.: `01-dicionario-variaveis.R` ↔ Aula 02, que é sobre dicionário e tipagem).

Quando surgirem entregas para os Blocos III–V, esta tabela precisa ser revisada nas linhas III–V.

---

## Estrutura do repositório

```
proj_ivan_gustavo_jorge_(IPDM)/
├── README.md
├── .gitignore
├── assets/
│   ├── instrucoes_arquivos_ipynb.txt
│   ├── instrucoes_consolidados.txt
│   └── instrucoes_conversa_LLM.txt
├── consolidado/
│   ├── 01-dicionario-variaveis.md
│   ├── 02-analise-exploratoria.md
│   ├── 03-regressao-linear.md
│   ├── 04-regressao-logistica.md
│   ├── 05-regressao-linear-treino-teste.md
│   ├── 06-regressao-logistica-treino-teste.md
│   ├── 07-reamostragem.md
│   ├── 08-regularizacao.md
│   ├── 09-escolha-da-pergunta.md
│   ├── entrega-1-pergunta.Rnw
│   ├── entrega-1-pergunta.pdf
│   └── referencias.bib
├── estrutura/
│   ├── codigo/
│   │   └── 09-escolha-da-pergunta.R
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
│   │   └── 08-regularizacao.ipynb
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
│       └── figuras/
│           ├── 02-analise-exploratoria_img1.png
│           ├── 02-analise-exploratoria_img2.png
│           ├── 02-analise-exploratoria_img3.png
│           ├── 03-regressao-linear_img1.png
│           ├── 03-regressao-linear_img2.png
│           ├── 03-regressao-linear_img3.png
│           ├── 03-regressao-linear_img4.png
│           ├── 03-regressao-linear_img5.png
│           ├── 03-regressao-linear_img6.png
│           ├── 04-regressao-logistica_img1.png
│           ├── 04-regressao-logistica_img2.png
│           ├── 05-regressao-linear-treino-teste_img1.png
│           ├── 05-regressao-linear-treino-teste_img2.png
│           ├── 05-regressao-linear-treino-teste_img3.png
│           ├── 06-regressao-logistica-treino-teste_img1.png
│           ├── 06-regressao-logistica-treino-teste_img2.png
│           ├── 07-reamostragem_img1.png
│           ├── 07-reamostragem_img2.png
│           ├── 08-regularizacao_img1.png
│           ├── 08-regularizacao_img2.png
│           └── 08-regularizacao_img3.png
├── slides_aulas/
│   ├── TAE_aula01.PDF
│   ├── TAE_aula02.PDF
│   ├── TAE_aula03.PDF
│   ├── TAE_aula04.PDF
│   ├── TAE_aula05.PDF
│   ├── TAE_aula06.PDF
│   ├── TAE_aula07.PDF
│   ├── TAE_aula08.PDF
│   └── TEA_aula09.PDF
└── to.delete/
```

| Pasta | O que é |
|---|---|
| `assets/` | Instruções auxiliares do projeto (arquivos `.txt` de orientação interna) |
| `consolidado/` | Relatórios didáticos das atividades; inclui a análise comparativa da Atividade 09 (`09-escolha-da-pergunta.md`) e a entrega formal em PDF, cujo fonte é `entrega-1-pergunta.Rnw` |
| `estrutura/codigo/` | Scripts auxiliares de análise e geração de entregas, incluindo a Atividade 09 |
| `estrutura/bancoDeDados/` | Arquivos `.csv` utilizados nas análises (principalmente o da Baixada Santista) |
| `estrutura/dicionario/` | Dicionário de variáveis em LaTeX (`.tex`) e PDF |
| `estrutura/notebooks/` | Cópias das análises `.R`, feitas para rodar em nuvem via Colab |
| `estrutura/scriptsR/` | Análises pedidas nos slides do professor — scripts `.R`, outputs técnicos `.md` e `figuras/` |
| `slides_aulas/` | Slides das aulas do professor (PDFs), base para o mapeamento aulas × blocos × atividades |
| `to.delete/` | Pasta temporária, a ser removida |

---

## Atividades × aulas

Os números de página referem-se aos marcadores `===== Page X =====` do PDF das aulas (extração do arquivo original em `slides_aulas/`). A numeração interna dos slides do professor é diferente (ex.: a pág. 18 da Aula 04 corresponde ao slide "12/15").

| # | Entrega | Script | Aula | Slide (PDF) | Por que |
|---|---|---|---|---|---|
| 01 | [01-dicionario-variaveis.md](consolidado/01-dicionario-variaveis.md) | `estrutura/scriptsR/01-dicionario-variaveis.R` | Aula 02 | pág. 20 | Exercício "Sobre um data.frame (o seu, ou iris): inspecione, corrija os tipos e comece o dicionário" |
| 02 | [02-analise-exploratoria.md](consolidado/02-analise-exploratoria.md) | `estrutura/scriptsR/02-analise-exploratoria.R` | Aula 03 | pág. 23 | Exercício "Aplique ao banco que você escolheu: 1) EDA de variável quantitativa; 2) relação entre duas variáveis; 3) densidade Normal sobreposta; 4) faltantes" |
| 03 | [03-regressao-linear.md](consolidado/03-regressao-linear.md) | `estrutura/scriptsR/03-regressao-linear.R` | Aula 04 | pág. 18 | Exercício "Escolha uma resposta quantitativa e um ou mais preditores: 1) regressão simples; 2) gráfico quadrado com reta; 3) múltipla; 4) resíduos vs ajustado" |
| 04 | [04-regressao-logistica.md](consolidado/04-regressao-logistica.md) | `estrutura/scriptsR/04-regressao-logistica.R` | Aula 05 | pág. 29 | Exercício "Escolha uma resposta binária y (0/1): 1) logística + razões de chance; 2) matriz de confusão; 3) limiares 0,3/0,5/0,7; 4) AUC" |
| 05 | [05-regressao-linear-treino-teste.md](consolidado/05-regressao-linear-treino-teste.md) | `estrutura/scriptsR/05-regressao-linear-treino-teste.R` | Aula 06 | pág. 27 | Exercício "Aplique o protocolo ao seu banco, com dois modelos das aulas passadas: 1) dividir 70/30; 2) ajustar dois candidatos só no treino; 3) comparar no teste" |
| 06 | [06-regressao-logistica-treino-teste.md](consolidado/06-regressao-logistica-treino-teste.md) | `estrutura/scriptsR/06-regressao-logistica-treino-teste.R` | Aula 06 | pág. 27 | Mesmo exercício da pág. 27, estendido à classificação por analogia. O enunciado não especifica `glm`, mas diz "dois modelos das aulas passadas" |
| 07 | [07-reamostragem.md](consolidado/07-reamostragem.md) | `estrutura/scriptsR/07-reamostragem.R` | Aula 07 | pág. 23 | Exercício "Traque a divisão única da Aula 6 por validação cruzada, e qualifique um coeficiente por bootstrap: 1) CV(5) comparando dois candidatos; 2) bootstrap do coeficiente" |
| 08 | [08-regularizacao.md](consolidado/08-regularizacao.md) | `estrutura/scriptsR/08-regularizacao.R` | Aula 08 | pág. 29 | Exercício "library(glmnet)... cv.glmnet(X, yv, alpha = 1); cv.glmnet(X, yv, alpha = 0)" — Lasso e Ridge com curva em U |
| 09 | [09-escolha-da-pergunta.md](consolidado/09-escolha-da-pergunta.md) e [entrega-1-pergunta.pdf](consolidado/entrega-1-pergunta.pdf) | `estrutura/codigo/09-escolha-da-pergunta.R` e `consolidado/entrega-1-pergunta.Rnw` | Aula 09 | — | Compara duas perguntas candidatas e documenta a escolha da pergunta de pesquisa; a entrega formal em PDF aprofunda a pergunta escolhida |

---

## Atividade 09 — dois documentos complementares

A Atividade 09 tem dois documentos com papéis diferentes; um não substitui o outro:

- **[09-escolha-da-pergunta.md](consolidado/09-escolha-da-pergunta.md):** relatório analítico da atividade. Compara as duas perguntas candidatas, registra os diagnósticos do banco e os resultados da validação cruzada que fundamentam a escolha da Pergunta 1. É gerado pelo script [09-escolha-da-pergunta.R](estrutura/codigo/09-escolha-da-pergunta.R).
- **[entrega-1-pergunta.pdf](consolidado/entrega-1-pergunta.pdf):** versão formal da entrega, voltada à apresentação da pergunta escolhida. Expõe o problema, os dados, a pergunta, os diagnósticos e a justificativa. Seu fonte editável é [entrega-1-pergunta.Rnw](consolidado/entrega-1-pergunta.Rnw), e as referências estão em [referencias.bib](consolidado/referencias.bib).

### Como gerar os dois documentos

É necessário ter **R** instalado. Para gerar o PDF, também é necessário o pacote R `knitr` e uma distribuição LaTeX (por exemplo, MiKTeX ou TeX Live).

Na raiz do repositório, gere primeiro o relatório Markdown:

```bash
Rscript estrutura/codigo/09-escolha-da-pergunta.R
```

O script lê o CSV em `estrutura/bancoDeDados/` (com alternativa de download do repositório) e grava `consolidado/09-escolha-da-pergunta.md`.

Em seguida, gere o PDF. No RStudio, abra `consolidado/entrega-1-pergunta.Rnw`, confirme que o mecanismo de Sweave é **knitr** e clique em **Compile PDF**. Alternativamente, no terminal:

```bash
cd consolidado
Rscript -e "knitr::knit2pdf('entrega-1-pergunta.Rnw')"
```

Execute o comando do terminal a partir da raiz do repositório. O `.Rnw` usa o CSV local em `estrutura/bancoDeDados/` (ou o baixa como alternativa), e o processo de compilação usa `referencias.bib`. O PDF é gravado em `consolidado/entrega-1-pergunta.pdf`.

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
3. **Pacotes usados:** `glmnet` (apenas para a Atividade 08). Para instalar:
   ```r
   install.packages("glmnet")
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
   ```
3. Cada script imprime o output no terminal, grava as figuras em `estrutura/scriptsR/figuras/` e gera um `.md` de output na mesma pasta.

**Não é preciso configurar caminhos manualmente.** Os scripts:

- Detectam a própria pasta via `rstudioapi` (quando rodados pelo RStudio);
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

**Como rodar depois que o notebook abrir:**

1. Se o kernel não estiver em R, troque: **Runtime → Change runtime type → Runtime type: R**.
2. **Runtime → Run all** (ou `Ctrl+F9`).

**Sobre os dados:** os notebooks buscam o CSV automaticamente no repositório do GitHub. Não é preciso subir o arquivo manualmente.

**Sobre pacotes:** o Colab já vem com a maioria dos pacotes base. Se algum faltar (ex.: `glmnet`), adicione uma célula no topo:
```r
install.packages("glmnet")
```

### Resumo em uma frase

**Local (`.R`) = projeto completo, com figuras e output técnico. Colab (`.ipynb`) = mesma análise, sem instalar nada, útil para verificação rápida.**