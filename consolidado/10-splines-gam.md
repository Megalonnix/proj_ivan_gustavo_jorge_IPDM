# Atividade 10 — Splines e Modelos Aditivos Generalizados (GAM): Flexibilidade Domada

> **Este documento é o resultado do script**  
> [`estrutura/scriptsR/10-splines-gam.R`](https://github.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/blob/main/estrutura/scriptsR/10-splines-gam.R).  
> O script produz os cálculos e figuras; este consolidado é a leitura analítica, matemática e aplicada dos resultados para a nossa pesquisa sobre o IPDM na Baixada Santista.

> **Alvo ($Y$):** `mortalidade_60_69` (Taxa de mortalidade de 60 a 69 anos, por mil habitantes).  
> **Preditores socioeconômicos ($X_1, X_2, X_3$):** `riqueza`, `escolaridade`, `distorcao_em`.  
> **Controles estruturais de painel:** `municipio` (9 níveis) e `ano` (2014 a 2024).  
> **Linha de base (Média do treino em CV(5)):** $\mathrm{MSE}_{\mathrm{CV}} = 14,7647$ ($\mathrm{RMSE}_{\mathrm{CV}} = 3,8425$ mortes por mil hab.).

---

## O Funil do Projeto até a Aula 10

| # | Etapa | O que fizemos | O que descobrimos |
|---|---|---|---|
| **03 / 05 / 07** | Polinômios Globais | Graus 1, 3 e 12 em `escolaridade` | Polinômio de grau alto (12) oscila violentamente nas bordas ($\mathrm{RMSE}_{\mathrm{CV}} = 240$) |
| **08** | Regularização ($L_1/L_2$) | Ridge, Lasso e Elastic Net | O Lasso descarta ruído socioeconômico e retém `municipio`, `ano` e `riqueza` |
| **09 (Oficina)** | Escolha da Pergunta | Efeitos fixos (`municipio + ano`) vs Logística | `municipio + ano` reduz $42,6\%$ do RMSE ($\mathrm{RMSE} = 2,20$) e domina a classificação ($\mathrm{AUC} = 0,89$) |
| **09 (Suavização)** | KNN e Kernel | Médias locais em `riqueza` e `ano` | Kernel ($h=0,0070$) bate a reta em `riqueza` ($-7,2\%$ MSE), mas sofre com viés nas bordas e maldição da dimensionalidade para $p > 2$ |
| **10** | **Splines e GAM** | **Polinômios por partes + modelos aditivos** | **Corrigimos a oscilação de borda (Spline Natural) e combinamos múltiplos preditores sem maldição da dimensionalidade (GAM)** |

---

## 1. Fundamentação Teórica e Matemática

Na **Aula 09**, vimos que os métodos puramente locais (KNN e Kernel de Nadaraya-Watson) resolvem a rigidez da reta paramétrica, mas deixam dois problemas em aberto:
1. **O problema das bordas:** como a média local só enxerga vizinhos de um lado nos extremos do domínio, a curva achata nas pontas (ou oscila na regressão polinomial global de grau alto — *fenômeno de Runge*).
2. **A maldição da dimensionalidade:** em $p \ge 3$ dimensões, o volume da vizinhança cresce como $\ell^p$, esvaziando a amostra local.

A **Aula 10** resolve ambos os problemas voltando ao mundo das funções de base (expansão de atributos da Aula 08), mas com **localidade controlada**: as **Splines** e os **Modelos Aditivos Generalizados (GAM)**.

### 1.1. Regressão por Partes e Splines Cúbicas (Base de Potências Truncadas)

Em vez de ajustar um único polinômio de grau 12 sobre todo o intervalo de `riqueza`, dividimos o domínio em $K$ pontos de corte chamados **nós** (*knots*) $\xi_1 < \xi_2 < \dots < \xi_K$ e ajustamos polinômios de grau baixo ($d = 3$, cúbicos) em cada subintervalo, exigindo que a curva, sua primeira derivada ($f'$) e sua segunda derivada ($f''$) sejam **contínuas nos nós**.

Matematicamente, qualquer spline cúbica com $K$ nós pode ser escrita como um modelo linear na **base de potências truncadas**, onde $h(x, \xi_k) = (x - \xi_k)_+^3 = \max(x - \xi_k, 0)^3$:

$$
f(x) = \beta_0 + \beta_1 x + \beta_2 x^2 + \beta_3 x^3 + \sum_{k=1}^{K} \theta_k (x - \xi_k)_+^3
$$

- **Por que o cubo $(x - \xi_k)_+^3$ garante suavidade perfeita?** No ponto $x = \xi_k$, a função $(x-\xi_k)_+^3$, sua derivada primeira $3(x-\xi_k)_+^2$ e sua derivada segunda $6(x-\xi_k)_+$ valem todas **zero**! Apenas a terceira derivada sofre um salto de $6\theta_k$. Assim, somar $\theta_k(x-\xi_k)_+^3$ dobra a curvatura a partir de $\xi_k$ sem criar quinas visíveis ao olho humano.
- **Contagem de graus de liberdade ($\mathrm{df}$):** São $4$ parâmetros para o polinômio cúbico base ($\beta_0, \beta_1, \beta_2, \beta_3$) mais $K$ parâmetros de nós ($\theta_1, \dots, \theta_K$), totalizando **$K + 4$ graus de liberdade** (ou $K + 3$ colunas na matriz de desenho sem o intercepto).

### 1.2. Splines Cúbicas Naturais (`ns`)

Uma spline cúbica comum ainda se comporta como um polinômio de grau 3 fora dos nós extremos ($x < \xi_1$ e $x > \xi_K$), onde há poucos dados e a variância da estimativa dispara. A **Spline Natural** impõe a restrição adicional de que a função seja **estritamente linear além dos nós de fronteira** ($f''(x) = f'''(x) = 0$ para $x < \xi_1$ e $x > \xi_K$).

- Isso economiza $4$ graus de liberdade ($2$ em cada ponta), estabilizando drasticamente as bordas. Com $K$ nós internos e $2$ nós de fronteira ($K_{\mathrm{total}} = K + 2$), uma spline natural possui exatamente **$K + 2$ graus de liberdade** (incluindo o intercepto, ou $\mathrm{df} = K + 1$ colunas em `ns(x, df)` no R).

### 1.3. Splines de Suavização (`smooth.spline`) e Graus de Liberdade Efetivos ($\mathrm{edf}$)

Em vez de escolher manualmente quantos nós colocar e onde posicioná-los, a **Spline de Suavização** busca a função $f$ que minimiza o compromisso entre fidelidade aos dados (RSS) e penalidade de curvatura (rugosidade):

$$
\hat{f}_\lambda = \operatorname{arg\,min}_{f} \left[ \sum_{i=1}^{n} \bigl(y_i - f(x_i)\bigr)^2 + \lambda \int \bigl(f''(t)\bigr)^2 \, dt \right]
$$

- **Teorema de Reinsch:** a solução exata desse problema variacional é uma **spline cúbica natural com nós em todos os pontos únicos $x_i$**, mas com coeficientes encolhidos pelo parâmetro $\lambda \ge 0$ (análogo ao Ridge da Aula 08!).
- **Os dois extremos de $\lambda$:**
  - $\lambda \to 0$: sem penalidade de curvatura $\implies$ a curva interpola todos os pontos ($\mathrm{edf} = n$, variância máxima);
  - $\lambda \to \infty$: qualquer curvatura $f''(t) \neq 0$ custa infinito $\implies$ força $f''(t) = 0$ em toda parte, reduzindo a solução à **reta de Mínimos Quadrados Ordinários** ($\mathrm{edf} = 2$: intercepto + inclinação).
- **Graus de liberdade efetivos ($\mathrm{edf}$):** Como o vetor de predições pode ser escrito como um suavizador linear $\hat{\mathbf{y}} = \mathbf{S}_\lambda \mathbf{y}$, o número efetivo de parâmetros é o traço da matriz chapéu: $\mathrm{edf}(\lambda) = \mathrm{tr}(\mathbf{S}_\lambda) \in [2, n]$.

### 1.4. Modelos Aditivos Generalizados (GAM)

Para combinar $p$ preditores mantendo a flexibilidade não-paramétrica sem cair na maldição da dimensionalidade da Aula 09, o **GAM** substitui cada termo linear $\beta_j x_{ij}$ da regressão múltipla por uma função suave univariada $f_j(x_{ij})$:

$$
y_i = \beta_0 + f_1(x_{i1}) + f_2(x_{i2}) + \dots + f_p(x_{ip}) + \varepsilon_i
$$

- **Por que o GAM escapa da maldição da dimensionalidade?** Em vez de buscar vizinhos em uma caixa $p$-dimensional (cujo volume colapsa como $\ell^p$), o GAM estima $p$ curvas **unidimensionais** somadas (via *backfitting* ou splines penalizadas simultâneas no pacote `mgcv`). O preço pago é a **hipótese de aditividade**: o efeito de $X_1$ sobre $Y$ não depende do nível de $X_2$ (ausência de interações automáticas, a menos que incluídas explicitamente).

---

## 2. O Laboratório no Banco de Dados (IPDM Baixada Santista)

Aplicamos o protocolo da Aula 10 às $n = 54$ observações da Baixada Santista utilizando exatamente as mesmas 5 dobras de validação cruzada (`set.seed(1)`):
1. **Linha de Base (Média do treino):** $\hat{y} = \bar{y}_{\mathrm{tr}}$;
2. **MQO Linear Múltiplo:** `mortalidade_60_69 ~ riqueza + escolaridade + distorcao_em` ($y \sim x_1 + x_2 + x_3$);
3. **Spline Natural em $X_1$ (`riqueza`):** `mortalidade_60_69 ~ ns(riqueza, df = k) + escolaridade + distorcao_em`, varrendo $\mathrm{df} \in \lbrace 2, 3, \dots, 8 \rbrace$;
4. **GAM Socioeconômico:** `mortalidade_60_69 ~ s(riqueza) + s(escolaridade) + s(distorcao_em)`;
5. **GAM Semiparamétrico Estrutural (integrado à Entrega 1):** `mortalidade_60_69 ~ municipio + s(ano, k = 5) + s(riqueza, k = 4)`.

### 2.1. Seleção de Flexibilidade ($\mathrm{df}$) da Spline Natural em `riqueza`

| Graus de Liberdade ($\mathrm{df}$) | Nº de Nós Internos | CV(5) MSE | CV(5) RMSE | Diagnóstico de Viés-Variância |
|---:|---:|---:|---:|---|
| $\mathrm{df} = 2$ | 1 nó (mediana) | $16,1033$ | $4,0129$ | Subajuste (corte único no meio não captura a inflexão) |
| $\mathrm{df} = 3$ | 2 nós (tercis) | $14,5393$ | $3,8130$ | Supera o MQO linear e a linha de base |
| **$\mathrm{df} = 4$** | **3 nós (quartis)** | **$14,4319$** | **$3,7989$** | **Mínimo global da curva em U (bate a linha de base)** |
| $\mathrm{df} = 5$ | 4 nós (quintis) | $15,6281$ | $3,9532$ | Início de sobreajuste (oscilação entre municípios) |
| $\mathrm{df} = 6$ | 5 nós | $15,6916$ | $3,9613$ | Variância crescente |
| $\mathrm{df} = 7$ | 6 nós | $17,4376$ | $4,1758$ | Sobreajuste severo |
| $\mathrm{df} = 8$ | 7 nós | $18,4365$ | $4,2938$ | Excesso de parâmetros para $n = 54$ |

### 2.2. Graus de Liberdade Efetivos ($\mathrm{edf}$) do GAM

Quando ajustamos o GAM com splines penalizadas (`mgcv::gam`), a validação cruzada generalizada (GCV) escolhe automaticamente a penalidade $\lambda_j$ de cada preditor:

| Termo Suavizado | $\mathrm{edf}$ Estimado | Interpretação Geométrica e Estatística |
|---|---:|---|
| `s(riqueza)` | **$1,00$** | Penalidade alta ($\lambda_1 \to \infty$): encolhido estritamente para uma **reta linear** ($1$ grau de liberdade) quando controlado pelos demais indicadores sociais |
| `s(escolaridade)` | **$1,00$** | Penalidade alta ($\lambda_2 \to \infty$): reduzido a uma **reta horizontal** sem efeito significativo |
| `s(distorcao_em)` | **$1,77$** | **Curva não-linear suave:** sobe acentuadamente entre $8\%$ e $17\%$ de distorção idade-série e **satura num platô** a partir de $18\%$ |

Já no **GAM Semiparamétrico Estrutural** (`y ~ municipio + s(ano, k=5) + s(riqueza, k=4)`):
- O suavizador temporal `s(ano)` recebe **$\mathrm{edf} = 3,91$**, desenhando com precisão a onda não-linear da pandemia de COVID-19 (estabilidade 2014–2018, explosão 2020–2022 e queda em 2024);
- Controlado pelo efeito fixo de município e pela onda temporal, `s(riqueza)` mantém **$\mathrm{edf} = 1,00$**.

### 2.3. Placar Geral de Validação Cruzada (5 Dobras)

| # | Modelo | Estrutura Funcional | CV(5) MSE | CV(5) RMSE | Ganho de MSE vs Base |
|---|---|---|---|---:|---:|
| 1 | **Linha de Base (Média)** | Constante ($\hat{y} = \bar{y}_{\mathrm{tr}}$) | $14,7647$ | $3,8425$ | $0,00\%$ |
| 2 | **MQO Linear Múltiplo** | Rígido ($x_1 + x_2 + x_3$) | $15,0907$ | $3,8847$ | $-2,21\%$ |
| 3 | **Melhor Spline Natural ($\mathrm{df}=4$)** | Semiparamétrico (`ns(x1, 4) + x2 + x3`) | **$14,4319$** | **$3,7989$** | **$+2,25\%$** |
| 4 | **GAM Socioeconômico** | Aditivo ($s(x_1) + s(x_2) + s(x_3)$) | $15,5234$ | $3,9400$ | $-5,14\%$ |
| 5 | **GAM Semiparamétrico Estrutural** | Painel (`municipio + s(ano) + s(x1)`) | **$5,5315$** | **$2,3519$** | **$+62,54\%$** |

---

## 3. Frase de Diagnóstico da Relação (Requisito da Entrega)

> **Frase para o dono do problema (Secretarias de Saúde da Baixada Santista):**  
> *"Dentre os três indicadores socioeconômicos contínuos, o preditor que claramente não é uma reta no GAM é a **distorção idade-série no Ensino Médio (`distorcao_em`, $\mathrm{edf} = 1,77$)**: seu efeito parcial sobe fortemente entre $8\%$ e $17\%$ (+3,5 mortes por mil hab., funcionando como termômetro de vulnerabilidade social urbana), mas **satura num platô horizontal a partir de $18\%$**, onde novos aumentos da distorção escolar deixam de agravar a mortalidade de idosos. Já na análise marginal de `riqueza`, a **Spline Natural com $\mathrm{df} = 4$** supera a reta de MQO e a linha de base ($\mathrm{MSE}_{\mathrm{CV}} = 14,43$ vs $14,76$) ao capturar o desnível entre o litoral sul (Mongaguá/Itanhaém), Santos e o repique industrial de Cubatão sem oscilar nas bordas. Contudo, o salto preditivo decisivo ocorre quando integramos o GAM à estrutura da nossa Pergunta 1 (`municipio + s(ano) + s(riqueza)`), onde a spline temporal ($\mathrm{edf} = 3,91$) modela o choque pandêmico de 2020–2022 e reduz o erro quadrático médio em $62,5\%$ ($\mathrm{RMSE}_{\mathrm{CV}} = 2,35$ mortes por mil hab.)."*

---

## 4. Análise Detalhada das Figuras

### Figura 1: Efeitos Parciais do GAM Socioeconômico (`s(x1)`, `s(x2)`, `s(x3)`)
![Efeitos parciais do GAM](https://raw.githubusercontent.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/main/estrutura/scriptsR/figuras/10-splines-gam_img1.png)
*(Arquivo local: `estrutura/scriptsR/figuras/10-splines-gam_img1.png`)*

- **Leitura dos três painéis:** Cada gráfico mostra a contribuição isolada $\hat{f}_j(x_j)$ centrada em zero, mantendo os demais preditores fixos, acompanhada das bandas de confiança de $\pm 2\,\mathrm{EP}$ (sombreado azul) e do tapete de observações (*rug plot*) no eixo horizontal.
- **Autocontrole da penalidade:** Note como o GAM não força curvas onde não há evidência suficiente: `s(riqueza)` ($\mathrm{edf}=1,00$, inclinação negativa) e `s(escolaridade)` ($\mathrm{edf}=1,00$, quase plana) foram automaticamente encolhidas para retas pela penalidade $\lambda \int [f''(t)]^2 dt$. Apenas `s(distorcao_em)` ($\mathrm{edf}=1,77$) conservou curvatura côncava.

---

### Figura 2: Curva em U da Seleção de Flexibilidade ($\mathrm{df}$) na Spline Natural
![Seleção de df da Spline Natural](https://raw.githubusercontent.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/main/estrutura/scriptsR/figuras/10-splines-gam_img2.png)
*(Arquivo local: `estrutura/scriptsR/figuras/10-splines-gam_img2.png`)*

- Com $\mathrm{df} = 2$ (apenas 1 nó interno), o modelo ainda é rígido demais no lugar errado ($\mathrm{MSE} = 16,10$).
- Em **$\mathrm{df} = 4$** (3 nós internos nos quartis de `riqueza`), a curva atinge o **fundo do U** ($\mathrm{MSE} = 14,43$), ficando abaixo tanto do MQO linear ($15,09$, linha vermelha pontilhada) quanto da linha de base ($14,76$, linha cinza tracejada).
- A partir de $\mathrm{df} = 5$ até $\mathrm{df} = 8$, a variância domina ($\mathrm{MSE}$ sobe para $18,44$), mas repare na diferença crucial em relação à Aula 07: enquanto o polinômio global de grau 12 explodia para $\mathrm{RMSE} = 240$ ($\mathrm{MSE} > 57.000$), a Spline Natural com $\mathrm{df} = 8$ mantém o erro contido em $18,44$ graças à **restrição de linearidade nas bordas**!

---

### Figura 3: Reta MQO vs. Spline Natural ($\mathrm{df} = 4$) em `riqueza`
![Reta MQO vs Spline Natural](https://raw.githubusercontent.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/main/estrutura/scriptsR/figuras/10-splines-gam_img3.png)
*(Arquivo local: `estrutura/scriptsR/figuras/10-splines-gam_img3.png`)*

- A **reta MQO (cinza tracejada)** impõe uma queda constante, subestimando a mortalidade na faixa intermediária e ignorando a estrutura em degraus da região.
- A **Spline Natural com $\mathrm{df} = 4$ (verde contínua)** acompanha a queda acentuada entre os municípios de menor riqueza (Mongaguá/Peruíbe) e Santos (riqueza $\approx 0,50$), captura a estabilização/repique na faixa de Cubatão/Bertioga (riqueza $> 0,51$), e **sai em linha reta comportada nas duas extremidades** do gráfico, sem o efeito de achatamento horizontal do KNN nem o tremor de borda do polinômio global.

---

### Figura 4: O Padrão de Saturação em `distorcao_em` ($\mathrm{edf} = 1,77$)
![Efeito parcial de distorção idade-série](https://raw.githubusercontent.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/main/estrutura/scriptsR/figuras/10-splines-gam_img4.png)
*(Arquivo local: `estrutura/scriptsR/figuras/10-splines-gam_img4.png`)*

- Esta figura isola a descoberta não-linear do GAM socioeconômico: municípios com baixa distorção escolar ($8\%$ a $12\%$, como Santos) têm efeito parcial negativo sobre a mortalidade (cerca de $-2$ a $-3$ mortes/mil hab.). Conforme a distorção avança até $17\%$, o efeito parcial sobe para $+1$ morte/mil hab., estabilizando num **platô de saturação** entre $18\%$ e $27\%$.

---

## 5. Resolução Completa dos Exercícios da Aula 10 (Slides 29/32 e 30/32)

Para fundamentação teórica completa do grupo, resolvemos passo a passo todos os exercícios dos slides 29/32 e 30/32 da Aula 10 ([TAE_aula10.PDF](file:///c:/Users/Ivan/Documents/Pasta-Documentos-PC-antigo/GITHUB-Meus-Repositorios/PesquisaTeoAprendiEstati_2026_v2/proj_ivan_gustavo_jorge_(IPDM)/slides_aulas/TAE_aula10.PDF)).

### Parte A: Exercícios de Cálculo (Slide 29/32)

#### Exercício 1: Contagem de Parâmetros na Spline Cúbica e na Spline Natural ($K = 4$ nós)
*Enunciado:* Spline cúbica com $K = 4$ nós: quantos coeficientes têm os 5 polinômios soltos, quantas restrições os nós impõem e quantos parâmetros sobram? E a spline natural com esses 4 nós internos e os 2 de fronteira?

*Resolução:*
1. **Polinômios cúbicos soltos:** Com $K = 4$ nós, o eixo é dividido em $K + 1 = 5$ pedaços. Cada polinômio cúbico ($a + bx + cx^2 + dx^3$) tem $4$ coeficientes, totalizando $5 \times 4 = \mathbf{20}$ **coeficientes soltos**.
2. **Restrições impostas pelos nós:** Em cada um dos $K = 4$ nós, exigimos continuidade do valor da função ($f$), da primeira derivada ($f'$) e da segunda derivada ($f''$), ou seja, $3$ restrições por nó, totalizando $4 \times 3 = \mathbf{12}$ **restrições**.
3. **Parâmetros livres na spline cúbica comum:** Sobram $20 - 12 = \mathbf{8}$ **parâmetros livres** (fórmula geral: $K + 4 = 4 + 4 = 8$).
4. **Spline natural com 4 nós internos e 2 de fronteira ($K_{\mathrm{total}} = 6$ nós):** Uma spline cúbica com $6$ nós teria $6 + 4 = 10$ parâmetros. Porém, a spline natural exige que a curva seja uma **reta** ($f'' = 0$ e $f''' = 0$) antes do primeiro nó de fronteira e depois do último ($2 \times 2 = 4$ restrições extras nas pontas), restando $10 - 4 = \mathbf{6}$ **parâmetros livres** (ou $K_{\mathrm{internos}} + 2 = 4 + 2 = 6$).

---

#### Exercício 2: Base Truncada Linear por Pedaços e Continuidade no Nó
*Enunciado:* Seja $f(x) = 100 + 2x + 3(x - 50)_+ - 4(x - 80)_+$, com $(u)_+ = \max(u, 0)$. Calcule $f(40), f(50), f(60)$ e $f(100)$ e a inclinação em cada pedaço. A curva é contínua em $x = 50$?

*Resolução:*
1. **Valores de $f(x)$:**
   - Em $x = 40$ (ambos os termos truncados desligados, pois $40 \le 50$ e $40 \le 80$): $f(40) = 100 + 2(40) + 0 - 0 = \mathbf{180}$.
   - Em $x = 50$ (como $(50 - 50)_+ = 0$ e $(50 - 80)_+ = 0$): $f(50) = 100 + 2(50) + 0 - 0 = \mathbf{200}$.
   - Em $x = 60$ (primeiro nó em $50$ ligado e segundo em $80$ desligado): $f(60) = 100 + 2(60) + 3(60 - 50) - 0 = 220 + 30 = \mathbf{250}$.
   - Em $x = 100$ (ambos os nós em $50$ e $80$ ligados): $f(100) = 100 + 2(100) + 3(100 - 50) - 4(100 - 80) = 300 + 150 - 80 = \mathbf{370}$.
2. **Inclinação ($f'(x)$) em cada pedaço:**
   - **Pedaço 1 ($x < 50$):** $f(x) = 100 + 2x \implies f'(x) = \mathbf{+2}$.
   - **Pedaço 2 ($50 < x < 80$):** $f(x) = 100 + 2x + 3(x - 50) = -50 + 5x \implies f'(x) = 2 + 3 = \mathbf{+5}$.
   - **Pedaço 3 ($x > 80$):** $f(x) = -50 + 5x - 4(x - 80) = 270 + 1x \implies f'(x) = 5 - 4 = \mathbf{+1}$.
3. **Continuidade em $x = 50$:** **Sim, a curva é contínua em $x = 50$**, pois o limite pela esquerda $\lim_{x \to 50^-} (100 + 2x) = 200$ coincide exatamente com o limite pela direita $\lim_{x \to 50^+} [100 + 2x + 3(x-50)] = 200$. (Como as potências truncadas são de grau 1, a função é contínua mas possui "quina" na inclinação, que pula de $+2$ para $+5$ em $x = 50$).

---

#### Exercício 3: Pedágio de Curvatura $\int_0^1 g''(t)^2 dt$ e Seleção por $\lambda$
*Enunciado:* Em $[0, 1]$, calcule o pedágio $\int_0^1 g''(t)^2 dt$ de $g_1(x) = 3 + 2x$, $g_2(x) = x^2$ e $g_3(x) = x^3$. Três curvas candidatas têm RSS 52, 30 e 12 e pedágios 0, 4 e 30: qual minimiza o critério com $\lambda = 0{,}1$, com $\lambda = 1$ e com $\lambda = 10$?

*Resolução:*
1. **Cálculo dos pedágios de rugosidade em $[0, 1]$:**
   - Para $g_1(x) = 3 + 2x$ (reta): $g_1'(x) = 2 \implies g_1''(x) = 0 \implies \int_0^1 0^2\,dt = \mathbf{0}$.
   - Para $g_2(x) = x^2$ (parábola): $g_2'(x) = 2x \implies g_2''(x) = 2 \implies \int_0^1 2^2\,dt = \int_0^1 4\,dt = \mathbf{4}$.
   - Para $g_3(x) = x^3$ (cúbica): $g_3'(x) = 3x^2 \implies g_3''(x) = 6x \implies \int_0^1 (6t)^2\,dt = 36\left[\frac{t^3}{3}\right]_0^1 = \mathbf{12}$.
2. **Comparação das três curvas candidatas pelo critério $\mathrm{Custo}(\lambda) = \mathrm{RSS} + \lambda \cdot \mathrm{Ped}$:**
   - Candidata 1: $\mathrm{RSS}_1 = 52$, $\mathrm{Ped}_1 = 0 \implies \mathrm{Custo}_1(\lambda) = 52 + 0\lambda = 52$.
   - Candidata 2: $\mathrm{RSS}_2 = 30$, $\mathrm{Ped}_2 = 4 \implies \mathrm{Custo}_2(\lambda) = 30 + 4\lambda$.
   - Candidata 3: $\mathrm{RSS}_3 = 12$, $\mathrm{Ped}_3 = 30 \implies \mathrm{Custo}_3(\lambda) = 12 + 30\lambda$.
   - **Com $\lambda = 0{,}1$:** $\mathrm{Custo}_1 = 52$; $\mathrm{Custo}_2 = 30 + 0{,}4 = 30{,}4$; $\mathrm{Custo}_3 = 12 + 3{,}0 = \mathbf{15{,}0} \implies$ **vence a Curva 3** (pouco freio: ganha quem cola melhor nos pontos).
   - **Com $\lambda = 1$:** $\mathrm{Custo}_1 = 52$; $\mathrm{Custo}_2 = 30 + 4 = \mathbf{34}$; $\mathrm{Custo}_3 = 12 + 30 = 42 \implies$ **vence a Curva 2** (compromisso intermediário entre ajuste e suavidade).
   - **Com $\lambda = 10$:** $\mathrm{Custo}_1 = \mathbf{52}$; $\mathrm{Custo}_2 = 30 + 40 = 70$; $\mathrm{Custo}_3 = 12 + 300 = 312 \implies$ **vence a Curva 1** (freio pesado: ganha a reta com pedágio zero).

---

#### Exercício 4: Predição e Aditividade no GAM
*Enunciado:* Um GAM deu $\hat{\beta}_0 = 340$ e, para um imóvel, $\hat{f}_{\mathrm{area}} = -20$, $\hat{f}_{\mathrm{praia}} = +60$ e $\hat{f}_{\mathrm{idade}} = +26$. Qual é a predição? Se o imóvel estivesse a 2 km, com $\hat{f}_{\mathrm{praia}} = -11$, quanto ela mudaria — e por que só um termo muda?

*Resolução:*
1. **Predição inicial (a 500 m da praia):**
   - Soma aditiva: $\hat{y} = \hat{\beta}_0 + \hat{f}_{\mathrm{area}} + \hat{f}_{\mathrm{praia}} + \hat{f}_{\mathrm{idade}} = 340 - 20 + 60 + 26 = \mathbf{406}$ **mil reais**.
2. **Nova predição a 2 km da praia ($\hat{f}_{\mathrm{praia}} = -11$):**
   - Nova soma: $\hat{y}_{\mathrm{novo}} = 340 - 20 - 11 + 26 = \mathbf{335}$ **mil reais**.
   - Variação: a predição muda em $-11 - (+60) = \mathbf{-71}$ **mil reais** (cai 71 mil reais).
3. **Por que só um termo muda?** Porque o GAM assume uma **estrutura puramente aditiva** ($y = \beta_0 + f_1(x_1) + f_2(x_2) + f_3(x_3)$), sem termos de interação entre preditores. Assim, cada função $f_j(x_j)$ depende unicamente da sua própria coordenada $x_j$: ao afastar o imóvel da praia mantendo a área e a idade iguais, apenas a parcela $\hat{f}_{\mathrm{praia}}$ é alterada.

---

### Parte B: Exercícios Conceituais (Slide 30/32)

#### 1. Global vs. por pedaços
- **Por que um polinômio de grau 10 oscila nas pontas e uma spline natural com 10 graus de liberdade não?**  
  No polinômio global de grau 10, um único conjunto de coeficientes precisa ajustar simultaneamente o centro e as extremidades; para curvar no meio da amostra, as potências altas ($x^8, x^9, x^{10}$) crescem explosivamente nas bordas onde há poucos dados (*fenômeno de Runge*). Na **spline natural com $\mathrm{df} = 10$**, os polinômios têm grau baixo (grau 3) e atuam localmente entre nós adjacentes; além disso, a condição de contorno natural obriga a segunda derivada a ser zero fora dos nós de fronteira, fazendo a curva seguir em **linha reta comportada nas duas pontas**.

#### 2. Os dois botões (Spline de Regressão vs. Spline de Suavização)
- **Qual é o botão de cada uma e para que lado aumenta a flexibilidade?**  
  - Na **Spline de Regressão (`ns`/`bs`)**, o botão é o número de **graus de liberdade $\mathrm{df}$** (ou número de nós $K$): quanto **maior o $\mathrm{df}$**, **maior a flexibilidade**.  
  - Na **Spline de Suavização (`smooth.spline`)**, o botão físico é a **penalidade $\lambda$** (quanto **menor o $\lambda$**, maior a flexibilidade) ou, equivalentemente, os **graus de liberdade efetivos $\mathrm{df}_\lambda$** (quanto **maior o $\mathrm{df}_\lambda$**, maior a flexibilidade).
- **Por que a curva de validação cruzada da primeira saiu serrilhada e a da segunda, lisa?**  
  Na spline de regressão, ao passar de $\mathrm{df} = 4$ para $\mathrm{df} = 5$, todos os nós internos mudam discretamente de posição (de quartis para quintis), fazendo os polinômios saltarem quando um nó cai perto de um degrau dos dados. Na spline de suavização, os nós estão fixos em todas as observações desde o início e variamos apenas o freio contínuo $\lambda$ (ou $\mathrm{df}_\lambda$), gerando uma curva em U perfeitamente lisa.

#### 3. Aditivo (Hipótese do GAM e Falha por Interação)
- **O que o GAM supõe sobre os preditores?**  
  Supõe **aditividade**: o efeito de cada preditor $X_j$ sobre a resposta $Y$ é uma curva $f_j(X_j)$ que se soma às demais sem depender do valor dos outros preditores (ausência de interações sinergéticas).
- **Exemplo imobiliário onde a hipótese falha:**  
  No mercado imobiliário da Baixada Santista, o valor adicional de $+1\,\mathrm{m}^2$ de área útil na avenida da praia (orla de Santos) é muito maior do que $+1\,\mathrm{m}^2$ a 5 km da praia (há uma **interação positiva entre área e distância**). O GAM aditivo puro aplicaria a mesma curva média de área tanto na orla quanto no interior, **subestimando o preço de apartamentos grandes na beira-mar** e **superestimando o de apartamentos grandes longe da praia** (para corrigir, seria necessário incluir uma superfície de interação `ti(area, dist)` ou usar árvores de decisão na Aula 11).

#### 4. O efeito de $1\,\mathrm{m}^2$ vs. o efeito de 1 ano de idade no GAM da aula
- **A diretoria quer "o efeito de $1\,\mathrm{m}^2$ a mais no preço". O GAM da aula responde?**  
  **Não com um único número fixo.** Como a área recebeu uma curva não-linear ($\mathrm{edf} = 8{,}27$, com dois degraus), o efeito marginal de $+1\,\mathrm{m}^2$ é a derivada local $\hat{f}'_{\mathrm{area}}(x)$, que muda conforme o tamanho do imóvel (vale cerca de 0,3 mil reais por $\mathrm{m}^2$ no patamar plano de 120–170 $\mathrm{m}^2$, mas salta para 3 a 4 mil reais por $\mathrm{m}^2$ nas rampas dos degraus).
- **E "o efeito de 1 ano a mais de idade"?**  
  **Sim!** Como a penalidade do GAM encolheu a curva da idade automaticamente para uma reta ($\mathrm{edf} = 1{,}00$), sua inclinação é constante em todo o domínio: cada ano a mais de idade reduz o preço em um valor fixo (cerca de $-1{,}68$ mil reais por ano, mantendo área e distância constantes).

---

## Documentos complementares

- 🧮 [`10-splines-gam.R`](https://github.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/blob/main/estrutura/scriptsR/10-splines-gam.R) — script R reprodutível desta atividade.
- 📋 [Relatório técnico bruto (`10-splines-gam.md`)](https://github.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/blob/main/estrutura/scriptsR/10-splines-gam.md).
- 📎 [Consolidado 08 — Regularização](https://github.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/blob/main/consolidado/08-regularizacao.md).
- 📎 [Consolidado 09 — Métodos de Suavização](https://github.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/blob/main/consolidado/09-metodos-suavizacao.md).
- 📎 [Consolidado 09 — Escolha da Pergunta](https://github.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/blob/main/consolidado/09-escolha-da-pergunta.md).
- 📄 [Artigo Formal — Entrega 1 (PDF)](https://github.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/blob/main/consolidado/entrega-1-pergunta.pdf).
