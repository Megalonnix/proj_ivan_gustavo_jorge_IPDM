# Regressão Linear — Treino/Teste (70/30)

## 1. Objetivo

O ajuste sobre a amostra completa (script 1) mede o quanto o modelo
descreve os dados que ele mesmo viu. Aqui interessa outra pergunta: **o
modelo generaliza?** Para isso, separa-se a amostra em treino (70%) e teste
(30%), ajusta-se apenas no treino e mede-se o erro de previsão no conjunto
de teste — que o modelo não viu.

## 2. Split

    set.seed(42)
    idx_treino <- sample(seq_len(n), size = floor(0.7 * n))

- 54 observações → **38 treino / 16 teste**.
- `set.seed(42)` garante reprodutibilidade.
- **O mesmo split é usado no script 4**, o que torna a comparação entre
  regressão linear e logística legítima (mesmos municípios/anos no teste).

## 3. Ajuste no treino

Mesma especificação do script 1 (`mortalidade_60_69 ~ pib_per_capita`),
ajustada somente sobre as 38 observações do treino. O `summary()` do modelo
de treino dá os coeficientes e o R² intramostral.

## 4. Desempenho no teste

Métricas de erro fora da amostra:

- **RMSE** — raiz do erro quadrático médio, na mesma unidade do alvo
  (por mil habitantes). Penaliza erros grandes mais que o MAE.
- **MAE** — erro absoluto médio, mais robusto a outliers que o RMSE.
- **R² no teste** — coeficiente de determinação calculado comparando as
  previsões aos valores observados *no teste*, tendo como baseline a média
  do teste.

A comparação entre o R² no treino e o R² no teste é o que revela o grau de
sobreajuste. Com apenas um preditor e 38 pontos, o sobreajuste tende a ser
pequeno — o risco aqui é o oposto: **subajuste**, já que o PIB explica pouco
da mortalidade mesmo dentro da amostra.

![](https://raw.githubusercontent.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/main/estrutura/scriptsR/figuras/fig3_linear_teste_reta.png)

A reta foi ajustada **apenas com os pontos cinza (treino)**; os pontos
laranja (teste) foram sobrepostos depois. Se a reta descrevesse bem o
fenômeno, os pontos de teste ficariam próximos dela — a dispersão visível
quantifica a limitação do modelo.

![](https://raw.githubusercontent.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/main/estrutura/scriptsR/figuras/fig3_linear_previsto_real.png)

Previsto vs. real. Quanto mais próximos da diagonal, melhor. Desvios
sistemáticos (nuvem acima ou abaixo da linha) indicariam viés; dispersão
vertical indica erro aleatório.

## 5. Discussão

O desempenho fora da amostra tende a ser **modesto e coerente com o R²
baixo** do modelo full. Isso é informativo: não se trata de um artefato de
sobreajuste, e sim de uma limitação real do preditor único. Um modelo com
múltiplos preditores (educação, saneamento, estrutura etária, acesso a
saúde) provavelmente capturaria mais variabilidade — direção natural de
expansão.

Ressalva metodológica importante: o split é **aleatório por linha**, o que
pode colocar anos do mesmo município em treino e teste simultaneamente. Em
painéis, o split por unidade (município) costuma ser mais rigoroso. Como o
objetivo aqui é didático e a amostra é pequena, mantém-se o split por linha,
com a ressalva registrada.