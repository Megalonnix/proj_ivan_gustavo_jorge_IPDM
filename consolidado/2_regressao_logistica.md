# Regressão Logística — Mortalidade alta × PIB per capita

## 1. Objetivo

Modelar a probabilidade de um município/ano apresentar taxa de mortalidade
60–69 **acima da mediana da amostra**, em função do PIB per capita. A
regressão logística é a extensão natural do modelo linear quando o alvo é
binário, e permite leitura direta em termos de *chance* (odds) relativa.

Este script cobre as tarefas da **Aula 5**: ajuste logístico, interpretação
de razões de chance, matrizes de confusão em **três limiares (0,3 / 0,5 /
0,7)**, AUC, e discussão sobre custo de erros (FP vs. FN) e escolha de limiar.

## 2. Construção da variável binária

`mortalidade_alta = 1` se a taxa de mortalidade 60–69 da observação está
acima da **mediana da amostra completa** (19,40 por mil hab.); `0` caso
contrário. O corte pela mediana garante divisão **27/27** entre as classes —
didaticamente limpo e dispensa a adoção de um limiar clínico externo, que
não tem consenso na literatura para essa faixa etária específica.

## 3. Especificação

    logit(P(Y = 1)) = β0 + β1 · PIB per capita

- Interpretação dos coeficientes via **odds ratio** (OR = exp(β)).
- OR < 1 → aumento do preditor reduz a chance do evento (mortalidade alta).
- OR > 1 → aumento do preditor eleva a chance.

Como o PIB tem escala em milhares de reais, a OR por R$ 1,00 é praticamente
1,000. A leitura substantiva é a **OR por R$ 1.000**, obtida via
`exp(β1 · 1000)`.

## 4. Resultado — amostra completa

| Quantidade | Valor |
|-----------|-------|
| β₀ (intercepto, logit) | +0,306 |
| β₁ (PIB, logit) | −5,25 × 10⁻⁶ |
| OR por R$ 1,00 | 0,99999 |
| **OR por R$ 1.000** | **0,9948** |
| IC 95% para β₁ | [−1,68 × 10⁻⁵ ; +4,12 × 10⁻⁶] |
| p-valor de β₁ | 0,301 |
| Pseudo-R² de McFadden | 0,0157 |

**Leitura do coeficiente:** o sinal é **negativo** — consistente com a
regressão linear e com a hipótese teórica (renda maior → menor chance de
mortalidade alta). Porém:

- O **p-valor de 0,301** indica que, na amostra completa, **não há evidência
  estatística** de que β₁ seja diferente de zero.
- O **IC 95% cruza o zero** — reforça a mesma conclusão.
- A **OR por R$ 1.000 é 0,9948** — cada mil reais adicionais de PIB reduzem
  as chances de mortalidade alta em apenas **0,52%**. Efeito minúsculo.

O **Pseudo-R² de McFadden = 0,016** confirma: o modelo é apenas marginalmente
melhor que o modelo nulo (sem preditor). PIB per capita, sozinho, discrimina
muito pouco entre municípios acima e abaixo da mediana.

## 5. Por que a curva parece quase reta (não um S)?

![](https://raw.githubusercontent.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/main/estrutura/scriptsR/figuras/fig2_logistica_sigmoide.png)

Um olhar apressado pode sugerir que "a logística falhou" — a curva não exibe
o S bem desenhado típico dos exemplos didáticos. **Não é falha**: é
consequência geométrica de β₁ pequeno.

A curva logística só exibe a forma de S bem definida quando o preditor
linear `z = β₀ + β₁·X` percorre uma **faixa ampla** (aproximadamente
−6 a +6). Se `z` varia pouco, ficamos presos na região **central** da curva,
que é praticamente linear.

O diagnóstico impresso pelo script mostra:

| Quantidade | Valor |
|-----------|-------|
| Amplitude de X (PIB) | R$ 250.054 |
| **Amplitude de z** | **1,31** |
| Amplitude de p (probabilidades previstas) | 0,30 |
| p mínimo previsto | 0,247 |
| p máximo previsto | 0,550 |

**Amplitude de z = 1,31** → muito abaixo do limiar de 2 que marcaria uma
sigmoide "moderadamente curvada". Traduzindo: as probabilidades previstas
**nunca passam de 0,55 nem caem abaixo de 0,25** — o modelo fica sempre
"em cima do muro", perto de 0,5. É por isso que a curva parece um risco
quase horizontal: o modelo tem muito pouca confiança em qualquer direção.

**Causa-raiz:** associação fraca. O mesmo achado do script 1 (R² ~ 0,06 no
linear) reaparece aqui como β₁ minúsculo no logit. Cubatão — caso atípico
com PIB altíssimo e mortalidade na média — impede que o logit se incline,
porque ele combina `X` grande com `Y` misto.

## 6. Tabela de contingência — onde os casos caem

Distribuição de `mortalidade_alta` por faixa de PIB:

| Faixa de PIB (R$) | Baixa (0) | Alta (1) |
|-------------------|-----------|----------|
| 19.814 – 70.075 | 19 | 24 |
| 70.075 – 120.086 | 5 | 0 |
| 120.086 – 170.097 | 0 | 1 |
| 170.097 – 220.108 | 1 | 1 |
| 220.108 – 270.369 | 2 | 1 |

Leitura:

- Na faixa mais baixa (até ~70 mil), a divisão é quase equilibrada — o
  preditor não separa as classes.
- A faixa intermediária (70k–120k) é 100% mortalidade baixa (5/5), o que
  sugere algum sinal — mas com apenas 5 observações, é frágil.
- As faixas altas (>120k) são dominadas por **Cubatão**, que tem mortalidade
  mista (3 baixas, 3 altas).

**Cubatão em detalhe:** suas 6 observações têm PIB entre R$ 170 mil e R$ 270
mil, mas `mortalidade_alta` alterna entre 0 e 1 sem padrão claro. Ou seja,
Cubatão **não ajuda o modelo a aprender** — ele só ocupa espaço na cauda
direita do PIB sem contribuir com sinal.

## 7. Matrizes de confusão em três limiares

### 7.1 Como as matrizes são geradas

As matrizes abaixo **não são cálculo manual** — vêm diretamente do output
do script. O bloco relevante é:

```r
prob <- predict(modelo_log, type = "response")
# prob: vetor de 54 probabilidades previstas, uma por observação

avaliar_limiar <- function(prob, y, c) {
  yhat <- as.integer(prob > c)          # (1) converte prob em classe 0/1
  tab <- table(                         # (2) cruza previsto x real
    Predito = factor(yhat, levels = c(0, 1)),
    Real    = factor(y,    levels = c(0, 1))
  )
  # (3) extrai as 4 células
  VP <- tab["1","1"]; VN <- tab["0","0"]
  FP <- tab["1","0"]; FN <- tab["0","1"]
  # (4) calcula as métricas
  acuracia      <- (VP + VN) / sum(tab)
  sensibilidade <- if ((VP + FN) > 0) VP / (VP + FN) else NA_real_
  especificidade<- if ((VN + FP) > 0) VN / (VN + FP) else NA_real_
  precisao      <- if ((VP + FP) > 0) VP / (VP + FP) else NA_real_
  list(limiar = c, tab = tab,
       acuracia = acuracia, sens = sensibilidade,
       espec = especificidade, prec = precisao)
}

resultados <- lapply(c(0.3, 0.5, 0.7),
                     function(c) avaliar_limiar(prob, df$mortalidade_alta, c))
```

**Cadeia lógica, passo a passo:**

1. `predict(..., type = "response")` devolve, para cada uma das 54
   observações, a probabilidade estimada `P(mortalidade_alta = 1)`.
2. Para cada limiar `c`, a regra `yhat = as.integer(prob > c)` converte
   probabilidade em classe prevista: 1 se acima do limiar, 0 se abaixo.
3. `table(Predito, Real)` cruza os dois vetores 0/1. As linhas são o que o
   modelo disse (`Predito`); as colunas são o que aconteceu (`Real`). Cada
   célula da matriz 2×2 é apenas uma **contagem** de observações naquela
   combinação.
4. A diagonal principal (canto superior esquerdo + canto inferior direito)
   concentra os acertos: **VN** (verdadeiro negativo) e **VP** (verdadeiro
   positivo). A diagonal secundária concentra os erros: **FP** e **FN**.

As três matrizes a seguir correspondem exatamente às três chamadas de
`avaliar_limiar` com `c = 0,3`, `c = 0,5` e `c = 0,7`.

### 7.2 Limiar 0,3 (permissivo)

```
        Real
Predito  0  1
      0  2  1
      1 25 26
```

| Métrica | Valor |
|---------|-------|
| Acurácia | 0,519 |
| Sensibilidade | 0,963 |
| Especificidade | 0,074 |
| Precisão | 0,510 |

Quase tudo é classificado como positivo. Sensibilidade altíssima,
especificidade péssima — o modelo dispara alarme para praticamente todos
os casos.

### 7.3 Limiar 0,5 (equilibrado)

```
        Real
Predito  0  1
      0  9  3
      1 18 24
```

| Métrica | Valor |
|---------|-------|
| Acurácia | 0,611 |
| Sensibilidade | 0,889 |
| Especificidade | 0,333 |
| Precisão | 0,571 |

Melhor equilíbrio dos três, mas ainda fortemente inclinado para o lado
positivo.

### 7.4 Limiar 0,7 (conservador)

```
        Real
Predito  0  1
      0 27 27
      1  0  0
```

| Métrica | Valor |
|---------|-------|
| Acurácia | 0,500 |
| Sensibilidade | 0,000 |
| Especificidade | 1,000 |
| Precisão | — |

**Colapso total:** o modelo nunca produz `p > 0,7` (o máximo é 0,55), então
classifica **tudo** como negativo. Sensibilidade zero. O modelo se torna
inútil como classificador — é apenas um "chute" enviesado.

**Comparação visual dos três limiares:** a acurácia parece sempre medíocre
(0,50–0,61), mas isso é ilusório — com 27/27 balanceado, o chute aleatório
já dá 50%. O modelo ganha pouco sobre o chute.

## 8. Curva ROC e AUC

![](https://raw.githubusercontent.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/main/estrutura/scriptsR/figuras/fig2_logistica_roc.png)

O AUC vem do objeto criado por:

```r
roc_obj <- pROC::roc(df$mortalidade_alta, prob,
                     levels = c(0, 1), direction = "<", quiet = TRUE)
print(pROC::auc(roc_obj))
```

| Modelo | AUC |
|--------|-----|
| Com Cubatão | **0,690** |
| Sem Cubatão | **0,737** |

Leitura (escala qualitativa):

- 0,5 → chute aleatório
- **0,7 → discriminação aceitável (limiar inferior)**
- 0,8 → discriminação boa
- 1,0 → discriminação perfeita

O modelo com Cubatão fica **logo abaixo** do limiar de "aceitável" (0,69).
Sem Cubatão, **cruza o limiar** (0,737). O ponto extremo, mais uma vez,
atrapalha — reforçando o achado do script 1.

## 9. Sensibilidade — o impacto de Cubatão

| Modelo | β₁ (logit) | OR por R$ 1.000 | AUC |
|--------|-----------|-----------------|-----|
| Com Cubatão | −5,25 × 10⁻⁶ | 0,9948 | 0,690 |
| **Sem Cubatão** | **−9,22 × 10⁻⁵** | **0,9119** | **0,737** |

Sem Cubatão:

- β₁ fica **~17× mais forte em módulo**.
- A **OR por R$ 1.000 cai de 0,995 para 0,912** — agora o efeito é substantivo:
  cada mil reais adicionais reduzem as chances de mortalidade alta em **~8,8%**.
- A AUC sobe para 0,737, cruzando o limiar de "aceitável".

Mesma narrativa do script 1: Cubatão tem PIB altíssimo mas mortalidade na
média — combinação que **contraria a hipótese renda–saúde** e enfraquece
qualquer modelo que use PIB como preditor.

## 10. Discussão — qual erro custa mais caro?

Pergunta explícita da Aula 5 (slide 29): *"no seu problema, qual erro (FP ou
FN) custa mais caro — e que limiar você usaria?"*

### Definições no contexto

- **FP** (falso positivo): classificar como "mortalidade alta" uma observação
  que é "baixa". **Alarme falso.**
- **FN** (falso negativo): classificar como "mortalidade baixa" uma que é
  "alta". **Alarme perdido.**

### Custo relativo

Interpretando em termos de política pública de saúde:

- **FP** → mobilizar recursos de vigilância/intervenção para um município-ano
  que **não** está em situação crítica. Custo: desperdício de orçamento,
  desvio de atenção.
- **FN** → **não** mobilizar recursos para um município-ano que **está** em
  situação crítica. Custo: **mortalidade evitável, perda humana**.

**O FN custa muito mais caro.** Um município que precisa de intervenção e
não é sinalizado perde vidas; um município sinalizado sem necessidade apenas
recebe atenção redundante.

### Escolha recomendada de limiar

**Limiar 0,3** — o permissivo. Consequências neste banco:

- Sensibilidade sobe para 0,963 → apenas **1 FN** em 27 casos de mortalidade
  alta real (contra 3 FNs com o limiar 0,5).
- Especificidade despenca para 0,074 → **25 FPs**. Aceitável dado o custo
  relativo.

O limiar 0,7 é **inaceitável** neste contexto: 27 FNs — ou seja, **todos os
casos de mortalidade alta passariam batido**. Apesar da acurácia "neutra"
(0,50), é o pior cenário do ponto de vista de saúde pública.

### Ressalva metodológica

A escolha do limiar **pressupõe** que o modelo tem algum poder discriminativo.
Neste caso, com AUC = 0,69 na amostra completa, o modelo é **apenas
marginalmente melhor que o chute**. O ajuste de limiar ajuda, mas não
transforma um modelo fraco em um modelo bom. A leitura honesta é:

> A escolha de limiar é uma decisão de negócio que otimiza o trade-off FP/FN
> **dentro** do poder discriminativo disponível. Aqui, o poder é baixo. A
> recomendação operacional é usar limiar baixo **em conjunto com outras
> ferramentas de triagem**, não como classificador autônomo.

## 11. Limitações e amarração

1. **Variabilidade amostral.** O efeito do PIB sobre a probabilidade de
   mortalidade alta já era fraco na amostra completa; com 54 observações e
   um ponto de alta alavancagem, é difícil separar sinal de ruído.

2. **Estrutura de painel.** 9 municípios × 6 anos — as observações do mesmo
   município são autocorrelacionadas. Os p-valores e ICs são **indicativos**,
   não provas rigorosas.

3. **Caso Cubatão.** Reforça a leitura do script 1: o achado depende
   criticamente do tratamento dado ao ponto extremo. Reportar as duas versões
   (com e sem) é o que torna a análise honesta.

4. **Discretização.** O corte por mediana descarta informação (a magnitude
   da mortalidade). Ganha-se em interpretação probabilística e comparabilidade
   com classificadores; perde-se em resolução.

5. **Amarração com script 4.** O split treino/teste (script 4) usa o
   **mesmo limiar 0,5** e a **mesma mediana** da amostra completa. Isso
   permite comparar as duas versões (full vs. out-of-sample) sem confundir
   a mudança de amostra com mudança de definição do alvo.

A conclusão substantiva vem da **leitura conjunta** dos quatro scripts: o
sinal do PIB per capita é negativo no modelo linear full e na logística full,
mas **não sobrevive à redução da amostra no split treino/teste** — evidência
de que, nesta amostra específica, a relação é tênue e sensível ao subconjunto
considerado.