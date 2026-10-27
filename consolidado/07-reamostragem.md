# Atividade 07 — Reamostragem: quando o dado é pequeno, olhamos para ele muitas vezes

> **Este documento é o resultado do script**
> [`estrutura/scriptsR/07-reamostragem.R`](https://github.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/blob/main/estrutura/scriptsR/07-reamostragem.R).
> O script produz os números; este consolidado é a leitura humana deles —
> com o porquê das decisões e o que aprender com cada resultado.

> **Alvo:** `mortalidade_60_69`. Predictor: `escolaridade`.  
> **Baseline herdado:** RMSE = 3,8504 (sd de Y).

## O problema quando o dado é pequeno

Temos 54 observações. Isso não é pouco no sentido absoluto — mas é pouco para um problema com sinal fraco, como os anteriores já mostraram. Com poucos dados, duas coisas ficam instáveis:

1. **As estimativas pontuais** — um coeficiente calculado em 54 pontos pode ser bem diferente se tivéssemos outros 54.
2. **As métricas de avaliação** — RMSE de treino/teste muda de split para split, como vimos na atividade 05.

A **reamostragem** é um conjunto de técnicas que ataca exatamente isso. Em vez de fingir que sabemos mais do que sabemos, olhamos para os dados repetidas vezes, de formas ligeiramente diferentes, e observamos como as conclusões se movem.

Esta atividade usa duas dessas técnicas:

- **Validação cruzada** (já nossa conhecida) — mas agora com **polinômios de graus diferentes**, para sondar não-linearidades.
- **Bootstrap** — uma abordagem diferente, que reamostra os dados com reposição e usa isso para estimar a incerteza dos coeficientes sem hipóteses de normalidade.

As duas respondem perguntas ligeiramente diferentes, mas compartilham o mesmo espírito: **não confie em uma única amostra**.

---

## Parte 1 — CV(5) com três graus de polinômio

### A pergunta

Na atividade 05, vimos que a escolaridade não tem poder preditivo linear. Mas e se a relação for **curva**? Mais anos de estudo podem proteger muito no começo e ter retorno decrescente depois? Ou o contrário?

Para testar essa hipótese, ajustamos polinômios de graus crescentes:

- **Grau 1:** reta (o modelo de sempre).
- **Grau 3:** curva cúbica, flexível.
- **Grau 12:** curva extremamente flexível — teoricamente capaz de passar por qualquer ponto.

Se existisse uma relação não-linear, o grau 3 deveria capturá-la e ganhar do grau 1. E o grau 12, se o problema fosse complexidade, deveria ganhar de todos. Vamos ver.

### O resultado

| Candidato | RMSE_CV |
|---|---|
| Grau 1 | **3,8945** |
| Grau 3 | 3,9420 |
| Grau 12 | **239,9973** |
| Baseline (sd Y) | 3,8504 |

Leia essa tabela devagar, porque ela tem um desastre didático embutido.

**Grau 1:** RMSE 3,89. Praticamente igual ao baseline (3,85). Sem novidade.

**Grau 3:** RMSE 3,94. Pior que o grau 1. A flexibilidade adicional **não ajudou** — e ainda custou um pouco. Ou seja, a curva cúbica não capturou nenhum padrão que a reta não capturasse; só adicionou ruído.

**Grau 12:** RMSE **240**. Esse número merece um parágrafo inteiro.

### O colapso do grau 12 — overfitting em estado bruto

Um RMSE de 240 é catastrófico. Compare com sd(Y) = 3,85: o modelo erra **62 vezes** mais que simplesmente dizer a média. Isso não é apenas ruim; é absurdo.

O que aconteceu? **Overfitting clássico.**

Um polinômio de grau 12 tem 13 coeficientes (12 graus + intercepto). Com apenas ~43 observações de treino por dobra (4/5 de 54), o modelo tem liberdade suficiente para passar **exatamente por todos os pontos de treino**. Ele "decora" os dados.

Quando confrontado com a dobra de teste — que ele nunca viu —, suas previsões **explodem**. Pequenas variações na escolaridade produzem previsões que disparam para valores absurdos, porque o polinômio está extrapolando violentamente entre pontos.

Podemos ver isso na tabela de erros por dobra:

| Dobra | Grau 1 | Grau 3 | Grau 12 |
|---|---|---|---|
| 1 | 2,91 | 2,98 | **3,10** |
| 2 | 3,99 | 4,06 | **16,79** |
| 3 | 4,48 | 4,48 | **4,01** |
| 4 | 4,84 | 4,78 | **5,22** |
| 5 | 2,81 | 3,07 | **536,34** |

Nas dobras 1, 3 e 4, o grau 12 até se comporta — o erro fica próximo dos outros. Mas na **dobra 2** dispara para 16,79, e na **dobra 5** explode para **536,34**.

O que aconteceu na dobra 5? Muito provavelmente, essa dobra continha um ponto extremo (talvez Mongaguá 2022, com mortalidade 33, ou Santos com escolaridade alta). O polinômio de grau 12 treinado sem aquele ponto criou uma oscilação enorme justamente ali. Na hora de prever, o modelo devolveu um número astronômico.

**Esta é a lição central da CV com polinômios:** a média de RMSE é enganosa porque é dominada por um único caso extremo. Aqui, o RMSE "médio" do grau 12 (240) é praticamente o erro da dobra 5 (536, ao quadrado, contribuindo sozinha com quase tudo).

Se você olhasse apenas a média de acurácia, diria "grau 12 é péssimo". Se olhasse a tabela por dobra, veria uma história mais matizada: em 3 das 5 dobras, grau 12 foi competitivo; em 1, foi desastroso; em outra, catastrófico. A instabilidade é o problema — não a média.

### O que aprendemos

1. **Não há sinal não-linear detectável.** Grau 3 perdeu para grau 1. Se houvesse curvatura, ela teria aparecido.
2. **Complexidade sem dados é veneno.** Grau 12 é o exemplo definitivo.
3. **CV captura overfitting.** Se tivéssemos avaliado o grau 12 no treino, ele pareceria ótimo. Na CV, ele explode.

---

## Parte 2 — Bootstrap do coeficiente β₁

### A pergunta

Na atividade 03, calculamos o IC 95% de β₁ usando a fórmula analítica clássica. Mas essa fórmula **assume normalidade dos resíduos** — e o teste de Shapiro rejeitou essa hipótese (p = 0,009).

E agora? Como estimar a incerteza de β₁ sem depender dessa hipótese?

A resposta é o **bootstrap não-paramétrico**.

### Como funciona o bootstrap

A ideia é engenhosamente simples:

1. **Sorteie com reposição** 54 observações dos seus próprios 54 dados.
2. Ajuste o modelo na amostra sorteada. Guarde β₁.
3. **Repita 2.000 vezes.**
4. Olhe a distribuição dos 2.000 β₁'s.

O que estamos fazendo é simular: "se eu tivesse 2.000 conjuntos de dados parecidos com o meu, como o coeficiente variaria?". Como não temos esses dados, inventamos a partir do que temos — por isso "reamostragem".

O ponto sutil: cada sorteio inclui umas observações duplicadas e deixa outras de fora. Isso **imita** a variabilidade de uma amostra aleatória. É uma simulação honesta, sem pressupostos sobre a forma da distribuição.

### O resultado

| Métrica | Valor |
|---|---|
| β₁ MQO (dados originais) | −2,0959 |
| EP analítico | 8,5337 |
| EP bootstrap | **7,9221** |
| IC 95% analítico | [−19,2201; 15,0283] |
| IC 95% bootstrap | [−18,8741; **11,8109**] |
| **0 dentro do IC bootstrap?** | **SIM** |

Vamos por partes.

**O EP bootstrap ficou próximo do analítico** (7,92 vs 8,53). Isso não é coincidência — quando a distribuição é razoavelmente bem comportada, os dois métodos concordam. É uma validação cruzada metodológica: se os dois discordassem muito, teríamos razões para desconfiar de um dos dois.

**O IC bootstrap é ligeiramente assimétrico.** Limite inferior −18,87, limite superior +11,81. O centro implícito é ≈ −3,5, próximo do β₁ pontual (−2,10), mas não exatamente. Essa assimetria é o eco da assimetria do alvo: o bootstrap **captura** essa forma, o analítico **impõe** normalidade.

**Compare os dois ICs:**

- Analítico: [−19,22; 15,03]
- Bootstrap: [−18,87; 11,81]

Eles são parecidos na parte inferior, mas o bootstrap é mais **estreito** na superior. Ou seja, o IC analítico estava **inflando** a incerteza do lado positivo. Isso acontece justamente porque a normalidade forçada produz caudas simétricas, enquanto a distribuição real do β₁ é levemente assimétrica.

**Conclusão comum a ambos:** o intervalo contém zero. Portanto, em ambos os métodos, **não podemos descartar a hipótese de que escolaridade não afeta mortalidade**.

### Por que o bootstrap importa

O bootstrap é uma ferramenta moderna e versátil. Ele:

- **Não exige normalidade.** Funciona com distribuições assimétricas, com outliers, com o que for.
- **Funciona com n pequeno.** 54 observações são suficientes para o bootstrap rodar bem.
- **É flexível.** A mesma técnica serve para estimar o IC de qualquer estatística (mediana, razão de chances, AUC — qualquer coisa).

A contrapartida é o custo computacional. Rodar 2.000 regressões toma alguns segundos; a fórmula analítica é instantânea. Mas, com o poder de cálculo atual, isso é uma falsa objeção.

---

## As duas figuras

### Figura 1 — 6 splits avulsos vs. CV(5)

![Comparação entre 6 divisões treino/teste aleatórias e o erro da CV(5), por grau polinomial](https://raw.githubusercontent.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/main/estrutura/scriptsR/figuras/07-reamostragem_img1.png)

O gráfico mostra duas camadas de informação:

- **Linhas cinzas finas (6 no total):** cada uma é uma divisão treino/teste avulsa, com erro calculado por grau polinomial. Elas se espalham verticalmente — refletindo que cada split produz um RMSE diferente.
- **Linha roxa grossa:** o RMSE médio da CV(5) para cada grau.

O eixo X tem os graus 1, 3 e 12. O eixo Y é o RMSE.

O que observar:

1. **Para grau 1 e 3, as linhas cinzas estão apertadas.** Os splits concordam entre si. A CV(5) cai no meio. Bom sinal de estabilidade.
2. **Para grau 12, as linhas cinzas se espalham enormemente.** Um split dá RMSE de ~3; outro dá RMSE de centenas. É o retrato visual da instabilidade do overfitting.
3. **A linha roxa da CV(5) sobe de grau 1 para grau 3 e explode no grau 12.** Confirma os números da tabela: complexidade não ajuda.

A lição visual é imediata: **quando as linhas cinzas ficam paralelas e apertadas, a CV está fazendo um bom trabalho. Quando elas se espalham, o modelo é instável — e a CV não esconde isso, ela mostra**.

### Figura 2 — Distribuição bootstrap de β₁

![Histograma dos 2.000 valores de β₁ reamostrados](https://raw.githubusercontent.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/main/estrutura/scriptsR/figuras/07-reamostragem_img2.png)

O histograma mostra os 2.000 β₁'s gerados pelo bootstrap. Três linhas verticais de referência:

- **Linha roxa:** β₁ pontual (−2,10).
- **Linhas laranjas tracejadas:** limites do IC 95% bootstrap (−18,87 e +11,81).
- **Zero** está entre as duas laranjas — visível a olho nu, mas também confirmado numericamente.

O que observar:

1. **A distribuição é larga.** Os β₁'s variam de aproximadamente −30 a +20. Isso é a incerteza do coeficiente inteira em uma imagem.
2. **É centrada perto de zero.** Não há "pico" deslocado para um lado ou para o outro — o coeficiente flutua ao redor do "sem efeito".
3. **É levemente assimétrica.** A cauda esquerda desce mais suavemente que a direita. Isso é o que o IC analítico não capta.
4. **A linha roxa está bem dentro da distribuição.** O β₁ pontual não está no extremo — está no meio de onde mais da metade das reamostragens produziu valores.

Comparar essa figura com a figura 4 da atividade 03 é revelador: são quase idênticas, porque ambos os bootstraps (o de lá e o de cá) usaram a mesma técnica. Aqui, a diferença é que estamos olhando essa figura **em contexto** — depois de ver a CV confirmar o mesmo veredito.

---

## Síntese: o que esta atividade ensina

Quatro conclusões.

**Primeira: não-linearidades não ajudam neste recorte.** Grau 3 perde para grau 1. Se existisse curvatura, ela apareceria. Não aparece.

**Segunda: complexidade + pouco dado = overfitting catastrófico.** O grau 12 é o exemplo definitivo. RMSE de 240 contra um baseline de 3,85. Não é "um pouco pior" — é um desastre. A CV flagrou isso, e a figura 1 mostra visualmente o porquê.

**Terceira: bootstrap confirma o IC analítico — mas com nuance.** O EP bootstrap (7,92) é próximo do analítico (8,53). Os dois ICs contêm zero. Mas o bootstrap revela uma assimetria que o analítico esconde. Em distribuições não-normais, o bootstrap é mais honesto.

**Quarta: as duas técnicas são complementares.** A CV mede **capacidade preditiva** (quanto o modelo erra em dados novos). O bootstrap mede **incerteza dos coeficientes** (quão confiável é a estimativa). São perguntas diferentes — e vale ter as duas respostas.

O que fica desta atividade:

1. **CV(5) com polinômios:** grau 1 = 3,8945; grau 3 = 3,9420; grau 12 = 239,9973. Baseline: 3,8504.
2. **Grau 12 colapsa** por overfitting: erro na dobra 5 chega a 536,34.
3. **Bootstrap β₁:** EP 7,9221 (vs analítico 8,5337).
4. **IC 95% bootstrap:** [−18,8741; 11,8109] — contém zero.
5. **IC bootstrap é assimétrico** — refletindo a não-normalidade do alvo.
6. **Duas técnicas, dois propósitos:** CV mede previsão, bootstrap mede incerteza.

O caminho está cada vez mais claro. Todas as abordagens até aqui bateram na mesma parede: **o sinal é fraco, o n é pequeno, os modelos complexos sobreajustam**. A atividade 08 fecha o ciclo com uma resposta direta a esse dilema: **regularização** — que encolhe os coeficientes justamente para não deixá-los explodir quando há muitos preditores e pouca evidência.

---

## Fundamentação Matemática e Resolução dos Exercícios (Aula 07)

Para consolidar o rigor teórico da **Aula 07** (`slides_aulas/TAE_aula07.PDF` — *Reamostragem: validação cruzada e bootstrap*), apresentamos as equações formais dos estimadores de reamostragem, a frase síntese exigida no laboratório (slide 20/20) e as soluções dos exercícios dos slides 17–18/20.

### 1. Formulação Matemática da Validação Cruzada $k$-Fold e do Bootstrap

- **Validação Cruzada em $k$ Dobras ($\mathrm{CV}_{(k)}$):** Particiona-se o conjunto de dados $D = \lbrace (x_i, y_i) \rbrace_{i=1}^n$ em $k$ subconjuntos disjuntos $D_1, \dots, D_k$ de tamanhos aproximadamente iguais ($\lvert D_j\rvert \approx n/k$). Para cada dobra $j \in \lbrace 1, \dots, k \rbrace$, ajusta-se o modelo $\hat{f}^{(-j)}$ nos dados restantes $D \setminus D_j$ e calcula-se o erro quadrático médio na dobra retida $D_j$:

$$
\mathrm{MSE}_j = \frac{1}{\lvert D_j\rvert}\sum_{i \in D_j}\left(y_i - \hat{f}^{(-j)}(x_i)\right)^2, \qquad \mathrm{CV}_{(k)} = \frac{1}{k}\sum_{j=1}^{k}\mathrm{MSE}_j
$$

No caso limite $k = n$ (*Leave-One-Out Cross-Validation*, LOOCV), para um ajustador linear $\hat{\mathbf{y}} = \mathbf{H}\mathbf{y}$ com alavancagens $h_{ii} = (\mathbf{H})_{ii}$, vale o atalho algébrico fechado sem reajustar $n$ vezes:

$$
\mathrm{LOOCV} = \frac{1}{n}\sum_{i=1}^{n}\left(\frac{y_i - \hat{y}_i}{1 - h_{ii}}\right)^2
$$

- **Erro-Padrão e Intervalo Percentílico Bootstrap:** Dada uma estatística $\hat{\theta} = s(D)$, geram-se $B$ amostras bootstrap $D^{*(1)}, \dots, D^{*(B)}$ de tamanho $n$ sorteadas **com reposição** de $D$ (em média, cada amostra bootstrap contém $1 - (1 - 1/n)^n \approx 1 - e^{-1} \approx 63{,}2\%$ das observações originais distintas). Calcula-se $\hat{\theta}^{*(b)} = s(D^{*(b)})$ e estima-se o erro-padrão empírico (onde $\bar{\theta}^* = \frac{1}{B}\sum_{b=1}^{B}\hat{\theta}^{*(b)}$):

$$
\mathrm{EP}_{\mathrm{boot}}(\hat{\theta}) = \sqrt{\frac{1}{B - 1}\sum_{b=1}^{B}\left(\hat{\theta}^{*(b)} - \bar{\theta}^*\right)^2}
$$

O intervalo de confiança percentílico de $95\%$ é dado pelos quantis empíricos de ordem $2{,}5\%$ e $97{,}5\%$ de $\lbrace\hat{\theta}^{*(b)}\rbrace_{b=1}^B$: $\mathrm{IC}_{95\%}^{\mathrm{boot}} = \left[q_{0,025}^*;\; q_{0,975}^*\right]$.

- **Frase síntese de entrega do Laboratório (Slide 20/20):**  
  > *"O coeficiente de escolaridade ($\hat{\beta}_1 = -2{,}10$) **não é estatisticamente distinguível de zero**, pois seu intervalo de confiança bootstrap de 95% ($[-18{,}87;\; +11{,}81]$, com $\mathrm{EP}_{\mathrm{boot}} = 7{,}92$) atravessa o zero com ampla folga."*

### 2. Exercícios de Cálculo (Slide 17/20 — Aula 07)

1. **Cálculo direto de $\mathrm{CV}_{(5)}$ e RMSE:**  
   Dados os erros quadráticos médios nas $k = 5$ dobras: $\mathrm{MSE}_j = (940,\; 1120,\; 860,\; 1310,\; 1020)$ (com $y$ em milhares de reais):
   - Média das dobras: $\mathrm{CV}_{(5)} = \frac{940 + 1120 + 860 + 1310 + 1020}{5} = \frac{5.250}{5} = \mathbf{1.050}$ (mil reais ao quadrado).
   - Raiz do erro quadrático médio: $\mathrm{RMSE}_{\mathrm{CV}} = \sqrt{1.050} \approx \mathbf{32{,}40}$ **mil reais**.

2. **Comparação de dois candidatos por $\mathrm{CV}_{(5)}$ (média vs. estabilidade entre dobras):**  
   - **Candidato A:** dobras $(1210,\; 980,\; 1150,\; 1040,\; 1120)$  
     - $\mathrm{CV}_{(5)}(A) = \frac{5.500}{5} = 1.100$, com desvio-padrão entre dobras $s_A = \sqrt{\frac{(110)^2 + (-120)^2 + 50^2 + (-60)^2 + 20^2}{4}} = \sqrt{8.250} \approx \mathbf{90{,}83}$.
   - **Candidato B:** dobras $(1020,\; 1310,\; 760,\; 1440,\; 890)$  
     - $\mathrm{CV}_{(5)}(B) = \frac{5.420}{5} = 1.084$, com desvio-padrão entre dobras $s_B = \sqrt{\frac{(-64)^2 + 226^2 + (-324)^2 + 356^2 + (-194)^2}{4}} = \sqrt{81.130} \approx \mathbf{284{,}83}$.
   - **Quem vence e o que mais chama atenção?** O Candidato B vence por margem mínima na média ($1.084$ contra $1.100$, diferença de $1{,}5\%$), mas apresenta **dispersão entre dobras mais de três vezes maior** ($s_B \approx 284{,}8$ vs. $s_A \approx 90{,}8$). Portanto, A é substancialmente mais estável e previsível fora da amostra, enquanto B sofre de alta variância dependendo da partição.

3. **Leitura de saída de Bootstrap ($B = 1.000$):**  
   Dados $\hat{\theta} = 2{,}4$, $\mathrm{EP}_{\mathrm{boot}} = 0{,}3$ e $\mathrm{IC}_{95\%}^{\mathrm{boot}} = [1{,}85;\; 3{,}02]$:  
   - **Leitura:** Estimamos o parâmetro em $2{,}4$ com incerteza típica de reamostragem de $\pm 0{,}3$; em $95\%$ das amostras bootstrap o parâmetro situou-se entre $1{,}85$ e $3{,}02$.  
   - **O valor $\theta = 0$ é plausível?** **Não.** Como o zero está completamente fora do intervalo $[1{,}85;\; 3{,}02]$ (a mais de $6$ erros-padrão de distância de $\hat{\theta}$), há forte evidência estatística de que $\theta > 0$.

### 3. Exercícios Conceituais (Slide 18/20 — Aula 07)

1. **As duas queixas da divisão única:**  
   A divisão única 70/30 sofre de (i) **alta variância da avaliação** (o MSE de teste muda drasticamente conforme a semente do sorteio, como demonstramos nos 200 splits da Atividade 05) e (ii) **viés pessimista / desperdício de dados** (apenas 70% das observações são usadas para treinar o modelo, o que em bases pequenas como $n = 54$ empobrece o ajuste). A validação cruzada $k$-fold reduz a variância ao promediar o erro sobre $k$ dobras onde cada ponto é testado exatamente uma vez, e reduz o viés pessimista ao treinar cada modelo com $(k-1)/k$ (80% ou 90%) da base.
2. **Escolha do tamanho de $k$ na CV:**  
   - **Se $k$ for muito pequeno (ex.: $k = 2$):** Cada modelo é treinado com apenas metade dos dados ($50\%$), o que superestima o erro de teste real (alto viés pessimista na estimativa do erro).  
   - **Se $k$ for muito grande (ex.: $k = n$, LOOCV):** Os $n$ conjuntos de treinamento compartilham $n - 2$ observações idênticas, tornando os modelos ajustados fortemente correlacionados entre si e exigindo alto custo computacional (além de maior variância na média das $n$ avaliações). Por isso $k = 5$ ou $k = 10$ são o ponto de equilíbrio padrão.
3. **Padronização dentro do laço da CV:**  
   Padronizar as variáveis (subtrair a média e dividir pelo desvio-padrão da base inteira) **antes** de entrar no laço das $k$ dobras usa a média e a variância das observações da dobra de validação $D_j$ para escalar o treino $D^{(-j)}$, configurando **vazamento de dados (*data leakage*)**. A padronização correta deve calcular $\bar{x}^{(-j)}$ e $s_x^{(-j)}$ exclusivamente dentro das $k-1$ dobras de treino e aplicar essa mesma transformação linear à dobra $j$ de validação.
4. **Quando usar Validação Cruzada vs. Bootstrap:**  
   - *(a) Escolher entre polinômio de grau 3 e de grau 5:* **Validação Cruzada** (problema de seleção de hiperparâmetro / comparação de erro preditivo fora da amostra).  
   - *(b) Decidir se o coeficiente $\hat{\beta}_1$ pode ser zero:* **Bootstrap** (problema de inferência / quantificação da incerteza e intervalo de confiança de um parâmetro).  
   - *(c) Medir a incerteza da mediana de renda da amostra:* **Bootstrap** (estimativa de erro-padrão e IC para uma estatística que não possui fórmula analítica simples).  
   - *(d) Comparar um modelo com 10 preditores contra um com 3:* **Validação Cruzada** (comparação da capacidade de generalização entre modelos com diferentes números de parâmetros, onde o erro de treino favoreceria artificialmente o modelo com 10 preditores).

---

## Documentos complementares

**Script que gera este consolidado:**
- 🧮 [`07-reamostragem.R`](https://github.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/blob/main/estrutura/scriptsR/07-reamostragem.R) — **a fonte** deste documento.

**Demais documentos relacionados:**
- 📋 [Relatório técnico do script (`07-reamostragem.md`)](https://github.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/blob/main/estrutura/scriptsR/07-reamostragem.md) — output bruto, sem a camada didática.
- 📎 [Consolidado 01 — Dicionário de variáveis](https://github.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/blob/main/consolidado/01-dicionario-variaveis.md).
- 📎 [Consolidado 02 — Análise exploratória](https://github.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/blob/main/consolidado/02-analise-exploratoria.md).
- 📎 [Consolidado 03 — Regressão linear](https://github.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/blob/main/consolidado/03-regressao-linear.md).
- 📎 [Consolidado 04 — Regressão logística](https://github.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/blob/main/consolidado/04-regressao-logistica.md).
- 📎 [Consolidado 05 — Treino/teste (regressão)](https://github.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/blob/main/consolidado/05-regressao-linear-treino-teste.md).
- 📎 [Consolidado 06 — Classificação honesta](https://github.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/blob/main/consolidado/06-regressao-logistica-treino-teste.md).
- 📊 [Banco de dados (CSV)](https://github.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/blob/main/estrutura/bancoDeDados/df_ipdm_baixada_por_municipio.csv).
- 📄 [Dicionário de dados (PDF)](https://github.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/blob/main/estrutura/dicionario/dicionario_ipdm_baixada.pdf).
