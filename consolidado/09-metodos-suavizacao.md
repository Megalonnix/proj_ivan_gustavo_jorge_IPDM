# Atividade 09 — Métodos de Suavização: Quando os Dados Moldam a Curva

> **Este documento é o resultado do script**  
> [`estrutura/codigo/09-metodos-suavizacao.R`](https://github.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/blob/main/estrutura/codigo/09-metodos-suavizacao.R) (e cópia em [`estrutura/scriptsR/09-metodos-suavizacao.R`](https://github.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/blob/main/estrutura/scriptsR/09-metodos-suavizacao.R)).  
> O script produz os cálculos e figuras; este consolidado é a leitura analítica e aprofundada dos resultados para a nossa pesquisa sobre o IPDM na Baixada Santista.

> **Alvo ($Y$):** `mortalidade_60_69` (Taxa de mortalidade de 60 a 69 anos, por mil habitantes).  
> **Preditor principal ($X_1$):** `riqueza` (Índice de Riqueza IPDM, 0 a 1) — maior correlação socioeconômica válida ($r = -0,393$).  
> **Preditor temporal complementar:** `ano` (2014 a 2024).  
> **Linha de base (MQO Linear):** CV(5) MSE = 13,4295 (RMSE = 3,6646 mortes por mil hab.).

---

## 1. Contexto: A Virada do Paramétrico para o Não-Paramétrico

Nos Blocos I e II do curso (Aulas 01 a 08), todos os modelos ajustados tinham uma **forma funcional rígida pré-estabelecida**:
- Uma reta linear: $y = \beta_0 + \beta_1 x$ (Aula 04);
- Uma curva logística em S: $\mathrm{logit}(p) = X\beta$ (Aula 05);
- Polinômios globais: $y = \beta_0 + \beta_1 x + \dots + \beta_d x^d$ (Aulas 06 e 07);
- Penalizações para frear coeficientes: Ridge e Lasso (Aula 08).

Na **Aula 09**, viramos a chave metodológica: entramos nos **modelos não-paramétricos (suavizadores)**. Aqui, **não supomos uma fórmula matemática a priori**. Em vez disso, assumimos apenas que a função subjacente $f(x)$ é suave — ou seja, municípios com níveis socioeconômicos parecidos devem apresentar taxas de mortalidade parecidas.

Para prever a resposta em um ponto $x_0$, o princípio intuitivo é:
> *"Quanto deve ser a mortalidade em um município com riqueza $0,45$? Olhe os municípios com riqueza parecida e tire a média."*

A aula formaliza duas maneiras complementares de calcular essa média local:
1. **KNN-regressão ($k$-Nearest Neighbours):** Define a vizinhança pelos $k$ pontos mais próximos e atribui peso igual ($1/k$) a todos eles.
2. **Kernel Smoothing (Nadaraya-Watson):** Todos os dados participam da predição, mas ponderados por um núcleo gaussiano (sino de largura $h$) que decai exponencialmente com a distância quadrática.

| Critério | KNN-regressão | Kernel Nadaraya-Watson |
|---|---|---|
| **Quem entra na conta?** | Os $k$ mais próximos | Todas as observações da amostra |
| **Distribuição de pesos** | Peso uniforme ($1/k$) | Peso decrescente dado pelo sino gaussiano |
| **Largura da janela** | **Adaptativa:** alarga onde os dados rareiam | **Fixa ($h$):** constante em todo o domínio |
| **Aspecto da curva** | Em degraus (serrilhada para $k$ pequeno) | Contínua e infinitamente diferenciável |
| **Botão de flexibilidade** | $k$ (número de vizinhos) | $h$ (largura de banda da janela) |
| **Sentido da rigidez** | $k$ maior $\implies$ mais rígido (mais viés) | $h$ maior $\implies$ mais rígido (mais viés) |

---

## 2. O Laboratório no Banco de Dados (IPDM Baixada Santista)

Conforme a orientação do slide 26 da Aula 09:
> *"Troque x1 e y pelo preditor numérico mais importante e pela resposta do seu banco. Reta, KNN e kernel, pelas mesmas dobras... Entregar: a figura com o melhor h; o k e o h escolhidos; o erro de CV da reta, do KNN e do kernel; e uma frase dizendo onde a relação não é uma reta — e, se for, fique com a reta."*

Aplicamos exatamente o protocolo às 54 observações da Baixada Santista (9 municípios ao longo de 6 anos), utilizando a mesma semente (`set.seed(1)`) e as mesmas 5 dobras para garantir comparabilidade absoluta.

### Resultados da Validação Cruzada (5 Dobras)

| Modelo | Parâmetro Escolhido | Flexibilidade / Estrutura | CV(5) MSE | CV(5) RMSE | Redução do Erro vs Reta |
|---|---|---|---|---|---|
| **Reta (MQO)** | — (paramétrico) | Rígido global | **13,4295** | 3,6646 | *Linha de base (0,0%)* |
| **KNN-regressão** | **$k = 20$** vizinhos | Média local uniforme | **12,5767** | 3,5464 | **-6,35%** |
| **Kernel Smoothing** | **$h = 0,0070$** ($0,10 \times \mathrm{sd}$) | Média ponderada gaussiana | **12,4573** | 3,5295 | **-7,24%** |

#### Grade de Busca de $k$ (KNN):
- $k = 3$: $\mathrm{MSE} = 14,9243$ (alta variância, serrilha seguindo ruídos locais);
- $k = 5$: $\mathrm{MSE} = 12,7052$;
- $k = 10$: $\mathrm{MSE} = 12,9605$;
- **$k = 20$**: **$\mathrm{MSE} = 12,5767$** $\leftarrow$ **Mínimo global de CV**;
- $k = 40$: $\mathrm{MSE} = 14,6372$ (alto viés, quase a média global).

#### Grade de Busca de $h$ (Kernel):
- $h = 0,0035$ ($0,05 \times \mathrm{sd}$): $\mathrm{MSE} = 14,0373$ (janela estreita, excesso de oscilação local);
- **$h = 0,0070$** ($0,10 \times \mathrm{sd}$): **$\mathrm{MSE} = 12,4573$** $\leftarrow$ **Melhor $h$ absoluto**;
- $h = 0,0140$ ($0,20 \times \mathrm{sd}$): $\mathrm{MSE} = 12,9854$;
- $h = 0,0280$ ($0,40 \times \mathrm{sd}$): $\mathrm{MSE} = 12,8697$ (sino largo, achatando inflexões).

---

## 3. Frase de Diagnóstico da Relação (Requisito da Entrega)

> **Frase de diagnóstico:**  
> *"A relação entre Riqueza e Mortalidade 60–69 anos na Baixada Santista **não é puramente uma reta**. Ela exibe um patamar elevado e achatado de mortalidade em municípios de riqueza baixa/média (índice 0,35 a 0,42 — Mongaguá, Peruíbe, Itanhaém e São Vicente, com taxas frequentemente entre 20 e 28 por mil), uma queda substancial em direção a Santos (riqueza ~0,50 e mortalidade abaixo de 15 por mil), mas sofre uma **inflexão local acentuada em Cubatão**, onde a riqueza é elevada (~0,51), mas a mortalidade repica para 18–21 por mil devido a fatores industriais e ambientais históricos. Por capturar esse platô e esse repique intermediário sem impor inclinação constante, o Kernel com $h = 0,0070$ supera a reta paramétrica em validação cruzada (MSE 12,46 contra 13,43, eliminando 7,2% do erro)."*

---

## 4. Análise das Figuras e Relevância para a Pesquisa

### Figura 1: Ajuste Não-Paramétrico no Banco Real (O Gráfico da Entrega)
![Ajuste Não-Paramétrico](https://raw.githubusercontent.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/main/estrutura/scriptsR/figuras/09-metodos-suavizacao_img1.png)
*(Arquivo local: `estrutura/scriptsR/figuras/09-metodos-suavizacao_img1.png`)*

- **A Reta Paramétrica (cinza tracejada):** Traça uma linha descendente uniforme ($y = 29,26 - 21,64 x$). Ela subestima a mortalidade nos municípios mais vulneráveis (Mongaguá e Peruíbe) e superestima a mortalidade em Santos, sem qualquer capacidade de detectar peculiaridades municipais.
- **O KNN com $k=20$ (linha roxa):** Cria degraus locais. Consegue notar que entre $0,35$ e $0,42$ a mortalidade é sistematicamente mais alta, mas sofre com descontinuidades abruptas onde observações entram e saem da janela.
- **O Kernel Nadaraya-Watson com $h = 0,0070$ (linha verde grossa):** É o estimador ideal. Ele produz uma curva suave contínua que abraça a densidade da Baixada:
  1. Identifica o patamar crítico de mortalidade em Itanhaém e Mongaguá;
  2. Desce suavemente em direção aos municípios mais estruturados;
  3. Evita oscilações espúrias nas pontas, mantendo equilíbrio perfeito entre viés e variância.

---

### Figura 2: Curvas em U de Validação Cruzada (O Trade-off Viés-Variância Espelhado)
![Curvas de Validação Cruzada](https://raw.githubusercontent.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/main/estrutura/scriptsR/figuras/09-metodos-suavizacao_img2.png)
*(Arquivo local: `estrutura/scriptsR/figuras/09-metodos-suavizacao_img2.png`)*

Conforme ensinado nos slides 13 e 15 da Aula 09:
- O eixo $x$ representa o botão de flexibilidade em escala logarítmica.
- **Aqui, a flexibilidade cresce para a ESQUERDA:**
  - Valores baixos de $k$ ou $h$ (à esquerda) representam modelos hiperflexíveis, dominados pela **variância** (o modelo persegue o ruído individual de cada ponto);
  - Valores altos de $k$ ou $h$ (à direita) representam modelos excessivamente rígidos, dominados pelo **viés** (o modelo degenera na média global);
  - O ponto de fundo da curva em U marca a complexidade ótima: $k = 20$ e $h = 0,0070$. Ambos batem a reta paramétrica (linha horizontal tracejada).

---

### Figura 3: O Dilema de Ajuste (Treme vs Achata)
![Efeito do Botão de Flexibilidade](https://raw.githubusercontent.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/main/estrutura/scriptsR/figuras/09-metodos-suavizacao_img3.png)
*(Arquivo local: `estrutura/scriptsR/figuras/09-metodos-suavizacao_img3.png`)*

- **Painel Esquerdo (Kernel):** Com $h = 0,0035$ ($0,05 \times \mathrm{sd}$), o sino é tão estreito que a curva "treme" para capturar cada observação individual (overfitting local). Com $h = 0,0280$ ($0,40 \times \mathrm{sd}$), o sino é largo demais e achata o relevo real da distribuição.
- **Painel Direito (KNN):** Com $k = 3$, vemos o clássico aspecto "serrilhado", com saltos bruscos a cada ponto. Com $k = 40$, quase dois terços da amostra entram na janela, transformando o preditor num patamar estático.

---

### Figura 4: A Dinâmica Temporal — Onde a Reta Falha Catastroficamente
![Dinâmica Temporal](https://raw.githubusercontent.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/main/estrutura/scriptsR/figuras/09-metodos-suavizacao_img4.png)
*(Arquivo local: `estrutura/scriptsR/figuras/09-metodos-suavizacao_img4.png`)*

Na nossa Pergunta 1 de pesquisa (`09-escolha-da-pergunta.md`), documentamos que o tempo (`ano`) exerce um papel determinante sobre a mortalidade de idosos devido ao **choque sanitário da COVID-19**.
- Se tentarmos ajustar uma **reta paramétrica** para `ano`, o MSE de validação cruzada é desastroso (**$16,12$**), pois uma reta assume que a mortalidade sobe ou desce de forma monótona para sempre.
- O **Kernel Nadaraya-Watson** com banda temporal $h = 0,86$ anos atinge **$\mathrm{MSE} = 10,83$** (redução de 32,8% do erro!), capturando com perfeição o ciclo epidemiológico real:
  - Estabilidade relativa entre 2014 e 2018 (~17 a 18 mortes por mil);
  - Explosão não-linear no biênio pandêmico 2020–2022 (pico superior a 25 mortes por mil);
  - Recuperação expressiva e queda acentuada em 2024 (~14 a 16 mortes por mil).
Este resultado ilustra com clareza o poder dos métodos não-paramétricos: **descobrir a anatomia do fenômeno sem forçar uma hipótese funcional falsa**.

---

## 5. Diagnóstico de `NaN` no Kernel e Como Evitá-lo

O slide 26 alerta:
> *"Deu NaN no kernel? É a janela fixa sem vizinhos: aumente h."*

### Por que o `NaN` ocorre matematicamente?
A fórmula de Nadaraya-Watson calcula a predição como uma razão ponderada, onde $K_h(x_0, x_i) = \exp\left(-\frac{1}{2}\left(\frac{x_i - x_0}{h}\right)^2\right)$:

$$
\hat{f}(x_0) = \frac{\sum_{i=1}^n K_h(x_0, x_i) y_i}{\sum_{i=1}^n K_h(x_0, x_i)}
$$

Se a largura de banda $h$ for pequena demais e tentarmos prever em um ponto $x_0$ situado em uma região esparsa (por exemplo, na transição entre $0,45$ e $0,50$ onde há poucos municípios, ou além de $0,58$ na borda superior):
1. A distância $\lvert x_i - x_0\rvert / h$ ultrapassa 4 ou 5 desvios para todas as observações $i = 1, \dots, n$;
2. A densidade normal sob o ponto flutuante do computador atinge zero exato (`dnorm() == 0`);
3. O denominador vira zero: $\sum_{i=1}^n K_h(x_0, x_i) = 0$;
4. A fração torna-se $0 / 0 = \mathrm{NaN}$.

### Como o problema foi tratado no script?
- Na grade de busca, utilizamos múltiplos de $\mathrm{sd}(x)$: $h \in [0,05 \times \mathrm{sd}, 0,40 \times \mathrm{sd}]$.
- Em $h = 0,05 \times \mathrm{sd} = 0,0035$, todas as dobras mantiveram densidade suficiente para evitar `NaN`.
- O $h$ ótimo de CV ($h = 0,0070 = 0,10 \times \mathrm{sd}$) garante que, para qualquer ponto da Baixada Santista, haja pelo menos 8 a 15 municípios com peso superior a 1%, eliminando completamente o risco de indefinição numérica.

---

## 6. Resolução Completa dos Exercícios da Aula 09

Para fundamentação teórica completa do grupo, resolvemos formalmente todos os exercícios dos slides 24 e 25 da aula.

### Parte A: Exercícios de Cálculo (Slide 24)

#### Exercício 1: KNN com Vários $k$
*Enunciado:* Sete imóveis: áreas $(50, 55, 62, 70, 80, 96, 110)$ e preços $(150, 170, 160, 210, 230, 300, 320)$. Preveja o preço de um imóvel de $74\ \mathrm{m}^2$ por KNN com $k = 1, 3, 5, 7$. Para onde a predição caminha quando $k$ cresce?

*Resolução:*
1. Distâncias até $x_0 = 74$:
   - $\lvert 70 - 74\rvert = 4$ (preço 210)
   - $\lvert 80 - 74\rvert = 6$ (preço 230)
   - $\lvert 62 - 74\rvert = 12$ (preço 160)
   - $\lvert 55 - 74\rvert = 19$ (preço 170)
   - $\lvert 96 - 74\rvert = 22$ (preço 300)
   - $\lvert 50 - 74\rvert = 24$ (preço 150)
   - $\lvert 110 - 74\rvert = 36$ (preço 320)
2. Predições:
   - **$k = 1$:** Vizinhança $\lbrace 70 \rbrace \implies \hat{y} = \mathbf{210,0}$
   - **$k = 3$:** Vizinhança $\lbrace 70, 80, 62 \rbrace \implies \hat{y} = \frac{210 + 230 + 160}{3} = \mathbf{200,0}$
   - **$k = 5$:** Vizinhança $\lbrace 70, 80, 62, 55, 96 \rbrace \implies \hat{y} = \frac{210 + 230 + 160 + 170 + 300}{5} = \mathbf{214,0}$
   - **$k = 7$:** Todas as 7 observações $\implies \hat{y} = \frac{150+170+160+210+230+300+320}{7} = \mathbf{220,0}$
3. *Comportamento:* Quando $k$ cresce, a predição caminha monotonicamente para a **média global da amostra** ($\bar{y} = 220$). O modelo perde flexibilidade local e aumenta o viés, reduzindo a variância a zero.

---

#### Exercício 2: Kernel Nadaraya-Watson com $h = 10$ e $h = 3$
*Enunciado:* Com os imóveis $(62, 160), (70, 210), (80, 230), (96, 300)$ e o núcleo gaussiano em $x_0 = 74$: calcule os pesos para $h = 10$, normalize e obtenha a predição. Repita com $h = 3$: quem ainda pesa?

*Resolução:*
- **Caso $h = 10$:**
  - $z_i = (x_i - 74)/10$: $z = (-1,2; -0,4; +0,6; +2,2)$
  - Pesos gaussianos $w_i = \phi(z_i)$: $w = (0,19419; \, 0,36827; \, 0,33322; \, 0,03547)$; soma $= 0,93115$
  - Pesos normalizados $\tilde{w}_i$: **$20,85\%$** (62), **$39,55\%$** (70), **$35,79\%$** (80), **$3,81\%$** (96)
  - Predição: $\hat{f}(74) = 0,2085(160) + 0,3955(210) + 0,3579(230) + 0,0381(300) = \mathbf{210,16}$
- **Caso $h = 3$:**
  - $z_i = (x_i - 74)/3$: $z = (-4,0; -1,333; +2,0; +7,333)$
  - Pesos gaussianos: $w = (0,00013; \, 0,16401; \, 0,05399; \, 0,00000)$; soma $= 0,21813$
  - Pesos normalizados: **$0,06\%$** (62), **$75,19\%$** (70), **$24,75\%$** (80), **$0,00\%$** (96)
  - Predição: $\hat{f}(74) = 0,7519(210) + 0,2475(230) = \mathbf{214,92}$
  - *Quem ainda pesa?* Praticamente **apenas os vizinhos imediatos 70 (75,2%) e 80 (24,8%)**. O ponto 62 está a 4 bandas de distância e seu peso colapsa para 0,06%; o ponto 96 está a mais de 7 bandas e seu peso é zero.

---

#### Exercício 3: Regra de 1 Erro-Padrão no KNN
*Enunciado:* Validação cruzada deu: $k=2 \implies 1300$; $k=5 \implies 950$; $k=10 \implies 900$; $k=20 \implies 940$; $k=50 \implies 1500$. Qual $k$ minimiza? Com erro padrão 60 no fundo, qual $k$ a regra de 1 SE escolhe — e por que aqui "mais simples" é $k$ maior?

*Resolução:*
1. $k$ que minimiza o erro médio: **$k = 10$** com $\mathrm{CV} = 900$.
2. Limite da regra de 1 SE: $\mathrm{CV}_{\mathrm{min}} + \mathrm{SE} = 900 + 60 = \mathbf{960}$.
3. Modelos com erro dentro do intervalo $[900, 960]$: $k = 5$ (950), $k = 10$ (900) e $k = 20$ (940).
4. *Escolha da regra:* A regra de 1 SE escolhe o **modelo mais parcimonioso/simples**. No KNN, quanto maior o $k$, menor é o número de graus de liberdade efetivos ($\mathrm{df} \approx n/k$) e menor é a variância. Logo, o modelo mais simples e rígido é aquele com o **maior $k$**. A regra escolhe **$k = 20$**.

---

#### Exercício 4: Maldição da Dimensionalidade
*Enunciado:* Com $p = 3$ e $p = 8$ preditores, que lado precisa ter a vizinhança cúbica que captura 10% dos dados uniformes em $[0,1]^p$? E quantas observações mantêm 10 vizinhos numa caixa de lado 0,1 quando $p = 4$?

*Resolução:*
1. O volume de uma caixa de lado $l$ em $p$ dimensões é $V = l^p$. Para capturar $10\%$ do volume ($V = 0,10$), o lado deve ser $l = 0,10^{1/p}$:
   - Para $p = 3$: $l = 0,10^{1/3} = \mathbf{0,4642}$ (a vizinhança precisa cobrir $46,4\%$ de cada dimensão).
   - Para $p = 8$: $l = 0,10^{1/8} = \mathbf{0,7499}$ (precisa cobrir $75,0\%$ de cada dimensão — quase o domínio inteiro!).
2. Para uma caixa fixa de lado $l = 0,10$ em $p = 4$:
   - O volume da caixa é $V = 0,1^4 = 0,0001$ ($1/10.000$ do espaço total).
   - Para que essa fração minúscula contenha em média 10 observações uniformes, a base precisa ter $n \approx \frac{10}{0,1^4} = 10 \times 10.000 = \mathbf{100.000}$ **observações**.

---

### Parte B: Exercícios Conceituais (Slide 25)

#### 1. $k$ e a Flexibilidade
- **Por que $k$ pequeno é flexível?** Quando $k$ é pequeno (ex.: $k=1$ ou $k=3$), a predição depende exclusivamente de um ou pouquíssimos vizinhos. Qualquer flutuação aleatória ou ruído amostral desses vizinhos altera diretamente o valor previsto. Isso confere **altíssima variância** e **baixo viés**, resultando em uma curva que "serrilha" e sobreajusta os dados de treino.
- **Qual é o KNN mais rígido possível e o que prevê?** É o modelo com $k = n$ (onde $n$ é o total de observações). Ele prevê a **média aritmética global da amostra** ($\bar{y}$) para qualquer ponto do espaço preditor, com variância nula entre previsões e máximo viés estrutural.

#### 2. O Problema da Borda
- **Por que a média local erra nas bordas em uma relação crescente?** Em pontos centrais de uma rampa crescente, $x_0$ possui vizinhos à esquerda (que puxam a média para baixo) e vizinhos à direita (que puxam para cima), que se compensam mutuamente. Na borda inferior (extrema esquerda), só existem vizinhos à direita (valores maiores de $y$), superestimando a resposta. Na borda superior (extrema direita), só existem vizinhos à esquerda (valores menores de $y$), subestimando a resposta.
- **Trocar KNN por Kernel resolve?** **Não.** O Kernel também calcula uma média local ponderada. Mesmo com pesos que decaem suavemente, se todos os vizinhos disponíveis estão de um só lado da rampa, a média ponderada continuará achatando a tendência nas pontas.
- **O que resolveria?** Trocar a média local por uma **regressão linear local** ajustada em cada vizinhança (como o estimador **LOESS** / `geom_smooth()` / `lowess`) ou modelos de **Splines de regressão** (Aula 10), que conseguem extrapolar a inclinação até os limites do domínio.

#### 3. Qual Modelo Responde? (Interpretabilidade vs Extrapolação)
- **"O efeito marginal de $+1\ \mathrm{m}^2$ no preço":** O método adequado é a **reta linear paramétrica (MQO da Aula 04)**. O coeficiente $\beta_1$ resume exatamente a taxa marginal constante em um único parâmetro com intervalo de confiança e teste de hipótese. Modelos de Kernel produzem derivadas locais variáveis a cada ponto, sem um único número de resumo executivo.
- **"O preço de um imóvel de $300\ \mathrm{m}^2$, maior que todos da base":** O Kernel é completamente inadequado para extrapolação fora do suporte dos dados: longe de todos os pontos conhecidos, os pesos gaussianos chegam a zero e o modelo devolve `NaN` ou achata artificialmente. A reta paramétrica consegue extrapolar matematicamente ao longo de sua fórmula (embora com risco de extrapolação conceitual).

#### 4. Muitos Preditores (A Maldição na Prática)
- **Por que o colega com 40 preditores falhou no KNN?** Em 40 dimensões, o espaço hiperdimensional é incomensuravelmente vasto e vazio. Conforme vimos na conta da maldição ($l = 0,1^{1/40} \approx 0,944$), para encontrar qualquer vizinho é necessário cobrir praticamente $95\%$ de cada variável. Os pontos tornam-se todos equidistantes entre si, perdendo o conceito de vizinhança local; o KNN degenera em uma média global ruidosa.
- **Dois caminhos de solução:**
  1. **Seleção e Regularização (Aula 08):** Aplicar o **Lasso ($L_1$)** para zerar preditores redundantes/irrelevantes, reduzindo drasticamente a dimensionalidade efetiva de 40 para apenas 2 a 4 variáveis dominantes antes de suavizar.
  2. **Modelos Aditivos Generalizados - GAM (Aula 10):** Decompor o problema multidimensional na soma de suavizadores unidimensionais independentes: $y = \beta_0 + f_1(x_1) + f_2(x_2) + \dots + f_p(x_p)$, evitando a maldição do produto tensorial de vizinhanças.

---

## 7. Conexão com o Bloco III e Próximos Passos

A Atividade 09 marca com sucesso a inauguração do **Bloco III (Modelos Flexíveis)** em nosso projeto:
1. Comprovamos empiricamente que as taxas de mortalidade na Baixada Santista possuem não-linearidades reais que a reta de MQO é incapaz de capturar;
2. Tanto o KNN ($k=20$) quanto o Kernel de Nadaraya-Watson ($h=0,0070$) reduziram o erro de validação cruzada em relação ao MQO;
3. O Kernel smoothing superou todos os métodos ao oferecer uma curva diferenciável e clinicamente plausível, destacando o impacto do parque industrial de Cubatão e o choque pandêmico de 2020–2022.

Na **Aula 10**, levaremos esses suavizadores para o próximo patamar técnico através de **Splines Cúbicos** (que corrigem as distorções de borda) e **Modelos Aditivos Generalizados (GAM)** (que combinam múltiplos preditores sem sucumbir à maldição da dimensionalidade).
