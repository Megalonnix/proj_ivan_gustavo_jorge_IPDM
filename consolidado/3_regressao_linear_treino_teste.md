# Regressão Linear — Treino/Teste (70/30)

## 1. Objetivo

O ajuste sobre a amostra completa (script 1) mede o quanto o modelo
descreve os dados que ele mesmo viu. Aqui interessa outra pergunta: **o
modelo generaliza?** Para isso, separa-se a amostra em treino (70%) e teste
(30%), ajusta-se apenas no treino e mede-se o erro de previsão no conjunto
de teste — que o modelo não viu.

## 2. Split

```r
set.seed(42)
idx_treino <- sample(seq_len(n), size = floor(0.7 * n))
```

- 54 observações → **37 treino / 17 teste**.
- `set.seed(42)` garante reprodutibilidade.
- **O mesmo split é usado no script 4**, o que torna a comparação entre
  regressão linear e logística legítima (mesmos municípios/anos no teste).

### 2.1 Onde Cubatão caiu

Cubatão tem 6 observações no banco. O split alocou:

- **Treino (4 obs):** 2014, 2016, 2020, 2022 — PIB entre R$ 170 e 250 mil,
  mortalidade entre 17,1 e 21,1.
- **Teste (2 obs):** 2018 (PIB ≈ R$ 171 mil, mortalidade 16,7) e 2024
  (PIB ≈ R$ 270 mil, mortalidade 18,1).

Isso é decisivo para interpretar as métricas: **as duas observações mais
extremas de Cubatão caíram no teste**, sendo 2024 o pico de PIB da amostra
inteira. O modelo treinado é avaliado exatamente nos pontos mais difíceis de
prever — e isso explica boa parte dos erros grandes do teste.

## 3. Ajuste no treino

    mortalidade_60_69 = 20,16 − 1,03 × 10⁻⁵ · pib_per_capita

| Quantidade | Valor |
|-----------|-------|
| β₀ (intercepto) | 20,1557 |
| β₁ (PIB) | −1,03 × 10⁻⁵ |
| p-valor de β₁ | 0,269 |
| R² treino | **0,0347** |
| R² ajustado (treino) | 0,0072 |
| Erro-padrão residual | 3,188 |

O β₁ **não é estatisticamente significativo** (p = 0,269). O R² caiu em
relação à amostra completa (0,062 no script 1 → 0,035 aqui) — reflexo de que
o split retirou observações que sustentavam o sinal.

## 4. Desempenho no teste

| Métrica | Valor |
|---------|-------|
| RMSE | 4,8186 |
| MAE | 3,3765 |
| **R² no teste** | **0,0188** |
| R² treino | 0,0347 |

**Leitura:**

- **RMSE ≈ 4,82 por mil hab.** — erro típico de ~5 pontos na escala de
  mortalidade, cuja faixa no teste vai de 14,6 a 33,0. Erro proporcionalmente
  grande.
- **MAE ≈ 3,38** — mais robusto a outliers. A diferença RMSE − MAE ≈ 1,44
  indica que há alguns erros grandes concentrados em poucas observações
  (ver seção 6.2).
- **R² de teste = 0,019** — praticamente zero. O modelo explica ~2% da
  variabilidade da mortalidade no teste.
- **R² treino ≈ R² teste** (0,035 vs 0,019) — não há sobreajuste. O modelo
  não está "decorando" o treino. É **subajuste**: o preditor único não
  captura o fenômeno, dentro ou fora da amostra.

## 5. Gráfico 1 — Reta ajustada no treino sobre pontos de teste

![](https://raw.githubusercontent.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/main/estrutura/scriptsR/figuras/fig3_linear_teste_reta.png)

### 5.1 Leitura visual (números que sustentam a descrição)

| Elemento | Valor |
|----------|-------|
| Intercepto da reta | 20,16 |
| Inclinação | −1,03 × 10⁻⁵ |
| Altura da reta no PIB mínimo | 19,95 |
| Altura da reta no PIB máximo | 17,36 |
| **Δy da reta sobre toda a faixa** | **−2,58** |
| Faixa de mortalidade no treino | 13,94 a 26,28 |
| Faixa de mortalidade no teste | 14,65 a 33,00 |

### 5.2 O que a figura mostra

- A reta vermelha é praticamente **horizontal** — cai apenas 2,58 pontos ao
  longo de toda a amplitude de PIB (de R$ 20 mil a R$ 270 mil). Visualmente,
  é um risco quase plano em y ≈ 20.
- A **banda de confiança** é estreita (erro-padrão residual 3,19 com n=37).
- Pontos **cinza (treino)** concentrados à esquerda (PIB baixo), com 4 pontos
  isolados à direita (Cubatão no treino: 170k, 171k, 249k, 250k).
- Pontos **laranja (teste)** espalhados à esquerda, com **2 Cubatão à
  direita** (171k e 270k).
- Os pontos de mortalidade alta (28–33 no teste, em 2022) ficam **muito
  acima da faixa vermelha** — a reta não os alcança.
- Os 2 Cubatão do teste (mortalidade 16,7 e 18,1) ficam **abaixo** da reta,
  que prevê ≈ 18,5–19 para eles.

**Mensagem visual:** a reta "não aprendeu" a subir ou descer. Ela apenas
passa no meio da nuvem, e qualquer ponto com mortalidade muito acima ou
abaixo da média fica fora da banda. É o retrato de um modelo que só reproduz
a média do treino.

## 6. Gráfico 2 — Previsto vs. real

![](https://raw.githubusercontent.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/main/estrutura/scriptsR/figuras/fig3_linear_previsto_real.png)

### 6.1 Comparação das amplitudes

| Estatística | Previsões | Real |
|-------------|-----------|------|
| Mínimo | 17,36 | 14,65 |
| Mediana | 19,78 | 19,26 |
| Máximo | **19,93** | **33,00** |
| **Amplitude** | **2,56** | **18,35** |
| Razão real/previsto | — | **7,16** |
| Correlação previsto × real | — | **0,348** |

### 6.2 Os 5 maiores erros absolutos no teste

| Município | Ano | PIB (R$) | Real | Previsto | Erro |
|-----------|-----|----------|------|----------|------|
| Mongaguá | 2022 | 22.113 | 33,00 | 19,93 | **+13,07** |
| Itanhaém | 2022 | 22.777 | 28,21 | 19,92 | **+8,29** |
| Peruíbe | 2022 | 35.474 | 27,37 | 19,79 | **+7,58** |
| Bertioga | 2024 | 42.939 | 15,05 | 19,71 | −4,67 |
| Santos | 2018 | 86.963 | 14,65 | 19,26 | −4,61 |

### 6.3 O que a figura mostra

- Os pontos azuis estão **espremidos verticalmente** entre 17,4 e 19,9
  (faixa das previsões).
- Horizontalmente, se esticam de 14,6 a 33,0 (faixa do real).
- Resultado visual: uma **faixa horizontal fina** de pontos, **não** uma
  nuvem diagonal.
- A diagonal tracejada vermelha (identidade y = x) **corta** essa faixa:
  os pontos com real ≈ 19–20 caem perto da diagonal (acerto); os de real
  28–33 ficam **muito abaixo** dela (o modelo subestima); os de real 14–15
  ficam **acima** (superestima).
- **Os 5 maiores erros revelam um padrão:** três são de **2022** (Mongaguá,
  Itanhaém, Peruíbe) — ano com mortalidade anormalmente alta na região, que
  o modelo treinado em anos "normais" não conseguiu prever. Os outros dois
  são municípios com mortalidade muito baixa (Bertioga 2024, Santos 2018),
  que o modelo superestimou.

**Mensagem visual:** se o modelo fosse bom, os pontos seguiriam a diagonal.
Aqui eles formam uma linha horizontal que ignora completamente a variação
real — o mesmo que "chutar a média" para todo mundo. É a imagem do
**subajuste crônico**. A razão de amplitudes (7,16) quantifica o achatamento:
as previsões têm 1/7 da variabilidade do real.

## 7. Sensibilidade — sem Cubatão

| Modelo | R² treino | R² teste | RMSE teste |
|--------|-----------|----------|------------|
| Com Cubatão | 0,0347 | **0,0188** | 4,8186 |
| **Sem Cubatão** | **0,2774** | **−0,0224** | 5,1142 |

**Este é o resultado mais informativo do script.** Dois movimentos opostos:

1. **R² de treino dispara** (0,035 → 0,277). Era o esperado: sem o ponto
   extremo, a relação renda-mortalidade fica muito mais clara dentro do
   treino. Mesmo achado do script 1 (R² de 0,06 → 0,31 sem Cubatão).

2. **R² de teste despenca para NEGATIVO** (0,019 → −0,022). Não era o
   esperado.

### 7.1 Por que o R² de teste é negativo?

R² negativo significa: **as previsões do modelo são piores que simplesmente
chutar a média do teste**. Como isso pode acontecer se o R² de treino subiu?

**Por causa de onde Cubatão caiu no split.** As duas observações de Cubatão
estão no **teste** (2018 e 2024). O modelo sem Cubatão é treinado numa
amostra em que PIB e mortalidade são fortemente negativamente correlacionados
— ele aprende que **PIB alto → mortalidade baixa**. Ao prever as duas
observações de Cubatão no teste:

- PIB muito alto → modelo prevê mortalidade muito baixa.
- Mas Cubatão tem mortalidade **na média** (16,7 e 18,1).
- Erro de previsão relativamente grande → penaliza o R².

**Resumo:** o R² negativo **não contradiz** o achado do script 1. Ele
confirma que Cubatão é atípico — o modelo aprende uma regra que Cubatão
viola. Quando Cubatão aparece no teste, a regra falha justamente nele.

## 8. Discussão

### 8.1 Conclusão principal

O modelo **não sobreajusta** (R² treino ≈ R² teste) mas **subajusta
cronicamente** — PIB per capita isolado explica pouco da mortalidade nesta
amostra. O desempenho out-of-sample é modesto e coerente com o R² baixo da
amostra completa (script 1).

### 8.2 O papel de Cubatão (reforço do script 1)

A análise de sensibilidade revela um **trade-off explícito**:

- **Sem Cubatão no treino:** o sinal fica forte (R² treino = 0,28). Mas
  como Cubatão ainda aparece no teste, o modelo treinado **sem saber do
  fenômeno de Cubatão** faz previsões ruins para ele → R² teste negativo.

- **Com Cubatão no treino:** o sinal é mascarado (R² treino = 0,035), mas o
  modelo "sabe" que existe um caso atípico → prevê melhor no teste
  (R² teste = 0,019).

Ou seja: **remover Cubatão não é solução mágica**. Ele contamina de formas
diferentes dependendo de onde cai. A leitura honesta é que Cubatão é um
fenômeno substantivo, não um ponto a ser deletado — e um modelo que ignore
sua existência paga o preço em validação out-of-sample.

### 8.3 Sobre os erros grandes de 2022

Três dos cinco maiores erros são de 2022 (Mongaguá, Itanhaém, Peruíbe). Isso
sugere um **fator comum temporal** — possivelmente relacionado ao período
pós-pandemia — que o modelo não captura. É um lembrete de que, em painéis,
efeitos de ano podem ser relevantes e deveriam ser tratados (efeitos fixos
de tempo) numa análise mais completa.

### 8.4 Limitações estruturais

1. **Amostra pequena.** Com 37/17, cada métrica tem variância enorme. Um
   único ponto (no caso, Cubatão) muda drasticamente o R² de teste.

2. **Split por linha, não por unidade.** O mesmo município aparece em
   treino e teste em anos diferentes — parte da "identidade" do município
   vaza entre conjuntos. Isso **infla artificialmente** o desempenho em
   painéis reais. O split correto em painéis é por **município** (deixar
   todos os anos de um município em um lado só).

3. **Autocorrelação temporal.** Anos consecutivos do mesmo município são
   correlacionados. O OLS ignora isso.

4. **Instabilidade do R² negativo.** O R² negativo aqui é consequência de
   2 pontos. Não deve ser lido como prova de que o modelo é "pior que a
   média" universalmente — é uma observação local, dependente do split.

### 8.5 Direções de aprofundamento

- Split por município (`leave-one-municipality-out`).
- Validação cruzada k-fold agrupada por município.
- Modelos com efeitos fixos por município.
- Efeitos fixos de ano (dada a concentração de erros em 2022).
- Mais preditores (educação, saneamento, estrutura etária).

## 9. Amarração

- Split idêntico ao script 4 (mesmo seed, mesma chamada) — permite comparar
  linear e logística nas **mesmas** 17 observações de teste.
- Mesma especificação do script 1 (`mortalidade ~ PIB`).
- O achado central — **Cubatão mascara a relação renda–saúde** — é
  transversal aos scripts 1, 2, 3 e 4, e sustenta a conclusão consolidada.