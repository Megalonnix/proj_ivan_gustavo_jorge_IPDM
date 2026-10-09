# Atividade 08 — Regularização: quando menos é mais

> **Este documento é o resultado do script**
> [`estrutura/scriptsR/08-regularizacao.R`](https://github.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/blob/main/estrutura/scriptsR/08-regularizacao.R).
> O script produz os números; este consolidado é a leitura humana deles —
> com o porquê das decisões e o que aprender com cada resultado.

> **Alvo:** `mortalidade_60_69`. Predictores válidos (excluídos `ipdm` e `longevidade`).  
> **Baseline herdado:** RMSE = 3,6782 (média do treino).

## A resposta técnica a um problema antigo

Chegamos à última atividade do ciclo. O diagnóstico que se acumulou nas anteriores é claro:

- **n = 54** é pequeno.
- **p = 7** preditores é razoável — mas n/p = 7,7 não é confortável.
- **Sinal é fraco.** Correlações baixas, coeficientes não significativos, AUC perto de 0,5.
- **Modelos complexos explodem.** O polinômio de grau 12 da atividade 07 é o retrato disso.

Se você quer colocar muitos preditores num modelo, com sinal fraco e n pequeno, o MQO (Mínimos Quadrados Ordinários) simplesmente **não é a ferramenta certa**. Ele vai estimar coeficientes com variância alta — alguns vão parecer grandes, outros vão virar o sinal, e nada disso é confiável.

A **regularização** é a resposta técnica a esse problema. A ideia central é: em vez de deixar o modelo livre para escolher qualquer coeficiente, **imponha um custo** para coeficientes grandes. Isso "encolhe" as estimativas na direção de zero, reduz a variância, e geralmente melhora o desempenho em dados novos — à custa de um pequeno viés.

Existem três sabores:

- **Ridge (L2):** penaliza a **soma dos quadrados** dos coeficientes. Encolhe todos na direção de zero, sem zerar nenhum.
- **Lasso (L1):** penaliza a **soma dos valores absolutos**. Encolhe e **zera** alguns — faz seleção de variáveis.
- **ElasticNet:** mistura de L1 e L2, com um parâmetro α entre 0 e 1.

## Expansão: ainda mais preditores

Antes de regularizar, o script **expande** o conjunto original:

    escolaridade2       = escolaridade²
    distorcao_x_esc     = distorcao_em × escolaridade

Isso leva o modelo de 5 para **7 preditores**, adicionando um termo quadrático (para captar não-linearidade) e uma interação (para captar efeito conjunto). Não expandimos mais porque, com n = 54, mais termos = mais risco.

## A referência: MQO de sempre

Primeiro, o MQO nos 7 preditores, como régua:

    R²      = 0,229
    R² aj   = 0,1117

O R² ajustado de 0,11 é o primeiro sinal de fumaça. R² ajustado penaliza por número de preditores — e ele cai de 0,229 para 0,112. Ou seja, dos 22,9% da variação explicada pelo modelo, boa parte vem apenas de ter **usado mais variáveis**, não de sinal real.

## As três curvas em U

A regularização se dá via um parâmetro **λ** (lambda):

- **λ = 0:** nenhuma penalidade. Cai no MQO.
- **λ → ∞:** penalidade infinita. Todos os coeficientes viram zero (só resta o intercepto).
- **λ ótimo:** algum ponto no meio.

O **gráfico de validação cruzada** (cv.glmnet) plota, para cada λ, o erro de CV. O resultado é uma **curva em U**: erro alto para λ pequeno (variância), erro alto para λ grande (viés), mínimo em algum lugar no meio.

Existem duas escolhas de λ:

- **λ.min:** o valor que minimiza o erro de CV. Mais agressivo, mas pode sobreajustar o próprio CV.
- **λ.1se:** o maior λ cujo erro está a **1 erro-padrão** do mínimo. Mais conservador — a regra do 1 SE prefere modelos mais parcimoniosos quando a perda é compatível com ruído.

O script adota **λ.1se** por princípio: em problemas com sinal fraco, prefira o modelo mais simples.

### Resultados da CV

| Modelo | λ.min | MSE.min | λ.1se |
|---|---|---|---|
| Ridge (α=0) | 5,6484 | 14,1445 | **1500,2667** |
| ElasticNet (α=0,5) | 1,2989 | 14,5705 | 3,0005 |
| Lasso (α=1) | 0,5392 | 14,1402 | 1,5003 |

Observação crucial: o **λ.1se do Ridge é 1500**, contra 1,5 do Lasso. Por que essa diferença tão grande?

Porque Ridge **nunca zera** coeficientes. Para levar o erro a 1 SE do mínimo, ele precisa encolher **muito** os coeficientes — daí um λ gigantesco. Lasso consegue o mesmo efeito zerando alguns coeficientes com λ pequeno. É uma diferença estrutural entre as duas penalidades.

Compare com o **MSE do baseline** (média do treino): (3,6782)² ≈ 13,53. O MSE.min de todos os três regularizados está em torno de 14,1–14,6 — **acima do baseline**. Ou seja, a própria CV já está dizendo que nenhum deles bate a média.

## Os coeficientes no λ.1se: uma pegadinha visual

Aqui vale uma nota didática. Olhe os coeficientes do Ridge em λ.1se:

```
--- Ridge ---
                lambda.1se
(Intercept)        19.9056
escolaridade        0.0000
escolaridade2       0.0000
distorcao_em        0.0000
distorcao_x_esc     0.0000
pib_per_capita      0.0000
riqueza             0.0000
ano                 0.0000
```

Todos aparecem como 0,0000! Mas na linha seguinte o script diz:

```
Sobreviventes Ridge: (Intercept), escolaridade, escolaridade2, distorcao_em, distorcao_x_esc, pib_per_capita, riqueza, ano
```

**Contradição?** Não. É **arredondamento**. Os coeficientes não são exatamente zero — são valores minúsculos (tipo 0,00001) que, arredondados para 4 casas, viram 0,0000. A lista de sobreviventes testa `!= 0` **sem arredondar**, então pega esses valores minúsculos.

Esse é um momento precioso para entender a diferença entre Ridge e Lasso:

- **Ridge:** encolhe **todos** os coeficientes na direção de zero, mas **nenhum chega a zero**. Os coeficientes ficam vivos (na lista de sobreviventes), mas amordaçados.
- **Lasso:** encolhe **e zera**. De fato, aqui zerou tudo: só `(Intercept)` sobreviveu. É seleção radical.

O Lasso com λ.1se = 1,5 decidiu que **nenhum** preditor vale o custo. E isso é uma resposta — não um fracasso.

## Curvas em U e trilhas: as três figuras

### Figura 1 — Curva em U do Lasso

![Curva de validação cruzada do Lasso: erro em função de log(λ), com marcações de λ.min e λ.1se](https://raw.githubusercontent.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/main/estrutura/scriptsR/figuras/08-regularizacao_img1.png)

No eixo X está log(λ). No eixo Y, o erro de CV (deviance). Os pontos vermelhos são as médias; as barras de erro verticais, o erro-padrão.

O que observar:

1. **A curva desce, atinge um mínimo e volta a subir.** Formato em U clássico.
2. **As duas linhas verticais** marcam λ.min (mais à esquerda) e λ.1se (mais à direita). A escolha de λ.1se é deliberadamente mais conservadora.
3. **A região plana no meio** indica que a perda em adotar um λ mais agressivo é pequena — o que justifica preferir o λ.1se pelo princípio da parcimônia.

No caso do Lasso, a curva à esquerda (λ pequeno) tem mais variação — o modelo fica instável com muitos preditores vivos. É exatamente o problema que a regularização combate.

### Figura 2 — Curva em U do Ridge

![Curva de validação cruzada do Ridge: erro em função de log(λ), com marcações de λ.min e λ.1se](https://raw.githubusercontent.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/main/estrutura/scriptsR/figuras/08-regularizacao_img2.png)

Mesma estrutura, mas agora para Ridge. A diferença visual mais marcante:

1. **A curva do Ridge é mais suave** — porque sem zeramento, o efeito do λ é mais gradual.
2. **λ.1se está muito à direita** (1500, contra 1,5 do Lasso). A curva à direita é quase plana; a 1 SE, não custa nada escolher um λ altíssimo.
3. **O mínimo é próximo**, mas o λ que o atinge é bem menor que o λ.1se. A regra do 1 SE deu uma margem enorme ao Ridge.

Comparar as duas figuras lado a lado é didático: mostra como a forma de cada penalidade se reflete na curva.

### Figura 3 — Trilhas de coeficientes

![Trilhas de coeficientes do Ridge (esquerda) e do Lasso (direita), com λ no eixo X](https://raw.githubusercontent.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/main/estrutura/scriptsR/figuras/08-regularizacao_img3.png)

Aqui está a figura mais reveladora. Duas trilhas, uma ao lado da outra.

- **Eixo X:** λ (em escala log).
- **Eixo Y:** valor do coeficiente.
- **Cada linha colorida:** um preditor.

**Ridge (esquerda):** as linhas descem suavemente em direção ao zero à medida que λ cresce, mas **nenhuma toca o zero**. Elas convergem assintoticamente. É o comportamento "encolher sem zerar".

**Lasso (direita):** as linhas descem **e desaparecem** uma por uma. Quando um coeficiente bate em zero, ele fica lá — não volta. Isso é "encolher e zerar". No final, se λ for grande o suficiente, sobra apenas o intercepto.

Essa figura, mais que qualquer outra, **explica visualmente a diferença entre L1 e L2**. É a peça que costuma ficar abstrata em livros.

## O teste final: 70/30

Depois de toda a análise de CV, um teste cego de verdade: separar 70% (treino), ajustar os três modelos, e medir RMSE nos 30% restantes.

| Modelo | RMSE |
|---|---|
| Baseline (média treino) | 3,6782 |
| **MQO** | **3,6363** |
| Ridge (1se) | 3,6782 |
| Lasso (1se) | 3,6782 |

Leia com calma, porque o resultado é quase cômico.

**MQO ganha.** Por uma margem minúscula (3,6363 vs 3,6782), mas ganha. Ou seja, o modelo não-regularizado teve o melhor desempenho no teste. Ironicamente, a regularização — que era para ajudar — atrapalhou ligeiramente.

**Ridge e Lasso empataram com o baseline.** Ambos deram RMSE 3,6782, idêntico ao "prever sempre a média do treino". Isso acontece porque, com λ.1se tão agressivo, ambos os modelos essencialmente **zeraram tudo** e passaram a prever a média. Um modelo que prevê a média dá exatamente o RMSE do baseline.

Ou seja: a escolha de λ.1se, que era para ser conservadora e preferir simplicidade, foi **tão** conservadora que os modelos regularizados viraram o baseline. Não aprenderam nada.

Esse é um resultado honesto e importante. A regularização é uma técnica poderosa — **quando há sinal a ser regularizado**. Aqui, não há. Com sinal fraco e n pequeno, a penalidade atrapalha mais que ajuda.

## Síntese: o fecho do ciclo

Cinco conclusões.

**Primeira: regularização não é mágica.** Ela controla variância, não cria sinal. Se o sinal é fraco, ela encolhe o pouco que existe na direção de zero — podendo zerar tudo.

**Segunda: λ.1se é conservador por princípio, mas pode ser conservador demais.** No Ridge, com λ = 1500, foi. O modelo virou baseline. Se adotássemos λ.min, talvez houvesse mais sinal — mas também mais variância. É o trade-off clássico.

**Terceira: Ridge encolhe; Lasso zera.** A figura 3 mostra isso com clareza. Os coeficientes do Ridge são minúsculos mas não nulos. Os do Lasso desaparecem.

**Quarta: MQO venceu — mas por muito pouco.** RMSE 3,6363 vs 3,6782 do baseline. Uma diferença de 1,1%. Isso não é "MQO é bom"; é "todos os modelos são equivalentes ao baseline".

**Quinta: o ciclo terminou com uma resposta honesta, não com um troféu.** As oito atividades convergiram para a mesma conclusão: **neste recorte (Baixada Santista, 9 municípios, 6 anos), mortalidade 60–69 é praticamente imprevisível a partir das variáveis disponíveis.** Isso não é fracasso — é a descoberta.

O que fica desta atividade:

1. **MQO referência:** R² = 0,229; R² aj = 0,1117.
2. **λ.1se:** Ridge 1500,2667; ENet 3,0005; Lasso 1,5003.
3. **Ridge sobreviventes:** todos os 7 preditores (minúsculos, mas não zero). **Lasso sobreviventes:** só o intercepto.
4. **Teste RMSE:** Baseline 3,6782; MQO 3,6363; Ridge 3,6782; Lasso 3,6782.
5. **Regularização não melhorou** — virou baseline por agressividade de λ.
6. **Três figuras didáticas:** duas curvas em U, uma trilha comparativa.

## Balanço final do projeto (01–08)

Depois de oito atividades, um resumo do que aprendemos sobre o problema:

- **O alvo é `mortalidade_60_69`**, não o IPDM (que é circular).
- **n = 54 é pequeno.** Parcimônia e regularização são obrigatórias.
- **Sinal é fraco.** Correlações baixas, coeficientes não significativos.
- **Modelos simples (MQO) e complexos (polinômios grau 12) ficam perto ou pior que o baseline.**
- **Regressão logística** também fica próxima do chute, embora o modelo B (com `distorcao_em`) tenha dado AUC 0,68 na CV — o melhor resultado do projeto.
- **Regularização** não salvou — encolheu tudo.
- **A conclusão honesta:** com este recorte, não há sinal preditivo forte. Outra modelagem, outro recorte geográfico ou temporal, ou variáveis adicionais seriam necessários para uma previsão útil.

Isso não é um resultado empolgante. Mas é um resultado **rigoroso** — e a postura correta em um projeto científico é justamente resistir à tentação de maquiar um "não" em um "sim" com casas decimais.

---

## Documentos complementares

**Script que gera este consolidado:**
- 🧮 [`08-regularizacao.R`](https://github.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/blob/main/estrutura/scriptsR/08-regularizacao.R) — **a fonte** deste documento.

**Demais documentos relacionados:**
- 📋 [Relatório técnico do script (`08-regularizacao.md`)](https://github.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/blob/main/estrutura/scriptsR/08-regularizacao.md) — output bruto, sem a camada didática.
- 📎 [Consolidado 01 — Dicionário de variáveis](https://github.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/blob/main/consolidado/01-dicionario-variaveis.md).
- 📎 [Consolidado 02 — Análise exploratória](https://github.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/blob/main/consolidado/02-analise-exploratoria.md).
- 📎 [Consolidado 03 — Regressão linear](https://github.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/blob/main/consolidado/03-regressao-linear.md).
- 📎 [Consolidado 04 — Regressão logística](https://github.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/blob/main/consolidado/04-regressao-logistica.md).
- 📎 [Consolidado 05 — Treino/teste (regressão)](https://github.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/blob/main/consolidado/05-regressao-linear-treino-teste.md).
- 📎 [Consolidado 06 — Classificação honesta](https://github.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/blob/main/consolidado/06-regressao-logistica-treino-teste.md).
- 📎 [Consolidado 07 — Reamostragem](https://github.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/blob/main/consolidado/07-reamostragem.md).
- 📊 [Banco de dados (CSV)](https://github.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/blob/main/estrutura/bancoDeDados/df_ipdm_baixada_por_municipio.csv).
- 📄 [Dicionário de dados (PDF)](https://github.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/blob/main/estrutura/dicionario/dicionario_ipdm_baixada.pdf).