# Atividade 03 — Regressão linear: quando o resultado honesto é "nada"

> **Este documento é o resultado do script**
> [`estrutura/scriptsR/03-regressao-linear.R`](https://github.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/blob/main/estrutura/scriptsR/03-regressao-linear.R).
> O script produz os números; este consolidado é a leitura humana deles —
> com o porquê das decisões e o que aprender com cada resultado.

> **Alvo:** `mortalidade_60_69` (mortes por mil hab., 60–69).  
> **Baseline herdado:** RMSE = 3,8504 (sd de Y).

## O primeiro modelo de verdade

Se a EDA da atividade 02 foi "andar pela cidade", a regressão linear é o primeiro experimento de laboratório. A ideia é simples: encontrar uma **reta** que melhor descreva como `mortalidade_60_69` muda em função de `escolaridade`.

O método se chama **MQO** (Mínimos Quadrados Ordinários). Em uma frase, ele escolhe a reta que minimiza a soma dos quadrados das distâncias verticais entre os pontos observados e a própria reta. Essas distâncias se chamam **resíduos**, e são o coração de toda a diagnose que faremos a seguir.

Antes de qualquer coisa, precisamos avisar o leitor: a partir daqui, os resultados serão honestos mesmo quando desconfortáveis. E nesta atividade eles serão bem desconfortáveis.

---

## Modelo simples: mortalidade ~ escolaridade

A equação ajustada foi:

    mortalidade_60_69 = 20,9266 + (−2,0959) × escolaridade

Traduzindo cada pedaço:

- **20,9266** é o intercepto. Seria a mortalidade prevista se a escolaridade fosse exatamente 0. Como escolaridade é um índice 0–1, esse valor é mais uma âncora matemática do que uma previsão substantiva.
- **−2,0959** é o coeficiente angular. A leitura literal: a cada +1 no índice de escolaridade, a mortalidade cairia 2,10 mortes por mil habitantes. E o sinal é **negativo** — mais educação, menos mortalidade. Isso está de acordo com a intuição.

Mas antes de comemorar, precisamos olhar os **erros-padrão** e o **valor-p**.

### O que a tabela de coeficientes realmente diz

| Termo | Estimativa | EP | t | p |
|---|---|---|---|---|
| Intercepto | 20,9266 | 4,1904 | 4,994 | 7,03×10⁻⁶ *** |
| `escolaridade` | −2,0959 | **8,5337** | **−0,2456** | **0,807** |

Vamos por partes, porque essa tabela merece ser lida devagar.

**O erro-padrão (EP) do coeficiente é 8,5337.** Ele mede a incerteza da estimativa. Um coeficiente estimado em −2,10 com erro-padrão de 8,53 é como um jogador dizendo "acho que são 5 pontos, mais ou menos uns 20, talvez". A estimativa existe, mas o ruído é enorme.

**A razão t** é a estimativa dividida pelo seu erro-padrão:

    t = −2,0959 / 8,5337 ≈ −0,2456

Em palavras: o coeficiente está a apenas **um quarto de erro-padrão** de distância de zero. Não é nem perto de ser distinguível do zero.

**O valor-p de 0,807** confirma: se a verdadeira relação entre escolaridade e mortalidade fosse nula, teríamos 80,7% de chance de observar um coeficiente tão ou mais extremo quanto o estimado. Ou seja, o dado é perfeitamente compatível com a hipótese "escolaridade não faz diferença".

### O que a intuição pedia vs. o que o dado mostrou

A teoria diz: mais educação → menos mortalidade adulta. Faz sentido sociológico, faz sentido histórico, faz sentido individual.

O dado deste recorte diz: **não detecto essa relação**.

Três explicações possíveis — todas honestas:

1. **A relação pode não ser linear.** Talvez escolaridade ajude a mortalidade, mas de forma curva, ou em conjunto com outra variável.
2. **O n é pequeno (54 observações) e a variação é grande.** Com pouco dado, o ruído pode engolir sinais reais.
3. **Neste recorte específico (Baixada Santista, 9 municípios, 6 anos), a relação realmente não existe.** Pode ser um caso em que a correlação histórica não se manifesta localmente.

A postura correta não é escolher a explicação mais confortável — é reportar o que vimos e seguir testando alternativas.

### Intervalo de confiança (analítico)

    IC 95% para β₁: [−19,2201; +15,0283]

Este é um intervalo de 95% de confiança para o verdadeiro coeficiente de escolaridade. Como ele é construído sob a hipótese de normalidade e homocedasticidade dos resíduos, é uma estimativa **paramétrica**.

Dois pontos:

- **O intervalo contém o zero** — ou seja, "nenhum efeito" é um valor plausível.
- **O intervalo é largo** — ele vai de "escolaridade reduz mortalidade em 19 por mil" a "escolaridade aumenta mortalidade em 15 por mil". Isso é o retrato visual de que não sabemos praticamente nada.

## R² e RSE: quanto o modelo explica

- **R² = 0,0012** — o modelo explica 0,12% da variação da mortalidade. Em outros termos: 99,88% da variação não é capturada pela escolaridade.
- **R² ajustado = −0,018** — após penalizar por ter usado uma variável, o valor fica **negativo**. Sinal claro de que o preditor não está pagando o próprio custo.
- **RSE (erro-padrão residual) = 3,885** — o desvio-padrão dos resíduos. Ele é o "erro típico" do modelo, em unidades do alvo.

Compare com o baseline:

    RSE_modelo = 3,885
    sd(Y)      = 3,8504

O modelo é **ligeiramente pior que só dizer a média**. Ou seja, a escolaridade não apenas deixa de ajudar — ela atrapalha um pouquinho, porque introduz ruído de estimativa.

---

## Bootstrap: e se não confiarmos na normalidade?

O IC analítico acima exige uma suposição forte: que os resíduos seguem uma distribuição normal. Se essa suposição estiver errada, o intervalo não vale muito.

O **bootstrap** é uma alternativa sem essa suposição. A ideia é engenhosamente simples: em vez de derivar uma fórmula matemática para a incerteza, **reamostramos os dados** várias vezes e observamos como o coeficiente varia de amostra para amostra.

Passos do bootstrap não-paramétrico:

1. Sorteie, **com reposição**, 54 observações dos seus próprios 54 dados originais.
2. Ajuste o modelo e guarde β₁ dessa reamostragem.
3. Repita 2.000 vezes.
4. Olhe a distribuição dos 2.000 β₁'s.

Resultado:

| Métrica | Valor |
|---|---|
| β₁ MQO | −2,0959 |
| EP analítico | 8,5337 |
| EP bootstrap | 7,9221 |
| IC 95% analítico | [−19,2201; 15,0283] |
| IC 95% bootstrap | [−18,8741; 11,8109] |
| 0 dentro do IC bootstrap? | **SIM** |

O EP bootstrap ficou próximo do analítico (7,92 vs 8,53) e as conclusões são as mesmas: **o intervalo contém zero**. 

A diferença fica na **assimetria**. O IC bootstrap é ligeiramente assimétrico — o limite superior (11,81) está mais próximo de zero que o limite inferior (−18,87). Isso é um eco da assimetria que vimos na distribuição do alvo (figura 1 da atividade 02). Quando os dados não são gaussianos, o bootstrap captura isso; o IC analítico, por construção, não.

Vale reforçar: bootstrap é uma técnica de reamostragem sem hipótese paramétrica. Ele **funciona bem** justamente em situações como a nossa — n pequeno, distribuição assimétrica, e desconfiança das suposições clássicas.

---

## As seis figuras — uma por vez

### Figura 1 — Reta ajustada e resíduos

![Dispersão escolaridade × mortalidade com reta ajustada e resíduos](https://raw.githubusercontent.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/main/estrutura/scriptsR/figuras/03-regressao-linear_img1.png)

Os pontos azuis são as observações. A reta laranja é a previsão do modelo. Os segmentos verdes verticais são os **resíduos** — a diferença entre o valor observado e o valor previsto para cada município-ano.

Repare em duas coisas:

1. **A reta é quase horizontal.** Corresponde visualmente ao β₁ ≈ −2,10 com intervalo de confiança cruzando zero.
2. **Os resíduos são grandes.** Se você medir visualmente, cada ponto está longe da reta. Isso é o RSE ≈ 3,89 que vimos antes: o modelo erra, em média, quase 4 mortes por mil.

### Figura 2 — Resíduos vs. ajustados (modelo simples)

![Resíduos vs valores ajustados para o modelo simples](https://raw.githubusercontent.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/main/estrutura/scriptsR/figuras/03-regressao-linear_img2.png)

Este gráfico é um dos **diagnósticos padrão** em regressão. Ele plota, para cada observação, o valor previsto no eixo X e o resíduo no eixo Y. A linha laranja tracejada marca o resíduo zero.

O que queremos ver: uma **nuvem aleatória** ao redor do zero, sem padrão. O que queremos evitar: **forma de funil** (heterocedasticidade — variância muda com o ajuste), **curvatura** (relação não linear) ou agrupamento (outliers).

Aqui o gráfico é honesto e um pouco triste: não há padrão forte, mas também não há sinal de qualidade. É o retrato de um modelo que não capturou nada — os resíduos não seguem a estrutura dos ajustados, mas isso é porque o modelo também não tem estrutura para seguir.

### Figura 3 — Viés-variância em três graus de polinômio

![Retas de graus 1, 2 e 4 sobrepostas](https://raw.githubusercontent.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/main/estrutura/scriptsR/figuras/03-regressao-linear_img3.png)

Aqui usamos polinômios: em vez de ajustar uma reta (grau 1), tentamos uma parábola (grau 2) e uma curva de quarto grau (grau 4). A motivação é o clássico **trade-off viés-variância**:

- Modelos muito simples (grau 1) têm **viés alto** — assumem uma forma que pode não corresponder à realidade.
- Modelos muito complexos (grau 4+) têm **variância alta** — ficam sensíveis ao ruído particular dos dados, e generalizam mal.

O resultado visual é didático:

- **Grau 1 (azul):** reta quase horizontal, sem flexibilidade.
- **Grau 2 (laranja):** uma curva suave, mas ainda disciplinada pelos dados.
- **Grau 4 (roxo):** uma curva que começa a "contar histórias" — passa por regiões que talvez sejam apenas ruído.

Em um projeto com n = 54 e sinal fraco, o grau 4 já está na zona de sobreajuste. Nenhum dos três resolve o problema fundamental (não há sinal linear claro), mas a figura ensina uma lição importante: **complexidade não é solução universal**.

### Figura 4 — Distribuição bootstrap de β₁

![Histograma dos β₁ bootstrap](https://raw.githubusercontent.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/main/estrutura/scriptsR/figuras/03-regressao-linear_img4.png)

O histograma mostra as 2.000 estimativas de β₁ obtidas via bootstrap. A linha roxa marca o β₁ pontual (−2,10), e as linhas laranjas tracejadas marcam os limites do IC 95% bootstrap ([−18,87; 11,81]).

O que observar:

- A distribuição é **larga** e centrada perto de zero (o valor "sem efeito").
- A forma é **aproximadamente simétrica**, mas levemente assimétrica à esquerda.
- As barras cobrem uma faixa enorme — de cerca de −25 a +15. Isso é o rosto visual da **incerteza** do coeficiente.

Se a escolaridade realmente afetasse mortalidade, veríamos uma distribuição bem mais estreita e deslocada para um lado. O que vemos é uma distribuição "preguiçosa", sem preferência clara.

### Figura 5 — Simples vs. múltipla

![Comparação entre reta simples e reta múltipla com distorção na média](https://raw.githubusercontent.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/main/estrutura/scriptsR/figuras/03-regressao-linear_img5.png)

Aqui entra a **regressão múltipla**: em vez de usar só escolaridade, adicionamos `distorcao_em` como segundo preditor. A ideia é que a distorção idade-série possa estar "escondendo" parte da relação com escolaridade.

O resultado foi ainda mais decepcionante que o modelo simples:

| Modelo | R² | R² aj | RSE |
|---|---|---|---|
| Simples (escolaridade) | 0,0012 | −0,0180 | 3,8850 |
| Múltipla (+ distorção) | 0,0170 | −0,0215 | 3,8916 |

A regressão múltipla ganhou um R² marginalmente maior (0,017 vs 0,0012), mas:

- O **R² ajustado** (que penaliza por adicionar preditores) ficou ainda mais negativo.
- O **RSE** aumentou em vez de diminuir.
- A **correlação entre escolaridade e distorção é −0,4531** — moderada e negativa. Ou seja, os dois preditores carregam informação parcialmente redundante, o que aumenta a variância dos coeficientes sem trazer sinal novo.

A figura mostra isso visualmente: as duas retas (laranja tracejada, simples; roxa, múltipla com distorção fixada na média) estão muito próximas. Adicionar o segundo preditor não mudou a história.

Vale dizer de novo, porque é importante: **a correlação entre preditores não é um problema por si só** — é um fato a ser registrado. Ela só se torna problemática (multicolinearidade) quando impede a interpretação dos coeficientes individuais. Aqui, dado que nenhum dos dois é significativo, o debate é quase acadêmico.

### Figura 6 — Resíduos vs. ajustados (modelo múltiplo)

![Resíduos vs ajustados para o modelo múltiplo](https://raw.githubusercontent.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/main/estrutura/scriptsR/figuras/03-regressao-linear_img6.png)

O mesmo diagnóstico da figura 2, agora para o modelo múltiplo. A conclusão é a mesma: sem padrão forte, sem estrutura visível. O modelo não está errado — está apenas vazio.

---

## Teste de Shapiro-Wilk: a normalidade dos resíduos

O teste de Shapiro-Wilk verifica se uma amostra vem de uma distribuição normal. Hipóteses:

- **H₀:** os resíduos seguem uma distribuição normal.
- **H₁:** os resíduos não seguem distribuição normal.

Resultados:

| Modelo | W | p | Leitura |
|---|---|---|---|
| Simples | 0,9399 | **0,00925** | Rejeita H₀ |
| Múltiplo | 0,9213 | **0,00168** | Rejeita H₀ |

Em ambos os casos, rejeitamos a normalidade. Isso significa que **as suposições clássicas do IC analítico não se sustentam**. Um dos motivos é a assimetria do alvo que vimos na atividade 02 (cauda longa à direita, puxada por municípios como Mongaguá 2022).

A consequência prática: **o IC analítico deste modelo deve ser lido com desconfiança**. É por isso que o bootstrap importa — ele oferece uma alternativa que não exige normalidade. E, sorte nossa, as conclusões convergiram: o intervalo contém zero nos dois métodos.

---

## Síntese: o resultado honesto é "não há sinal linear detectável"

Esta é uma atividade incômoda, porque o resultado é fraco. É importante aprender a ler esses momentos sem cair em duas tentações:

**Tentação 1 — Forçar o resultado.** "O β₁ é negativo, então escolaridade protege!" Não. O β₁ negativo é ruído em torno de zero. O IC contém zero. O R² é praticamente zero. Não há evidência para essa afirmação.

**Tentação 2 — Jogar tudo fora.** "Não achamos nada, essa pesquisa não presta." Errado. **Não achar** é uma resposta válida e valiosa. Ela mostra que, neste recorte específico, o efeito esperado não se manifesta — ou não se manifesta linearmente. Isso é informação para o leitor.

O que fica desta atividade:

1. **Modelo simples:** β₁ = −2,10 [IC 95%: −19,22 a 15,03]. Não significativo. R² = 0,0012.
2. **Modelo múltiplo:** adicionar distorção não ajudou. R² ajustado ficou ainda mais negativo.
3. **Bootstrap:** confirma o IC analítico. EP bootstrap 7,92 vs 8,53.
4. **Normalidade dos resíduos:** rejeitada em ambos os modelos.
5. **Viés-variância:** grau 4 já sobreajusta. Complexidade não resolve falta de sinal.

Não é o resultado bonito que um projeto gostaria de ter. Mas é o resultado que temos — e é honesto.

Próxima parada: e se o problema não for linear? A regressão logística muda a forma de perguntar e pode revelar relações que a reta não alcança.

---

## Documentos complementares

**Script que gera este consolidado:**
- 🧮 [`03-regressao-linear.R`](https://github.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/blob/main/estrutura/scriptsR/03-regressao-linear.R) — **a fonte** deste documento.

**Demais documentos relacionados:**
- 📋 [Relatório técnico do script (`03-regressao-linear.md`)](https://github.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/blob/main/estrutura/scriptsR/03-regressao-linear.md) — output bruto, sem a camada didática.
- 📎 [Consolidado 01 — Dicionário de variáveis](https://github.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/blob/main/consolidado/01-dicionario-variaveis.md).
- 📎 [Consolidado 02 — Análise exploratória](https://github.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/blob/main/consolidado/02-analise-exploratoria.md).
- 📊 [Banco de dados (CSV)](https://github.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/blob/main/estrutura/bancoDeDados/df_ipdm_baixada_por_municipio.csv).
- 📄 [Dicionário de dados (PDF)](https://github.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/blob/main/estrutura/dicionario/dicionario_ipdm_baixada.pdf).