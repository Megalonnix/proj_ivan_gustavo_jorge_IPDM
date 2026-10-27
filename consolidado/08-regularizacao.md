# Atividade 08 — Expansão e Regularização: Quando Menos é Mais

> **Este documento é o resultado do script**
> [`estrutura/scriptsR/08-regularizacao.R`](https://github.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/blob/main/estrutura/scriptsR/08-regularizacao.R).
> O script produz os números; este consolidado é a leitura analítica e matemática deles —
> com o porquê das decisões e o que aprender com cada resultado.

> **Alvo ($Y$):** `mortalidade_60_69`. Preditores válidos (excluídos `ipdm` e `longevidade`).  
> **Baseline herdado:** RMSE = 3,6782 (média do treino no split 70/30) e RMSE = 3,8425 (em CV(5)).

---

## O Funil até a Aula 08

| # | Etapa | O que fizemos | O problema que restou |
|---|---|---|---|
| **03 / 04** | MQO e Logística | Ajuste na amostra cheia ($n=54$) | Risco de autoengano; sinais instáveis |
| **05 / 06** | Treino / Teste | Divisão 70/30 e métricas honestas | Alta volatilidade entre divisões |
| **07** | Reamostragem | CV(5) + Bootstrap + Polinômios (grau 12) | Medimos o sobreajuste ($\mathrm{RMSE} = 240$), mas medir não é consertar |
| **08** | **Expansão e Regularização** | **Acelerador (`model.matrix`) + Freio (Ridge, Lasso, Elastic Net)** | **Controlar a variância penalizando coeficientes grandes ($\lambda$ por CV)** |

---

## 1. Fundamentação Teórica e Matemática: O Acelerador e o Freio

Chegamos à última atividade do Bloco II. O diagnóstico acumulado nas etapas anteriores é claro:
- **$n = 54$ é pequeno** para muitos preditores.
- **Modelos complexos sem restrição explodem** (como o polinômio de grau 12 da Atividade 07) ou sofrem de **colinearidade** (preditores dizendo quase a mesma coisa inflam os erros-padrão).

Na **Aula 08**, combinamos dois movimentos opostos:
1. **O acelerador (Expansão de Atributos):** fabricar colunas novas (potências $x^2$, interações $x_1 \times x_2$ e *dummies* $0/1$ para variáveis categóricas via `model.matrix`) para reduzir o viés.
2. **O freio (Regularização):** substituir o estimador de Mínimos Quadrados Ordinários (MQO), que minimiza apenas a soma dos quadrados dos resíduos ($\mathrm{RSS}$), por uma função objetivo que **cobra um pedágio (multa)** pelo tamanho dos coeficientes $\beta_j$ (sem penalizar o intercepto $\beta_0$). Padronizar as colunas de $\mathbf{X}$ antes de penalizar é obrigatório (`standardize = TRUE` no `glmnet`), pois a multa compara a magnitude dos $\beta_j$ entre si:

$$
\hat{\beta}^{\mathrm{MQO}} = \arg\min_{\beta} \sum_{i=1}^{n} \left(y_i - \beta_0 - \sum_{j=1}^{p} \beta_j x_{ij}\right)^2 = (\mathbf{X}^\top \mathbf{X})^{-1}\mathbf{X}^\top \mathbf{y}
$$

### Os Três Sabores de Penalidade

**1. Ridge ($L_2$, $\alpha = 0$):** penaliza a **soma dos quadrados** dos coeficientes:

$$
\hat{\beta}^{\mathrm{Ridge}} = \arg\min_{\beta} \left[ \mathrm{RSS} + \lambda \sum_{j=1}^{p} \beta_j^2 \right] = (\mathbf{X}^\top \mathbf{X} + \lambda \mathbf{I})^{-1}\mathbf{X}^\top \mathbf{y}
$$

- Somar $\lambda \mathbf{I}$ na diagonal de $\mathbf{X}^\top \mathbf{X}$ estabiliza a inversão matricial sob colinearidade.
- Como a derivada de $\beta_j^2$ vai a zero quando $\beta_j \to 0$ (região de restrição redonda), o Ridge **encolhe todos os coeficientes juntos, mas não zera nenhum**.

**2. Lasso ($L_1$, $\alpha = 1$):** penaliza a **soma dos módulos (valores absolutos)**:

$$
\hat{\beta}^{\mathrm{Lasso}} = \arg\min_{\beta} \left[ \mathrm{RSS} + \lambda \sum_{j=1}^{p} \lvert\beta_j\rvert \right]
$$

- Como o módulo $\lvert\beta_j\rvert$ mantém taxa de cobrança constante até a origem (região de restrição em forma de losango com quinas sobre os eixos), o Lasso **zera coeficientes exatamente**, fazendo **seleção automática de variáveis**.

**3. Elastic Net ($0 < \alpha < 1$):** combina os dois pedágios:

$$
\hat{\beta}^{\mathrm{ENet}} = \arg\min_{\beta} \left[ \mathrm{RSS} + \lambda \left( (1 - \alpha)\sum_{j=1}^{p} \beta_j^2 + \alpha \sum_{j=1}^{p} \lvert\beta_j\rvert \right) \right]
$$

- Faz seleção esparsa como o Lasso, mas agrupa variáveis fortemente correlacionadas como o Ridge.

---

## 2. Parte A: Expansão no Bloco Socioeconômico ($p = 7$)

Primeiro, testamos a expansão estritamente nos indicadores contínuos (como nas Atividades 03 a 07), adicionando um termo quadrático e uma interação:

```r
escolaridade2   = escolaridade^2
distorcao_x_esc = distorcao_em * escolaridade
```

Note que `escolaridade` e `escolaridade2` possuem **correlação de $0,9969$** — são "variáveis gêmeas" por construção polinomial, exatamente o cenário em que o MQO sofre de colinearidade severa! No MQO de referência com esses $p = 7$ preditores:

$$
R^2 = 0,2290 \qquad \mathrm{vs.} \qquad R^2_{\mathrm{aj}} = 0,1117
$$

A queda brusca para $0,1117$ alerta que boa parte do ajuste no treino vem do excesso de graus de liberdade, não de sinal genuíno.

### Resultados da Validação Cruzada (`cv.glmnet`, $p = 7$)

| Modelo | $\lambda_{\mathrm{min}}$ | $\mathrm{MSE}_{\mathrm{min}}$ | $\lambda_{\mathrm{1se}}$ | $\mathrm{MSE}_{\mathrm{1se}}$ |
|---|---:|---:|---:|---:|
| **Ridge ($\alpha=0$)** | $5,6484$ | $14,1445$ | **$1500,2667$** | $15,5290$ |
| **Elastic Net ($\alpha=0,5$)** | $1,2989$ | $14,5705$ | $3,0005$ | $15,5278$ |
| **Lasso ($\alpha=1$)** | $0,5392$ | $14,1402$ | $1,5003$ | $15,5278$ |

#### A Conta da Regra de 1 Erro-Padrão ($\lambda_{\mathrm{1se}}$) no Lasso:
Conforme ensinado na Aula 08 (slide 17/24), o candidato $\lambda_{\mathrm{1se}}$ é o maior $\lambda$ (modelo mais simples) cujo erro de validação cruzada permanece dentro de $1$ erro-padrão do mínimo:

$$
\mathrm{Limiar}_{\mathrm{1SE}} = \mathrm{CV}_{\mathrm{min}} + \mathrm{EP}_{\mathrm{min}} = 14,1402 + 3,0340 = \mathbf{17,1742}
$$

Como $\mathrm{CV}(\lambda_{\mathrm{1se}}) = 15,5278 \le 17,1742$, a perda estatística é indistinguível do ruído das dobras! Por isso, no bloco socioeconômico isolado (onde o sinal é fraco), a regra de 1 SE encolhe tudo até restar apenas o intercepto ($\hat{y} = 19,9056$).

### Os Coeficientes em $\lambda_{\mathrm{1se}}$ ($p = 7$): A Diferença entre Encolher e Zerar

```
Sobreviventes Ridge (p=7): (Intercept), escolaridade, escolaridade2, distorcao_em, distorcao_x_esc, pib_per_capita, riqueza, ano
Sobreviventes Lasso (p=7): (Intercept)
```

No Ridge com $\lambda_{\mathrm{1se}} = 1500,27$, todos os 7 coeficientes aparecem como `0,0000` quando arredondados em 4 casas decimais, mas **nenhum é matematicamente zero** ($\approx 10^{-5}$). Já no Lasso com $\lambda_{\mathrm{1se}} = 1,50$, todos os 7 preditores foram **exatamente zerados**. No teste cego 70/30 desse bloco ($p=7$), tanto Ridge quanto Lasso empatam exatamente com o baseline da média ($\mathrm{RMSE} = 3,6782$), enquanto o MQO marca $3,6363$.

---

## 3. Parte B: Expansão Completa com `model.matrix` ($p = 19$) — Onde o Sinal Mora!

Nas Atividades 03 a 07, havíamos omitido `municipio` (qualitativa com 9 níveis) e tratado `ano` apenas como reta contínua. Seguindo literalmente a receita do laboratório da Aula 08 (slide 23/24):

```r
X_full <- model.matrix(mortalidade_60_69 ~ municipio + factor(ano) + riqueza +
                         escolaridade + escolaridade2 + distorcao_em +
                         distorcao_x_esc + pib_per_capita, data = dados)[, -1]
```

Temos agora **$p = 19$ preditores para apenas $n = 54$ observações** ($n/p = 2,84$)! Aqui, um MQO sem freio sofre com excesso de parâmetros e colinearidade entre indicadores sociais e *dummies* de município. Veja o que acontece quando acionamos o freio da regularização:

| Método ($p = 19$) | $\lambda_{\mathrm{min}}$ | $\mathrm{MSE}_{\mathrm{CV}}(\lambda_{\mathrm{min}})$ | $\mathrm{RMSE}_{\mathrm{CV}}(\lambda_{\mathrm{min}})$ | $\lambda_{\mathrm{1se}}$ | $\mathrm{MSE}_{\mathrm{CV}}(\lambda_{\mathrm{1se}})$ | Preditores $\neq 0$ ($\lambda_{\mathrm{1se}}$) |
|---|---:|---:|---:|---:|---:|---:|
| **Linha de Base (Média)** | — | $14,7647$ | $3,8425$ | — | $14,7647$ | $0$ |
| **MQO Completo ($p=19$)** | $0$ | $\approx 6,45$ | $\approx 2,54$ | — | — | $19$ |
| **Ridge ($\alpha=0$)** | $0,9417$ | $5,1278$ | $2,2645$ | $3,8017$ | $6,5572$ | $19$ |
| **Elastic Net ($\alpha=0,5$)** | $0,2608$ | **$4,7591$** | **$2,1815$** | $0,7258$ | **$5,7344$** | $10$ |
| **Lasso ($\alpha=1$)** | $0,1431$ | $5,4230$ | $2,3287$ | $0,3629$ | $6,1450$ | **$8$** |

### Quem o Lasso Guardou na Expansão Completa ($\lambda_{\mathrm{1se}} = 0,3629$)?

Dos **19 preditores candidatos**, o Lasso zerou **11 colunas de ruído/redundância** (incluindo `escolaridade`, `escolaridade2`, `distorcao_em`, `distorcao_x_esc` e `pib_per_capita`) e **reteve exatamente os 8 preditores que carregam o sinal real**:

| Preditor Sobrevivente ($\lambda_{\mathrm{1se}}$) | Coeficiente Encolhido ($\hat{\beta}$) | Leitura Substantiva para a Saúde Pública |
|---|---:|---|
| `(Intercept)` | $+22,1529$ | Patamar basal de referência |
| `municipioMongaguá` | **$+2,5484$** | Município com maior excesso estrutural de mortalidade idosa |
| `municipioItanhaém` | **$+1,1318$** | Segundo maior foco de vulnerabilidade estrutural no Litoral Sul |
| `municipioSantos` | **$-3,1161$** | Maior efeito protetor estrutural (rede hospitalar densa) |
| `municipioSão Vicente` | $-0,0772$ | Leve ajuste estrutural negativo |
| `ano_f2020` | **$+1,1428$** | Início do choque pandêmico da COVID-19 |
| `ano_f2022` | **$+4,4663$** | Pico agudo de mortalidade no biênio crítico da pandemia |
| `ano_f2024` | **$-2,2226$** | Queda expressiva pós-vacinação / retorno abaixo da média |
| `riqueza` | **$-6,6260$** | **Único indicador socioeconômico retido:** maior riqueza reduz a mortalidade |

> **Frase do laboratório (o que o Lasso disse sobre o nosso problema):**  
> *"Quando confrontado com todos os 19 preditores candidatos (efeitos espaciais, temporais e expansões socioeconômicas), o Lasso ($\lambda_{\mathrm{1se}} = 0,3629$) revela que o sinal da mortalidade de 60 a 69 anos na Baixada Santista é governado pelo **contraste territorial extremo** (Mongaguá $+2,55$ e Itanhaém $+1,13$ contra Santos $-3,12$), pelo **choque pandêmico temporal** (2020 $+1,14$, 2022 $+4,47$ e recuo em 2024 $-2,22$) e pelo **índice de riqueza municipal** ($-6,63$), descartando completamente escolaridade, distorção escolar e PIB per capita isolado como redundantes."*

---

## 4. Análise das Figuras

### Figura 1 — Curva em U do Lasso
![Curva de validação cruzada do Lasso](https://raw.githubusercontent.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/main/estrutura/scriptsR/figuras/08-regularizacao_img1.png)
*(Arquivo local: `estrutura/scriptsR/figuras/08-regularizacao_img1.png`)*

- **Os três eixos:** embaixo, $\log(\lambda)$; à esquerda, o MSE de validação cruzada com barras de $\pm 1$ EP; em cima, o número de preditores sobreviventes ($\neq 0$) em cada nível de penalidade. As duas linhas tracejadas verticais marcam $\log(\lambda_{\mathrm{min}})$ e $\log(\lambda_{\mathrm{1se}})$.

### Figura 2 — Curva em U do Ridge
![Curva de validação cruzada do Ridge](https://raw.githubusercontent.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/main/estrutura/scriptsR/figuras/08-regularizacao_img2.png)
*(Arquivo local: `estrutura/scriptsR/figuras/08-regularizacao_img2.png`)*

- Note no eixo superior que o número de preditores é constante do início ao fim: o Ridge suaviza a variância encolhendo as estimativas de forma contínua, sem jamais descartar variáveis.

### Figura 3 — Trilhas de Coeficientes: Ridge ($L_2$) vs. Lasso ($L_1$)
![Trilhas de coeficientes do Ridge e do Lasso](https://raw.githubusercontent.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/main/estrutura/scriptsR/figuras/08-regularizacao_img3.png)
*(Arquivo local: `estrutura/scriptsR/figuras/08-regularizacao_img3.png`)*

- **Esquerda (Ridge):** as curvas se aproximam assintoticamente do eixo horizontal zero à medida que $\log(\lambda)$ cresce, mas nunca tocam o zero.
- **Direita (Lasso):** as trajetórias batem no eixo zero uma a uma e permanecem coladas nele — ilustrando visualmente o efeito das quinas do losango $L_1$.

---

## 5. Resolução Completa dos Exercícios da Aula 08

Para fundamentação teórica completa, apresentamos a resolução dos exercícios dos slides 21 e 22 da Aula 08 ([TAE_aula08.PDF](file:///c:/Users/Ivan/Documents/Pasta-Documentos-PC-antigo/GITHUB-Meus-Repositorios/PesquisaTeoAprendiEstati_2026_v2/proj_ivan_gustavo_jorge_(IPDM)/slides_aulas/TAE_aula08.PDF)).

### Parte A: Exercícios de Cálculo (Slide 21/24)

#### Exercício 1: Cálculo das Penalidades $L_2$ e $L_1$
*Enunciado:* Um modelo tem $\beta = (3, -4, 0,5)$ (sem contar $\beta_0$). Calcule a penalidade $L_2$ e a penalidade $L_1$. Se $\lambda = 2$, quanto cada uma acrescenta ao $\mathrm{RSS}$?

*Resolução:*
- **1. Penalidade $L_2$ (Ridge):**
  - Soma dos quadrados: $\sum_{j=1}^{3} \beta_j^2 = 3^2 + (-4)^2 + (0,5)^2 = 9 + 16 + 0,25 = \mathbf{25,25}$.
  - Com $\lambda = 2$, acréscimo ao $\mathrm{RSS}$: $\lambda \sum \beta_j^2 = 2 \times 25,25 = \mathbf{50,50}$.
- **2. Penalidade $L_1$ (Lasso):**
  - Soma dos módulos: $\sum_{j=1}^{3} \lvert\beta_j\rvert = \lvert 3\rvert + \lvert -4\rvert + \lvert 0,5\rvert = 3 + 4 + 0,5 = \mathbf{7,50}$.
  - Com $\lambda = 2$, acréscimo ao $\mathrm{RSS}$: $\lambda \sum \lvert\beta_j\rvert = 2 \times 7,50 = \mathbf{15,00}$.

---

#### Exercício 2: Comportamento Assintótico quando $\lambda$ Cresce de $0$ a $\infty$
*Enunciado:* Com $\lambda$ crescendo de $0$ a $\infty$, diga para onde vão: (a) os coeficientes; (b) o erro de treino; (c) o viés; (d) a variância.

*Resolução:*
- **(a) Coeficientes ($\hat{\beta}_j$, $j \ge 1$):** Vão monotonicamente em direção a **zero** ($\hat{\beta} \to \mathbf{0}$; no Lasso atingem zero exato para $\lambda$ finito, no Ridge convergem a zero no limite $\lambda \to \infty$, restando apenas $\hat{\beta}_0 = \bar{y}$).
- **(b) Erro de treino ($\mathrm{MSE}_{\mathrm{tr}}$):** **Sobe monotonicamente** (pois $\lambda = 0$ é o MQO, que por definição minimiza o erro de treino sem restrições; qualquer restrição $\lambda > 0$ afasta a solução do mínimo do $\mathrm{RSS}$).
- **(c) Viés:** **Sobe** (o modelo fica cada vez mais rígido e encolhido em direção à constante $\bar{y}$).
- **(d) Variância:** **Cai para zero** (com coeficientes travados perto de zero, o modelo deixa de oscilar entre diferentes amostras de treino).

---

#### Exercício 3: Regra de 1 Erro-Padrão na Seleção de $\lambda$
*Enunciado:* Uma validação cruzada deu, para o Lasso: $\lambda = 0,5 \implies \mathrm{CV} = 2.700$ (14 preditores); $\lambda = 2 \implies \mathrm{CV} = 2.050$ (9); $\lambda = 6 \implies \mathrm{CV} = 2.120$ (5); $\lambda = 20 \implies \mathrm{CV} = 3.400$ (1). Qual é o `lambda.min`? Se o erro-padrão no fundo do U é $120$, qual $\lambda$ a regra de *um erro-padrão* escolheria, e com quantos preditores?

*Resolução:*
1. **`lambda.min`:** É o valor que minimiza o erro de CV: **$\lambda = 2$** ($\mathrm{CV}_{\mathrm{min}} = 2.050$, com $9$ preditores).
2. **Teto da regra de 1 erro-padrão:** $\mathrm{Limiar} = \mathrm{CV}_{\mathrm{min}} + \mathrm{EP}_{\mathrm{min}} = 2.050 + 120 = \mathbf{2.170}$.
3. **Escolha de `lambda.1se`:** Buscamos o **maior $\lambda$** (modelo mais parcimonioso) cujo erro não ultrapasse $2.170$. Em $\lambda = 6$, temos $\mathrm{CV} = 2.120 \le 2.170$. Logo, a regra escolhe **$\lambda = 6$, com apenas $5$ preditores** (economizando $4$ variáveis a custo estatisticamente indistinguível de ruído).

---

### Parte B: Exercícios Conceituais (Slide 22/24)

#### 1. Por que Padronizar?
- **Explicação:** Se `area` está em $\mathrm{m}^2$ (ex.: $100\ \mathrm{m}^2$) e `dist_centro` em $\mathrm{km}$, trocar `area` para hectares ($0,01\ \mathrm{ha}$) multiplica a escala de $X_1$ por $10^{-4}$ e, portanto, multiplica seu coeficiente $\beta_1$ por $10^4$ para manter a mesma predição $\beta_1 X_1$. No **MQO**, como não há multa sobre $\beta_1$, a escala se compensa exatamente e as predições não mudam. Já no **Ridge/Lasso**, a penalidade $\lambda \sum \beta_j^2$ ou $\lambda \sum \lvert\beta_j\rvert$ puniria brutalmente o coeficiente em hectares apenas pela unidade escolhida! Padronizar ($z$-score) coloca todas as variáveis na mesma régua (desvio-padrão $1$).

#### 2. Zera ou Não Zera?
- **Custo marginal perto de zero:** Reduzir um coeficiente pequeno de $0,02$ para $0,00$ economiza no Ridge apenas $0,02^2 - 0^2 = 0,0004$ de penalidade (um ganho quadrático ínfimo que não compensa a piora no $\mathrm{RSS}$). No Lasso, a economia é linear: $\lvert 0,02\rvert - 0 = 0,02$, mantendo força suficiente para empurrar o coeficiente exatamente até zero.
- **Geometria:** Na formulação restrita, as curvas de nível elípticas do $\mathrm{RSS}$ expandem até tocar a região de restrição: no Ridge é uma **esfera/círculo** ($\beta_1^2 + \beta_2^2 \le t$, sem quinas, toque fora dos eixos); no Lasso é um **politopo/losango** ($\lvert\beta_1\rvert + \lvert\beta_2\rvert \le t$, cujas quinas ficam exatamente sobre os eixos coordenados, onde $\beta_j = 0$).

#### 3. Seleção Não é Causa
- **Como `ruido` pode sobreviver no Lasso?** Em amostras finitas ($n$ pequeno), uma variável de ruído puro pode apresentar correlação amostral espúria com os resíduos de $Y$, ou o $\lambda$ escolhido por CV (focado em minimizar erro preditivo) pode ser brando o bastante para permitir a entrada de falso-positivos.
- **O que reportar:** Declarar explicitamente que o Lasso seleciona um subconjunto preditivo útil para reduzir variância, mas **sobreviver na regularização indica associação preditiva na amostra, jamais efeito causal**.

#### 4. Qual Método Usar em Cada Cenário?
- **(a) $p = 500$ preditores, suspeita de que apenas uns $10$ importam (cenário esparso):** **Lasso ($\alpha = 1$)**, pois zera os $\approx 490$ irrelevantes e entrega um modelo curto e interpretável.
- **(b) $p = 30$ preditores, todos plausíveis e vários correlacionados entre si:** **Ridge ($\alpha = 0$)** ou **Elastic Net ($\alpha = 0,5$)**, pois estabilizam grupos colineares dividindo o peso entre eles sem descartar arbitrariamente informações difusas.
- **(c) $p = 3$ preditores e $n = 5.000$ ($n/p \approx 1.667$):** **MQO tradicional (`lm`)**, pois com razão $n/p$ imensa a variância dos estimadores de mínimos quadrados já é mínima e não há necessidade de introduzir viés de encolhimento.

---

## Documentos Complementares

- 🧮 **Script gerador:** [`08-regularizacao.R`](https://github.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/blob/main/estrutura/scriptsR/08-regularizacao.R)
- 📋 **Relatório técnico bruto:** [`estrutura/scriptsR/08-regularizacao.md`](https://github.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/blob/main/estrutura/scriptsR/08-regularizacao.md)
- 📎 **Consolidados anteriores:** [`01`](01-dicionario-variaveis.md) · [`02`](02-analise-exploratoria.md) · [`03`](03-regressao-linear.md) · [`04`](04-regressao-logistica.md) · [`05`](05-regressao-linear-treino-teste.md) · [`06`](06-regressao-logistica-treino-teste.md) · [`07`](07-reamostragem.md)
