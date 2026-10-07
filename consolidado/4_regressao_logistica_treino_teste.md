# Regressão Logística — Treino/Teste (70/30)

## 1. Objetivo

Repetir o exercício do script 3 no contexto logístico: ajustar o modelo
**apenas no treino** e avaliar o poder de discriminação no conjunto de teste,
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
- **Limiar de decisão:** avaliado em três valores (0,3 / 0,5 / 0,7).

### 2.1 Distribuição do alvo nos conjuntos

| Conjunto | Positivos | Total | Proporção |
|----------|-----------|-------|-----------|
| Amostra completa | 27 | 54 | 50% |
| Treino | 19 | 37 | 51% |
| Teste | 8 | 17 | 47% |

Divisão razoavelmente equilibrada entre treino e teste.

## 3. Ajuste no treino

| Quantidade | Valor |
|-----------|-------|
| β₀ (intercepto, logit) | +0,0601 |
| **β₁ (PIB, logit)** | **−1,03 × 10⁻⁷** |
| p-valor de β₁ | **0,986** |
| Deviance nula | 51,27 |
| Deviance residual | 51,27 |
| AIC | 55,27 |

**O coeficiente é indistinguível de zero.** O p-valor de 0,986 é o mais
extremo possível sem ser exatamente 1 — sinal de que o preditor não adiciona
**nenhuma** informação no subconjunto de treino. A deviance residual é
**idêntica** à deviance nula (51,27 em ambos), o que confirma numericamente:
o modelo com PIB é exatamente tão bom quanto o modelo sem preditor nenhum.

**Por que isso acontece?** O script 3 mostrou que o split alocou Cubatão de
forma desfavorável — 4 obs no treino, 2 no teste. No treino, Cubatão
apresenta mortalidade **mista** (2 altas, 2 baixas) apesar de PIB altíssimo.
Isso "achata" o sinal dentro do treino: o PIB deixa de discriminar.

## 4. Previsões no teste — o colapso

![](https://raw.githubusercontent.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/main/estrutura/scriptsR/figuras/fig4_logistica_sigmoide_teste.png)

### 4.1 Faixa das probabilidades previstas

| Conjunto | Mínimo | Máximo | Amplitude |
|----------|--------|--------|-----------|
| Treino | 0,5086 | 0,5145 | **0,0059** |
| Teste | 0,5081 | 0,5145 | **0,0064** |

**Amplitude de z (logit) no treino: 0,0238.**

Duas coisas gritam nesses números:

1. **Todas as probabilidades estão acima de 0,5.** O modelo "acha" que
   praticamente toda observação é de mortalidade alta — independente do PIB.
2. **A variação entre elas é minúscula** (~0,006). O modelo é praticamente
   uma constante.

### 4.2 Leitura visual da sigmoide

A curva ajustada é **quase uma reta horizontal** em p ≈ 0,51. Como todas as
probabilidades previstas ficam concentradas numa faixa minúscula, os pontos
observados (0/1, em y = 0 ou y = 1) ficam **muito longe** da curva. É a
imagem visual de um modelo que não aprendeu nada.

Comparando com o script 2 (amostra completa), onde a amplitude de z era
1,31 (já pequena): aqui ela caiu para **0,024** — 55× menor. Menos dados no
treino + split desfavorável de Cubatão = o sinal praticamente desapareceu.

## 5. Matrizes de confusão em três limiares

### 5.1 Como as matrizes são geradas

Idêntico ao script 2:

```r
prob <- predict(modelo_treino, newdata = teste, type = "response")
yhat <- as.integer(prob > c)              # (1) converte prob em classe 0/1
tab  <- table(Predito = yhat, Real = y)   # (2) cruza previsto x real
```

Cada célula da matriz é apenas uma **contagem** de observações naquela
combinação (previsto, real) para aquele limiar.

### 5.2 Limiar 0,3 (permissivo)

```
        Real
Predito  0  1
      0  0  0
      1  9  8
```

| Métrica | Valor |
|---------|-------|
| Acurácia | 0,471 |
| Sensibilidade | **1,000** |
| Especificidade | **0,000** |
| Precisão | 0,471 |

### 5.3 Limiar 0,5 (equilibrado)

```
        Real
Predito  0  1
      0  0  0
      1  9  8
```

| Métrica | Valor |
|---------|-------|
| Acurácia | 0,471 |
| Sensibilidade | **1,000** |
| Especificidade | **0,000** |
| Precisão | 0,471 |

**Idêntico ao limiar 0,3.** Motivo: todas as probabilidades previstas estão
acima de 0,508, então mudar o limiar de 0,3 para 0,5 não altera nenhuma
classificação.

### 5.4 Limiar 0,7 (conservador)

```
        Real
Predito  0  1
      0  9  8
      1  0  0
```

| Métrica | Valor |
|---------|-------|
| Acurácia | 0,529 |
| Sensibilidade | **0,000** |
| Especificidade | **1,000** |
| Precisão | — |

**Colapso para o lado oposto.** Todas as probabilidades previstas são menores
que 0,514, então com limiar 0,7 o modelo classifica **tudo como 0**.

### 5.5 Síntese das matrizes

Este é o cenário extremo previsto no micro-relatório: **o ajuste de limiar
não produz trade-offs úteis**. Não há um limiar que dê equilíbrio entre
sensibilidade e especificidade — os valores de probabilidade são tão
comprimidos que:
- Qualquer limiar ≤ 0,51 → tudo positivo.
- Qualquer limiar ≥ 0,52 → tudo negativo.

Não existe zona de transição. O modelo **não tem confiança** em nada.

## 6. O paradoxo da AUC

![](https://raw.githubusercontent.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/main/estrutura/scriptsR/figuras/fig4_logistica_roc.png)

| Modelo | β₁ (treino) | AUC (teste) |
|--------|------------|-------------|
| **Com Cubatão** | −1,03 × 10⁻⁷ | **0,868** |
| Sem Cubatão | −6,82 × 10⁻⁵ | 0,840 |

### 6.1 Como pode AUC = 0,87 com β₁ ≈ 0?

Este é o resultado mais contraintuitivo do trabalho. β₁ é indistinguível de
zero (p = 0,986), as probabilidades previstas estão todas no intervalo
[0,508; 0,514], e ainda assim a AUC é **0,87** — o que normalmente indicaria
boa discriminação.

**Explicação:** a AUC mede **capacidade de ranking**, não de classificação.
Ela pergunta: *"se eu pegar uma observação positiva e uma negativa ao acaso,
qual a probabilidade de o modelo ter dado probabilidade maior à positiva?"*

Como β₁ é **negativo** (ainda que minúsculo), o modelo atribui
probabilidades levemente menores às observações com PIB mais alto. Se, no
teste, as observações positivas (mortalidade alta) tendem a ter PIB mais
baixo, esse ranking minúsculo ainda funciona — e a AUC captura isso.

**Mas o ranking é irrelevante na prática.** Um classificador real precisa de
um limiar. E como todas as probabilidades estão num intervalo de 0,006, o
limiar **não consegue separar** nada: qualquer limiar escolhido produz
colapso total em uma classe.

### 6.2 AUC alta ≠ modelo útil

Este caso é um exemplo didático do perigo de confiar só na AUC. Um modelo
que atribui a **mesma probabilidade** para todas as observações pode ter AUC
alta se a ordenação residual for favorável — mas é **inútil como
classificador**.

Métricas complementares que revelariam o problema:
- **Curva de calibração** (probabilidades previstas vs. observadas).
- **Brier score** (erro quadrático das probabilidades).
- **Inspeção da faixa de probabilidades** (feita neste relatório).

A conclusão honesta é: **AUC alta aqui é um artefato de amostra pequena +
ranking residual**, não evidência de poder preditivo.

### 6.3 Sensibilidade sem Cubatão

Ao remover Cubatão:

- β₁ fica **660× mais forte** em módulo (−1,03 × 10⁻⁷ → −6,82 × 10⁻⁵).
- AUC cai ligeiramente (0,868 → 0,840).

O β₁ mais forte sem Cubatão é o esperado (o ponto extremo atrapalha). A
**queda** da AUC é contraintuitiva, mas explicável: o split muda quando
removemos Cubatão (o `sample()` do seed 42 é aplicado a 48 obs em vez de
54), então a comparação não é controlada. Além disso, em 17 pontos, cada
troca vale muito.

## 7. Discussão — resultado informativo, não fracasso

Este script produz um resultado que, à primeira vista, parece negativo —
mas é **substantivamente informativo** e deve ser lido em conjunto com os
demais:

### 7.1 Variabilidade amostral em amostra pequena

O efeito do PIB sobre a probabilidade de mortalidade alta já era fraco na
amostra completa (script 2: β₁ = −5,25 × 10⁻⁶, p = 0,301). Em um split de
37 observações, esse efeito pode se tornar indistinguível de zero apenas por
flutuação amostral. É um retrato honesto do que acontece quando se tenta
estimar relações tênues com poucos dados.

### 7.2 O split agrava o problema de Cubatão

O split `set.seed(42)` alocou:
- Cubatão 2018 e 2024 (as duas obs mais extremas) no **teste**.
- Cubatão 2014, 2016, 2020, 2022 no **treino**.

No treino, Cubatão apresenta mortalidade **mista** (2 altas, 2 baixas)
apesar de PIB altíssimo. Resultado: o modelo não encontra sinal. É um efeito
de composição amostral, não uma falha do método.

### 7.3 Sobre "qual erro custa mais caro"

Pergunta da Aula 5 (slide 29). Mesmo raciocínio do script 2:

- **FP** (alarme falso): mobilizar recursos sem necessidade.
- **FN** (alarme perdido): **deixar passar** municípios em situação crítica.
- **O FN custa muito mais caro** no contexto de saúde pública.

Limiar recomendado: **0,3** (permissivo). Mas aqui, com o colapso em classe
única, nem 0,3 nem 0,5 funcionam de verdade — ambos classificam tudo como
positivo, o que gera 9 FPs e apenas 8 VPs. A escolha de limiar **não salva
um modelo sem sinal**.

### 7.4 O que o script 4 revela sobre o script 2

Comparando os dois:

| Script | Amostra | β₁ | p-valor | AUC |
|--------|---------|-----|---------|-----|
| Script 2 | Completa | −5,25 × 10⁻⁶ | 0,301 | 0,690 |
| Script 4 | Treino (37 obs) | −1,03 × 10⁻⁷ | 0,986 | 0,868 |

**Sem Cubatão, ambos os cenários ficam mais fortes:**
- Script 2 sem Cubatão: β₁ = −9,22 × 10⁻⁵, AUC = 0,737.
- Script 4 sem Cubatão: β₁ = −6,82 × 10⁻⁵, AUC = 0,840.

Isso reforça o fio condutor de todo o trabalho: o achado depende
criticamente do tratamento dado a Cubatão.

## 8. Limitações

1. **Amostra pequena.** Com 17 observações de teste, cada célula da matriz
   vale ~6% da acurácia. Métricas altamente instáveis.

2. **Estrutura de painel.** Split por linha pode colocar o mesmo município
   em treino e teste em anos diferentes — vazamento de "identidade".

3. **AUC enganosa.** AUC alta com probabilidades colapsadas é um caso
   didático do perigo de confiar em uma única métrica.

4. **Alvo binário.** Discretizar pela mediana descarta informação de
   magnitude.

5. **Instabilidade do split.** Remover Cubatão refaz o split do zero — não
   é uma variação controlada.

## 9. Amarração com os demais scripts

A conclusão substantiva vem da **leitura conjunta** dos quatro scripts:

- O sinal do PIB per capita é **negativo** no linear full (script 1), na
  logística full (script 2) e no linear treino/teste (script 3).
- No logístico treino/teste (script 4), o sinal **colapsa** — β₁ vira
  praticamente zero, e o classificador perde qualquer utilidade prática.
- **O fio condutor de todos os achados é Cubatão:** um município com PIB
  industrial altíssimo mas mortalidade na média dos vizinhos mais pobres,
  que mascara a relação renda–saúde na amostra completa e desestabiliza os
  splits.

Esse tipo de robustez — ou falta dela — é justamente o que a validação
out-of-sample existe para revelar.