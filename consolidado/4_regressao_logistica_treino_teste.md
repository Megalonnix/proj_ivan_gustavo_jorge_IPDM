# Regressão Logística — Treino/Teste (70/30)

## 1. Objetivo

Repetir o exercício do script 3 no contexto logístico: ajustar o modelo
*apenas no treino* e avaliar o poder de discriminação no conjunto de teste,
usando as métricas próprias de classificadores binários (matriz de confusão,
acurácia, sensibilidade, especificidade e curva ROC).

O split é **idêntico ao do script 3** (`set.seed(42)`, mesma chamada `sample`)
— requisito para que a comparação entre regressão linear e logística seja
legítima: os dois modelos são avaliados nas mesmas 17 observações de teste.

## 2. Especificação e alvo

- **Alvo:** `mortalidade_alta`, definido com a **mediana da amostra completa**
  (19,40 por mil hab.), não do treino. Manter o mesmo corte do script 2 é o
  que garante comparabilidade entre as versões full e treino/teste.
- **Modelo:** `glm(mortalidade_alta ~ pib_per_capita, family = binomial)`.
- **Limiar de decisão:** 0,5 (padrão). A probabilidade prevista > 0,5 →
  classifica como `1`.

## 3. Desempenho no teste

**Matriz de confusão** — cruza predito vs. real no conjunto de teste (17
observações). Neste split específico, o modelo treinado apresentou
coeficiente para PIB per capita **estatisticamente indistinguível de zero**
(β₁ ≈ −1,0 × 10⁻⁷, p ≈ 0,99), com desvio nulo igual ao desvio residual —
indicando que o preditor não adiciona informação no subconjunto de treino.
Consequentemente, as probabilidades previstas ficaram concentradas em torno
do limiar de decisão e **todas as 17 observações de teste foram
classificadas como classe 1**. Esse comportamento reflete ausência de sinal
discriminativo no treino, não erro de implementação — é coerente com a
magnitude modesta do efeito observada nos scripts 1 e 2 e reforça a leitura
de que o PIB per capita, isoladamente, tem poder preditivo limitado para a
mortalidade 60–69 nesta amostra.

Com 17 observações de teste, cada célula da matriz vale por aproximadamente
6% da acurácia, o que torna as métricas altamente sensíveis a um único
acerto/erro. Isso é uma limitação **estrutural** da amostra pequena, não do
método.

**Acurácia** — proporção de acertos. Rápida de ler, mas enganosa quando as
classes são desbalanceadas ou quando o modelo colapsa em uma única classe —
é exatamente o caso aqui.

**Sensibilidade** — dos que realmente têm mortalidade alta, quantos o modelo
pegou. **Especificidade** — dos que realmente têm mortalidade baixa, quantos
o modelo pegou. Com o colapso em classe 1, a especificidade é zero por
construção, o que confirma a ausência de discriminação.

**AUC (área sob a curva ROC)** — resumo do poder de discriminação em todos os
limiares possíveis. Leitura rápida:
- AUC = 0,5 → modelo não discrimina (equivale a chute).
- AUC ≈ 0,7 → discriminação aceitável.
- AUC ≥ 0,8 → discriminação boa.
- AUC = 1,0 → discriminação perfeita (sinal de sobreajuste ou vazamento).

Neste split, a AUC deve ficar próxima de 0,5, confirmando numericamente o
que a matriz de confusão já mostra.

![](https://raw.githubusercontent.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/main/estrutura/scriptsR/figuras/fig4_logistica_sigmoide_teste.png)

A curva sigmoide foi ajustada **apenas com o treino**; os pontos laranja são
as observações de teste. Como o coeficiente do PIB é praticamente nulo, a
curva resultante é quase plana — leitura visual direta da ausência de sinal.

![](https://raw.githubusercontent.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/main/estrutura/scriptsR/figuras/fig4_logistica_matriz_confusao.png)

Matriz de confusão visual. A concentração de toda a massa na linha "1"
reflete o colapso do classificador em uma única classe neste split.

![](https://raw.githubusercontent.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/main/estrutura/scriptsR/figuras/fig4_logistica_roc.png)

Curva ROC com AUC anotada. A diagonal tracejada representa o classificador
aleatório. A proximidade da curva a essa diagonal quantifica o poder
discriminativo nulo do modelo treinado.

## 4. Discussão e limitações

Este script produz um resultado que, à primeira vista, parece negativo — mas
é **substantivamente informativo** e deve ser lido em conjunto com os demais:

1. **Variabilidade amostral em amostra pequena.** O efeito do PIB sobre a
   probabilidade de mortalidade alta já era fraco na amostra completa. Em
   um split de 37 observações, esse efeito pode se tornar indistinguível de
   zero apenas por flutuação amostral. É um retrato honesto do que acontece
   quando se tenta estimar relações tênues com poucos dados.

2. **Estrutura de painel.** O split por linha pode colocar o mesmo município
   em treino e teste em anos diferentes — o que infla artificialmente o
   desempenho, porque parte da "identidade" do município vaza de um conjunto
   para o outro. Em painéis, o split por unidade é mais rigoroso.

3. **Tamanho do teste.** Com 17 observações, cada métrica tem variância
   enorme. As conclusões são **indicativas**, não inferenciais.

4. **Alvo binário.** Discretizar pela mediana descarta informação (a
   magnitude da mortalidade). Ganha-se em interpretação probabilística e
   comparabilidade com classificadores; perde-se em resolução.

A conclusão substantiva vem da **leitura conjunta** dos quatro scripts: o
sinal do PIB per capita é negativo no modelo linear full e na logística full,
mas não sobrevive à redução da amostra no split treino/teste — evidência de
que, nesta amostra específica, a relação é tênue e sensível ao subconjunto
considerado. Esse tipo de robustez (ou falta dela) é justamente o que a
validação cruzada existe para revelar.