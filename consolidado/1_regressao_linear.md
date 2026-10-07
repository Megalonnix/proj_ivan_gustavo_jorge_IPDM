
# Regressão Linear — Mortalidade 60–69 × PIB per capita

## 1. Objetivo

Quantificar, na amostra completa (9 municípios × 6 anos = 54 observações), a
relação entre o Produto Interno Bruto per capita e a taxa de mortalidade na
faixa de 60 a 69 anos (por mil habitantes) na Região Metropolitana da Baixada
Santista.

A hipótese teórica é a de que **maior renda per capita se associa a menor
mortalidade** — relação amplamente documentada na literatura de economia da
saúde. O par alvo/preditor foi deliberadamente escolhido por não apresentar
sobreposição estrutural dentro da metodologia do IPDM: o PIB per capita é
componente da dimensão *Riqueza*; a mortalidade 60–69 é componente da dimensão
*Longevidade*. São ramos distintos da árvore metodológica, o que elimina
circularidade e data leakage.

Este script cobre a tarefa da **Aula 4**: regressão simples, interpretação do
coeficiente, R², gráfico da reta ajustada, **regressão múltipla com comparação
de R²** e diagnóstico por resíduos. Inclui, adicionalmente, uma análise de
**sensibilidade ao outlier de alta alavancagem** (Cubatão) — que se revelou o
achado mais informativo do módulo.

## 2. Especificação

Modelo linear simples, estimado por Mínimos Quadrados Ordinários:

    Y_i = β0 + β1 · X_i + ε_i ,   ε_i ~ N(0, σ²)

- Y = taxa de mortalidade 60–69 (por mil hab.)
- X = PIB per capita (R$ de 2024)

Como a escala do PIB é grande (dezenas a centenas de milhares de reais), o
coeficiente β₁ por real é naturalmente minúsculo. A leitura substantiva é
feita **por R$ 1.000 adicionais**, isto é, Δ mortalidade = 1000 · β₁.

## 3. Ajuste — modelo simples

Na amostra completa, o coeficiente angular é **negativo**
(β₁ = −1,62 × 10⁻⁵), consistente com a hipótese teórica: cada R$ 1.000
adicionais de PIB per capita reduzem a taxa de mortalidade 60–69 em
aproximadamente 0,016 por mil habitantes.

O **R² = 0,062** — o PIB per capita, isoladamente, explica apenas ~6% da
variabilidade da mortalidade. O p-valor do coeficiente (≈ 0,069) fica no
limiar convencional de 5%. À primeira vista, evidência fraca.

**Esta leitura, porém, esconde o achado principal.** A seção 6 mostra que um
único ponto — Cubatão — distorce o resultado na amostra completa.

## 4. Diagnósticos do modelo simples

![](https://raw.githubusercontent.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/main/estrutura/scriptsR/figuras/fig1_linear_dispersao.png)

Dispersão, reta OLS e banda de confiança de 95%. A relação é negativa mas
ruidosa. **Note o ponto isolado à direita** — é Cubatão, com PIB muito acima
do resto e mortalidade na média. É esse ponto que puxa a reta para cima e
achata a inclinação.

![](https://raw.githubusercontent.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/main/estrutura/scriptsR/figuras/fig1_linear_residuos.png)

Resíduos vs. ajustados. Sem curvatura sistemática grosseira, mas o ponto
extremo à direita se destaca.

![](https://raw.githubusercontent.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/main/estrutura/scriptsR/figuras/fig1_linear_qq.png)

QQ-plot dos resíduos. O teste de Shapiro-Wilk no output dá o veredito formal
sobre normalidade — premissa relevante para a validade dos testes t e F em
amostras pequenas.

## 5. Regressão múltipla

Adiciona-se `distorcao_em` (taxa de distorção idade-série no Ensino Médio)
como segundo preditor, representando a dimensão *Escolaridade* do IPDM:

    Y_i = β0 + β1 · pib_per_capita_i + β2 · distorcao_em_i + ε_i

**Preditores deliberadamente excluídos** por circularidade/redundância:

- **Longevidade** — contém a própria mortalidade 60–69 (vazamento direto).
- **Riqueza** — contém o PIB per capita (redundância).
- **IPDM** — média das três dimensões; contém o alvo de forma indireta.

### Resultado

| Modelo | R² |
|--------|-----|
| Simples (PIB) | 0,0622 |
| Múltiplo (PIB + distorção EM) | 0,0933 |

O ganho é **modesto**: +0,031 em R². Isso sugere que `distorcao_em` e
`pib_per_capita` carregam informação parcialmente redundante (municípios mais
ricos tendem a ter menos distorção idade-série), de modo que o segundo
preditor pouco acrescenta **depois** que o primeiro já entrou. Em outras
palavras: a dimensão educacional, capturada pela distorção, não explica
mortalidade de forma independente da renda nesta amostra.

![](https://raw.githubusercontent.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/main/estrutura/scriptsR/figuras/fig1_mult_residuos.png)

Resíduos vs. ajustados do modelo múltiplo. Leitura análoga à do modelo
simples — nuvem sem padrão evidente, sem ganho visual dramático em relação
ao modelo com um preditor só.

## 6. Sensibilidade — modelo sem Cubatão (o achado principal)

Cubatão tem PIB per capita de ~R$ 170 mil a ~R$ 270 mil, muito acima dos
demais municípios (~R$ 20 mil a ~R$ 90 mil). É um ponto de **alta
alavancagem**. A decisão metodológica — registrada no script 0 — foi
**manter Cubatão no modelo principal** e apenas comparar, lado a lado, o
coeficiente estimado com e sem o município.

### Resultado

| Modelo | β₁ (PIB) | R² |
|--------|----------|-----|
| Com Cubatão | −1,62 × 10⁻⁵ | 0,062 |
| **Sem Cubatão** | **−1,30 × 10⁻⁴** | **0,311** |

**O impacto é dramático e é o achado substantivo deste módulo.**

Sem Cubatão:

- O coeficiente β₁ fica **~8× mais forte em módulo**.
- O R² **salta de 0,06 para 0,31** — a relação passa a explicar cerca de
  1/3 da variabilidade.

**Interpretação substantiva:** Cubatão tem PIB altíssimo, mas mortalidade
60–69 na **média dos demais municípios** (≈ 18–21 por mil em todos os anos).
Ele simplesmente **não segue a tendência negativa** PIB → mortalidade. Sua
presença na amostra:

1. Puxa a inclinação da reta para cima (em direção a zero).
2. Infla o erro residual e derruba o R².
3. Mascara uma relação que, sem ele, é bem mais clara.

**Por que isso importa:** o caso de Cubatão é substantivamente relevante, não
um mero artefato estatístico. Um município com PIB industrial altíssimo mas
mortalidade na faixa dos vizinhos mais pobres **contradiz a hipótese
renda–saúde** e merece discussão própria — provavelmente ligada à composição
populacional, exposição ambiental histórica (Cubatão tem histórico conhecido
de poluição industrial) ou acesso a serviços. Não é ruído: é um fenômeno a
explicar.

**Não removemos Cubatão do modelo principal.** O resultado com a amostra
completa é honesto e informativo: mostra que a relação renda–saúde é real
mas **sensível a um único caso atípico**. Reportar as duas versões é o que
torna o achado cientificamente defensável.

## 7. Discussão e limitações

### 7.1 Estrutura de painel

A estrutura de **painel** (9 municípios × 6 anos, mas apenas 9 unidades
verdadeiramente independentes) viola a premissa de observações i.i.d.
Observações do mesmo município ao longo do tempo são autocorrelacionadas.
Os testes formais são, portanto, **indicativos**, não provas rigorosas.

Alternativas naturais de aprofundamento (fora do escopo):

- **Efeitos fixos por município**: `lm(y ~ x + factor(Municipio))`.
- **Erros-padrão agrupados por município** (cluster-robust).
- **Erros-padrão robustos a heterocedasticidade** (HC3).

### 7.2 Conclusão substantiva

A leitura conjunta das duas versões (com e sem Cubatão) sustenta a seguinte
conclusão:

> **Existe uma associação negativa real entre PIB per capita e mortalidade
> 60–69 na Baixada Santista, mas ela é mascarada na amostra completa pela
> presença de Cubatão — um caso atípico em que renda alta não se traduz em
> mortalidade baixa.**

O sinal do coeficiente é o que a teoria prevê **em ambas as versões**. A
magnitude e o R², porém, dependem crucialmente do tratamento dado ao ponto
extremo. Esse tipo de sensibilidade é justamente o que justifica a leitura
cuidadosa dos resíduos e a análise de alavancagem — não para excluir o ponto,
mas para **entender o que ele revela sobre o fenômeno**.