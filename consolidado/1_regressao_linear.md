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

## 2. Especificação

Modelo linear simples, estimado por Mínimos Quadrados Ordinários:

    Y_i = β0 + β1 · X_i + ε_i ,   ε_i ~ N(0, σ²)

- Y = taxa de mortalidade 60–69 (por mil hab.)
- X = PIB per capita (R$ de 2024)

## 3. Ajuste

O coeficiente angular é **negativo** (β1 ≈ −1,62 × 10⁻⁵), consistente com a
hipótese teórica. Na prática: cada R$ 1.000 adicionais de PIB per capita
reduzem a taxa de mortalidade 60–69 em aproximadamente 0,016 por mil
habitantes. Ao longo da faixa observada na amostra (~R$ 20 mil a ~R$ 270 mil),
o efeito acumulado é da ordem de 4 pontos por mil — magnitude substantiva,
ainda que o intervalo de confiança de 95% para β1 toque o zero.

O **R²** é de aproximadamente 0,06 — o PIB per capita, isoladamente, explica
cerca de 6% da variabilidade da mortalidade. Isso é esperado: a mortalidade
nessa faixa é influenciada por muitos fatores (acesso a saúde, composição
etária, morbidade prévia, escolaridade, saneamento), e um preditor único
nunca dá conta do fenômeno. O p-valor do coeficiente (≈ 0,069) fica no limiar
convencional de 5% — evidência sugestiva, não conclusiva, o que é coerente com
o tamanho amostral efetivo e com a estrutura de painel.

## 4. Diagnósticos

![](https://raw.githubusercontent.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/main/estrutura/scriptsR/figuras/fig1_linear_dispersao.png)

Dispersão, reta OLS e banda de confiança de 95%. A relação é negativa mas
ruidosa: há considerável heterogeneidade em torno da reta, coerente com o R²
baixo.

![](https://raw.githubusercontent.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/main/estrutura/scriptsR/figuras/fig1_linear_residuos.png)

Resíduos vs. ajustados. A ausência de curvatura sistemática indica que a
especificação linear não está grosseiramente errada. Eventual padrão em funil
apontaria heterocedasticidade.

![](https://raw.githubusercontent.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/main/estrutura/scriptsR/figuras/fig1_linear_qq.png)

QQ-plot dos resíduos. O teste de Shapiro-Wilk no output dá o veredito formal
sobre a normalidade — premissa relevante para a validade dos testes t e F em
amostras pequenas.

## 5. Discussão e limitações

A estrutura de **painel** (9 municípios × 6 anos, mas apenas 9 unidades
verdadeiramente independentes) viola a premissa de observações i.i.d. Os
testes formais são, portanto, **indicativos**, não provas rigorosas. Uma
alternativa seria especificar efeitos fixos por município ou agrupar
erros-padrão por cluster — fora do escopo deste trabalho, mas registrado
como direção natural de aprofundamento.

Ainda assim, o sinal do coeficiente é o que a teoria prevê, e a leitura
conjunta com a regressão logística (script 2) e com o exercício de
treino/teste (scripts 3 e 4) permite discutir robustez.