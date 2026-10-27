# Atividade 10 — Splines e Modelos Aditivos Generalizados (GAM): Flexibilidade Domada

> **Este documento é o resultado do script**  
> [`estrutura/scriptsR/10-splines-gam.R`](https://github.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/blob/main/estrutura/scriptsR/10-splines-gam.R).  
> O script produz os cálculos e figuras; este consolidado é a leitura analítica, matemática e aplicada dos resultados para a nossa pesquisa sobre o IPDM na Baixada Santista.

> **Alvo ($Y$):** `mortalidade_60_69` (Taxa de mortalidade de 60 a 69 anos, por mil habitantes).  
> **Preditores socioeconômicos ($X_1, X_2, X_3$):** `riqueza`, `escolaridade`, `distorcao_em`.  
> **Controles estruturais de painel:** `municipio` (9 níveis) e `ano` (2014 a 2024).  
> **Linha de base (Média do treino em CV(5)):** $\text{MSE}_{\text{CV}} = 14,7647$ ($\text{RMSE}_{\text{CV}} = 3,8425$ mortes por mil hab.).

---

## O Funil do Projeto até a Aula 10

| # | Etapa | O que fizemos | O que descobrimos |
|---|---|---|---|
| **03 / 05 / 07** | Polinômios Globais | Graus 1, 3 e 12 em `escolaridade` | Polinômio de grau alto (12) oscila violentamente nas bordas ($\text{RMSE}_{\text{CV}} = 240$) |
| **08** | Regularização ($L_1/L_2$) | Ridge, Lasso e Elastic Net | O Lasso descarta ruído socioeconômico e retém `municipio`, `ano` e `riqueza` |
| **09 (Oficina)** | Escolha da Pergunta | Efeitos fixos (`municipio + ano`) vs Logística | `municipio + ano` reduz $42,6\%$ do RMSE ($\text{RMSE} = 2,20$) e domina a classificação ($\text{AUC} = 0,89$) |
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

Matematicamente, qualquer spline cúbica com $K$ nós pode ser escrita como um modelo linear na **base de potências truncadas**:

$$f(x) = \beta_0 + \beta_1 x + \beta_2 x^2 + \beta_3 x^3 + \sum_{k=1}^{K} \theta_k \, h(x, \xi_k), \qquad \text{onde } h(x, \xi_k) = (x - \xi_k)_+^3 = \begin{cases} (x - \xi_k)^3, & \text{se } x > \xi_k \\ 0, & \text{se } x \le \xi_k \end{cases}$$

- **Por que o cubo $(x - \xi_k)_+^3$ garante suavidade perfeita?** No ponto $x = \xi_k$, a função $(x-\xi_k)_+^3$, sua derivada primeira $3(x-\xi_k)_+^2$ e sua derivada segunda $6(x-\xi_k)_+$ valem todas **zero**! Apenas a terceira derivada sofre um salto de $6\theta_k$. Assim, somar $\theta_k(x-\xi_k)_+^3$ dobra a curvatura a partir de $\xi_k$ sem criar quinas visíveis ao olho humano.
- **Contagem de graus de liberdade ($\text{df}$):** São $4$ parâmetros para o polinômio cúbico base ($\beta_0, \beta_1, \beta_2, \beta_3$) mais $K$ parâmetros de nós ($\theta_1, \dots, \theta_K$), totalizando **$K + 4$ graus de liberdade** (ou $K + 3$ colunas na matriz de desenho sem o intercepto).

### 1.2. Splines Cúbicas Naturais (`ns`)

Uma spline cúbica comum ainda se comporta como um polinômio de grau 3 fora dos nós extremos ($x < \xi_1$ e $x > \xi_K$), onde há poucos dados e a variância da estimativa dispara. A **Spline Natural** impõe a restrição adicional de que a função seja **estritamente linear além dos nós de fronteira** ($f''(x) = f'''(x) = 0$ para $x < \xi_1$ e $x > \xi_K$).

- Isso economiza $4$ graus de liberdade ($2$ em cada ponta), estabilizando drasticamente as bordas. Com $K$ nós (incluindo os 2 das bordas), uma spline natural possui exatamente **$K$ graus de liberdade** (incluindo o intercepto, ou $\text{df} = K - 1$ colunas em `ns(x, df)` no R).

### 1.3. Splines de Suavização (`smooth.spline`) e Graus de Liberdade Efetivos ($\text{edf}$)

Em vez de escolher manualmente quantos nós colocar e onde posicioná-los, a **Spline de Suavização** busca a função $f$ que minimiza o compromisso entre fidelidade aos dados (RSS) e penalidade de curvatura (rugosidade):

$$\hat{f}_\lambda = \arg\min_{f} \left\{ \sum_{i=1}^{n} \bigl(y_i - f(x_i)\bigr)^2 + \lambda \int \bigl[f''(t)\bigr]^2 \, dt \right\}$$

- **Teorema de Reinsch:** a solução exata desse problema variacional é uma **spline cúbica natural com nós em todos os pontos únicos $x_i$**, mas com coeficientes encolhidos pelo parâmetro $\lambda \ge 0$ (análogo ao Ridge da Aula 08!).
- **Os dois extremos de $\lambda$:**
  - $\lambda \to 0$: sem penalidade de curvatura $\implies$ a curva interpola todos os pontos ($\text{edf} = n$, variância máxima);
  - $\lambda \to \infty$: qualquer curvatura $f''(t) \neq 0$ custa infinito $\implies$ força $f''(t) = 0$ em toda parte, reduzindo a solução à **reta de Mínimos Quadrados Ordinários** ($\text{edf} = 2$: intercepto + inclinação).
- **Graus de liberdade efetivos ($\text{edf}$):** Como o vetor de predições pode ser escrito como um suavizador linear $\hat{\mathbf{y}} = \mathbf{S}_\lambda \mathbf{y}$, o número efetivo de parâmetros é o traço da matriz chapéu:
  $$\text{edf}(\lambda) = \text{tr}(\mathbf{S}_\lambda) \in [2, n].$$

### 1.4. Modelos Aditivos Generalizados (GAM)

Para combinar $p$ preditores mantendo a flexibilidade não-paramétrica sem cair na maldição da dimensionalidade da Aula 09, o **GAM** substitui cada termo linear $\beta_j x_{ij}$ da regressão múltipla por uma função suave univariada $f_j(x_{ij})$:

$$y_i = \beta_0 + f_1(x_{i1}) + f_2(x_{i2}) + \dots + f_p(x_{ip}) + \varepsilon_i$$

- **Por que o GAM escapa da maldição da dimensionalidade?** Em vez de buscar vizinhos em uma caixa $p$-dimensional (cujo volume colapsa como $\ell^p$), o GAM estima $p$ curvas **unidimensionais** somadas (via *backfitting* ou splines penalizadas simultâneas no pacote `mgcv`). O preço pago é a **hipótese de aditividade**: o efeito de $X_1$ sobre $Y$ não depende do nível de $X_2$ (ausência de interações automáticas, a menos que incluídas explicitamente).

---

## 2. O Laboratório no Banco de Dados (IPDM Baixada Santista)

Aplicamos o protocolo da Aula 10 às $n = 54$ observações da Baixada Santista utilizando exatamente as mesmas 5 dobras de validação cruzada (`set.seed(1)`):
1. **Linha de Base (Média do treino):** $\hat{y} = \bar{y}_{\text{treino}}$;
2. **MQO Linear Múltiplo:** $y \sim \text{riqueza} + \text{escolaridade} + \text{distorcao\_em}$;
3. **Spline Natural em $X_1$ (`riqueza`):** $y \sim \text{ns}(\text{riqueza}, \text{df} = k) + \text{escolaridade} + \text{distorcao\_em}$, varrendo $\text{df} \in \{2, 3, \dots, 8\}$;
4. **GAM Socioeconômico:** $y \sim s(\text{riqueza}) + s(\text{escolaridade}) + s(\text{distorcao\_em})$;
5. **GAM Semiparamétrico Estrutural (integrado à Entrega 1):** $y \sim \text{municipio} + s(\text{ano}, k=5) + s(\text{riqueza}, k=4)$.

### 2.1. Seleção de Flexibilidade ($\text{df}$) da Spline Natural em `riqueza`

| Graus de Liberdade ($\text{df}$) | Nº de Nós Internos | CV(5) MSE | CV(5) RMSE | Diagnóstico de Viés-Variância |
|---:|---:|---:|---:|---|
| $\text{df} = 2$ | 1 nó (mediana) | $16,1033$ | $4,0129$ | Subajuste (corte único no meio não captura a inflexão) |
| $\text{df} = 3$ | 2 nós (tercis) | $14,5393$ | $3,8130$ | Supera o MQO linear e a linha de base |
| **$\text{df} = 4$** | **3 nós (quartis)** | **$14,4319$** | **$3,7989$** | **Mínimo global da curva em U (bate a linha de base)** |
| $\text{df} = 5$ | 4 nós (quintis) | $15,6281$ | $3,9532$ | Início de sobreajuste (oscilação entre municípios) |
| $\text{df} = 6$ | 5 nós | $15,6916$ | $3,9613$ | Variância crescente |
| $\text{df} = 7$ | 6 nós | $17,4376$ | $4,1758$ | Sobreajuste severo |
| $\text{df} = 8$ | 7 nós | $18,4365$ | $4,2938$ | Excesso de parâmetros para $n = 54$ |

### 2.2. Graus de Liberdade Efetivos ($\text{edf}$) do GAM

Quando ajustamos o GAM com splines penalizadas (`mgcv::gam`), a validação cruzada generalizada (GCV) escolhe automaticamente a penalidade $\lambda_j$ de cada preditor:

| Termo Suavizado | $\text{edf}$ Estimado | Interpretação Geométrica e Estatística |
|---|---:|---|
| `s(riqueza)` | **$1,00$** | Penalidade alta ($\lambda_1 \to \infty$): encolhido estritamente para uma **reta linear** ($1$ grau de liberdade) quando controlado pelos demais indicadores sociais |
| `s(escolaridade)` | **$1,00$** | Penalidade alta ($\lambda_2 \to \infty$): reduzido a uma **reta horizontal** sem efeito significativo |
| `s(distorcao_em)` | **$1,77$** | **Curva não-linear suave:** sobe acentuadamente entre $8\%$ e $17\%$ de distorção idade-série e **satura num platô** a partir de $18\%$ |

Já no **GAM Semiparamétrico Estrutural** (`y ~ municipio + s(ano, k=5) + s(riqueza, k=4)`):
- O suavizador temporal `s(ano)` recebe **$\text{edf} = 3,91$**, desenhando com precisão a onda não-linear da pandemia de COVID-19 (estabilidade 2014–2018, explosão 2020–2022 e queda em 2024);
- Controlado pelo efeito fixo de município e pela onda temporal, `s(riqueza)` mantém **$\text{edf} = 1,00$**.

### 2.3. Placar Geral de Validação Cruzada (5 Dobras)

| # | Modelo | Estrutura Funcional | CV(5) MSE | CV(5) RMSE | Ganho de MSE vs Base |
|---|---|---|---|---:|---:|
| 1 | **Linha de Base (Média)** | Constante ($\hat{y} = \bar{y}_{tr}$) | $14,7647$ | $3,8425$ | $0,00\%$ |
| 2 | **MQO Linear Múltiplo** | Rígido ($x_1 + x_2 + x_3$) | $15,0907$ | $3,8847$ | $-2,21\%$ |
| 3 | **Melhor Spline Natural ($\text{df}=4$)** | Semiparamétrico ($\text{ns}(x_1, 4) + x_2 + x_3$) | **$14,4319$** | **$3,7989$** | **$+2,25\%$** |
| 4 | **GAM Socioeconômico** | Aditivo ($s(x_1) + s(x_2) + s(x_3)$) | $15,5234$ | $3,9400$ | $-5,14\%$ |
| 5 | **GAM Semiparamétrico Estrutural** | Painel ($\text{municipio} + s(\text{ano}) + s(x_1)$) | **$5,5315$** | **$2,3519$** | **$+62,54\%$** |

---

## 3. Frase de Diagnóstico da Relação (Requisito da Entrega)

> **Frase para o dono do problema (Secretarias de Saúde da Baixada Santista):**  
> *"Dentre os três indicadores socioeconômicos contínuos, o preditor que claramente não é uma reta no GAM é a **distorção idade-série no Ensino Médio (`distorcao_em`, $\text{edf} = 1,77$)**: seu efeito parcial sobe fortemente entre $8\%$ e $17\%$ (+3,5 mortes por mil hab., funcionando como termômetro de vulnerabilidade social urbana), mas **satura num platô horizontal a partir de $18\%$**, onde novos aumentos da distorção escolar deixam de agravar a mortalidade de idosos. Já na análise marginal de `riqueza`, a **Spline Natural com $\text{df} = 4$** supera a reta de MQO e a linha de base ($\text{MSE}_{\text{CV}} = 14,43$ vs $14,76$) ao capturar o desnível entre o litoral sul (Mongaguá/Itanhaém), Santos e o repique industrial de Cubatão sem oscilar nas bordas. Contudo, o salto preditivo decisivo ocorre quando integramos o GAM à estrutura da nossa Pergunta 1 ($\text{municipio} + s(\text{ano}) + s(\text{riqueza})$), onde a spline temporal ($\text{edf} = 3,91$) modela o choque pandêmico de 2020–2022 e reduz o erro quadrático médio em $62,5\%$ ($\text{RMSE}_{\text{CV}} = 2,35$ mortes por mil hab.)."*

---

## 4. Análise Detalhada das Figuras

### Figura 1: Efeitos Parciais do GAM Socioeconômico (`s(x1)`, `s(x2)`, `s(x3)`)
![Efeitos parciais do GAM](https://raw.githubusercontent.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/main/estrutura/scriptsR/figuras/10-splines-gam_img1.png)
*(Arquivo local: `estrutura/scriptsR/figuras/10-splines-gam_img1.png`)*

- **Leitura dos três painéis:** Cada gráfico mostra a contribuição isolada $\hat{f}_j(x_j)$ centrada em zero, mantendo os demais preditores fixos, acompanhada das bandas de confiança de $\pm 2\text{ EP}$ (sombreado azul) e do tapete de observações (*rug plot*) no eixo horizontal.
- **Autocontrole da penalidade:** Note como o GAM não força curvas onde não há evidência suficiente: `s(riqueza)` ($\text{edf}=1,00$, inclinação negativa) e `s(escolaridade)` ($\text{edf}=1,00$, quase plana) foram automaticamente encolhidas para retas pela penalidade $\lambda \int [f''(t)]^2 dt$. Apenas `s(distorcao_em)` ($\text{edf}=1,77$) conservou curvatura côncava.

---

### Figura 2: Curva em U da Seleção de Flexibilidade ($\text{df}$) na Spline Natural
![Seleção de df da Spline Natural](https://raw.githubusercontent.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/main/estrutura/scriptsR/figuras/10-splines-gam_img2.png)
*(Arquivo local: `estrutura/scriptsR/figuras/10-splines-gam_img2.png`)*

- Com $\text{df} = 2$ (apenas 1 nó interno), o modelo ainda é rígido demais no lugar errado ($\text{MSE} = 16,10$).
- Em **$\text{df} = 4$** (3 nós internos nos quartis de `riqueza`), a curva atinge o **fundo do U** ($\text{MSE} = 14,43$), ficando abaixo tanto do MQO linear ($15,09$, linha vermelha pontilhada) quanto da linha de base ($14,76$, linha cinza tracejada).
- A partir de $\text{df} = 5$ até $\text{df} = 8$, a variância domina ($\text{MSE}$ sobe para $18,44$), mas repare na diferença crucial em relação à Aula 07: enquanto o polinômio global de grau 12 explodia para $\text{RMSE} = 240$ ($\text{MSE} > 57.000$), a Spline Natural com $\text{df} = 8$ mantém o erro contido em $18,44$ graças à **restrição de linearidade nas bordas**!

---

### Figura 3: Reta MQO vs. Spline Natural ($\text{df} = 4$) em `riqueza`
![Reta MQO vs Spline Natural](https://raw.githubusercontent.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/main/estrutura/scriptsR/figuras/10-splines-gam_img3.png)
*(Arquivo local: `estrutura/scriptsR/figuras/10-splines-gam_img3.png`)*

- A **reta MQO (cinza tracejada)** impõe uma queda constante, subestimando a mortalidade na faixa intermediária e ignorando a estrutura em degraus da região.
- A **Spline Natural com $\text{df} = 4$ (verde contínua)** acompanha a queda acentuada entre os municípios de menor riqueza (Mongaguá/Peruíbe) e Santos (riqueza $\approx 0,50$), captura a estabilização/repique na faixa de Cubatão/Bertioga (riqueza $> 0,51$), e **sai em linha reta comportada nas duas extremidades** do gráfico, sem o efeito de achatamento horizontal do KNN nem o tremor de borda do polinômio global.

---

### Figura 4: O Padrão de Saturação em `distorcao_em` ($\text{edf} = 1,77$)
![Efeito parcial de distorção idade-série](https://raw.githubusercontent.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/main/estrutura/scriptsR/figuras/10-splines-gam_img4.png)
*(Arquivo local: `estrutura/scriptsR/figuras/10-splines-gam_img4.png`)*

- Esta figura isola a descoberta não-linear do GAM socioeconômico: municípios com baixa distorção escolar ($8\%$ a $12\%$, como Santos) têm efeito parcial negativo sobre a mortalidade (cerca de $-2$ a $-3$ mortes/mil hab.). Conforme a distorção avança até $17\%$, o efeito parcial sobe para $+1$ morte/mil hab., estabilizando num **platô de saturação** entre $18\%$ e $27\%$.

---

## 5. Resolução Completa dos Exercícios da Aula 10

Para fundamentação teórica completa do grupo, resolvemos a seguir os exercícios de cálculo e conceituais da Aula 10.

### Parte A: Exercícios de Cálculo

#### Exercício 1: Base de Potências Truncadas e Continuidade no Nó
*Enunciado:* Considere a função spline cúbica com um único nó em $\xi = 5$:
$$f(x) = 10 + 2x - 0,1x^2 + 0,5(x - 5)_+^3.$$
Calcule $f(4)$, $f(5)$ e $f(7)$. Verifique o valor da primeira e da segunda derivada imediatamente à esquerda ($x \to 5^-$) e à direita ($x \to 5^+$) do nó.

*Resolução:*
1. **Avaliação nos pontos:**
   - Para $x = 4 \le 5$: o termo truncado $(4 - 5)_+^3 = 0$.
     $$f(4) = 10 + 2(4) - 0,1(16) + 0 = 10 + 8 - 1,6 = \mathbf{16,4}.$$
   - Para $x = 5$: $(5 - 5)_+^3 = 0$.
     $$f(5) = 10 + 2(5) - 0,1(25) + 0 = 10 + 10 - 2,5 = \mathbf{17,5}.$$
   - Para $x = 7 > 5$: o termo truncado liga e vale $(7 - 5)^3 = 2^3 = 8$.
     $$f(7) = 10 + 2(7) - 0,1(49) + 0,5(8) = 10 + 14 - 4,9 + 4,0 = \mathbf{23,1}.$$
2. **Derivadas em $x = 5$:**
   - Para $x < 5$: $f'(x) = 2 - 0,2x$ e $f''(x) = -0,2$. Em $x \to 5^-$: $f'(5^-) = 2 - 1 = \mathbf{1,0}$ e $f''(5^-) = \mathbf{-0,2}$.
   - Para $x > 5$: $f'(x) = 2 - 0,2x + 1,5(x-5)^2$ e $f''(x) = -0,2 + 3,0(x-5)$. Em $x \to 5^+$: $f'(5^+) = \mathbf{1,0}$ e $f''(5^+) = \mathbf{-0,2}$.
   - *Conclusão:* $f$, $f'$ e $f''$ coincidem exatamente em $x = 5$, provando que a emenda cúbica é invisível (classe $C^2$).

---

#### Exercício 2: Contagem de Graus de Liberdade (Spline Cúbica vs. Spline Natural)
*Enunciado:* Quantos parâmetros (incluindo o intercepto) possui uma spline cúbica comum com $K = 4$ nós internos? E se impusermos a condição de contorno de uma spline cúbica natural com os mesmos 4 nós internos (totalizando 6 nós com os 2 de fronteira)?

*Resolução:*
1. **Spline cúbica comum com $K = 4$ nós internos:**
   $$\text{df} = 4 \text{ (polinômio cúbico base: } 1, x, x^2, x^3\text{)} + 4 \text{ (funções truncadas nos nós)} = \mathbf{8 \text{ parâmetros}}.$$
   *(No R, `bs(x, knots = c(...), degree = 3)` cria $7$ colunas + $1$ intercepto do `lm` $= 8$).*
2. **Spline cúbica natural com 4 nós internos + 2 de fronteira ($K_{\text{total}} = 6$):**
   Partimos de uma spline cúbica com 6 nós ($6 + 4 = 10$ parâmetros) e descontamos $4$ restrições lineares nas duas extremidades ($f'' = f''' = 0$ à esquerda do primeiro nó e à direita do último):
   $$\text{df}_{\text{natural}} = 10 - 4 = \mathbf{6 \text{ parâmetros}} \quad (\text{ou } 5 \text{ colunas em } \texttt{ns(x, df = 5)} + \text{intercepto}).$$

---

#### Exercício 3: Limites de $\lambda$ e $\text{edf}$ na Spline de Suavização
*Enunciado:* Na spline de suavização que minimiza $\text{RSS} + \lambda \int [f''(t)]^2 dt$ em uma amostra com $n = 54$ valores distintos de $x$: (a) para qual modelo $\hat{f}_\lambda$ converge quando $\lambda \to 0$ e qual o seu $\text{edf}$? (b) para qual modelo converge quando $\lambda \to \infty$ e qual o seu $\text{edf}$?

*Resolução:*
- **(a) Quando $\lambda \to 0$:** A penalidade desaparece. O modelo busca zerar o $\text{RSS}$, tornando-se uma **spline cúbica natural que interpola exatamente todos os $54$ pontos** ($\text{RSS} = 0$). Os graus de liberdade efetivos vão para o teto: **$\text{edf} \to n = 54$** (viés zero na amostra, variância máxima).
- **(b) Quando $\lambda \to \infty$:** Qualquer segunda derivada $f''(t) \neq 0$ produz penalidade infinita. Para manter o custo finito, a solução força $f''(t) = 0$ em todo o domínio, o que implica $f(x) = \beta_0 + \beta_1 x$. O modelo converge exatamente para a **reta de Mínimos Quadrados Ordinários (MQO)**, com **$\text{edf} \to 2$** (intercepto e inclinação).

---

### Parte B: Exercícios Conceituais

#### 1. Por que Splines vencem Polinômios de Grau Alto?
- **Localidade vs. Globalidade:** Em um polinômio global de grau $g$ (Aula 06/07), alterar um único ponto extremo (como Mongaguá em 2022) altera todos os coeficientes $\beta_1, \dots, \beta_g$, fazendo a curva inteira chicotear de ponta a ponta. Nas splines, as funções de base são **locais**: uma mudança em um ponto afeta apenas o segmento entre os nós vizinhos, mantendo o restante da curva estável.
- **Comportamento nas bordas:** A Spline Natural obriga a função a sair como uma reta ($f''=0$) fora dos nós extremos, eliminando a explosão de variância nas pontas.

#### 2. Como o GAM contorna a Maldição da Dimensionalidade — e o que ele sacrifica?
- **Como contorna:** Na Aula 09, vimos que suavizar $p$ variáveis simultaneamente exige vizinhanças $p$-dimensionais que ficam vazias rapidamente. O GAM substitui a função geral $f(x_1, \dots, x_p)$ pela **soma de funções de uma variável** $f_1(x_1) + \dots + f_p(x_p)$. Como cada $f_j$ é estimada em dimensão $1$, a taxa de convergência estatística permanece próxima da unidimensional, mantendo a interpretabilidade através dos **gráficos de efeito parcial** (Figura 1).
- **O que sacrifica:** A forma aditiva pura **não captura interações entre preditores** (termos do tipo $f_{12}(x_1, x_2)$ em que a inclinação de $x_1$ muda conforme o nível de $x_2$). Para capturar interações complexas automaticamente, precisaremos das **Árvores de Decisão e Ensembles** (Aulas 11 e 12).

---

## 6. Documentos Complementares

- 🧮 **Script gerador:** [`estrutura/scriptsR/10-splines-gam.R`](https://github.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/blob/main/estrutura/scriptsR/10-splines-gam.R)
- 📋 **Output técnico bruto:** [`estrutura/scriptsR/10-splines-gam.md`](https://github.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/blob/main/estrutura/scriptsR/10-splines-gam.md)
- 📎 **Consolidado anterior:** [`consolidado/09-metodos-suavizacao.md`](https://github.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/blob/main/consolidado/09-metodos-suavizacao.md)
- 📄 **Entrega Formal (Pergunta de Pesquisa):** [`consolidado/entrega-1-pergunta.pdf`](https://github.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/blob/main/consolidado/entrega-1-pergunta.pdf)
