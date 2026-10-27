# Atividade 02 — Diagnóstico, baseline e primeiros olhares

> **Este documento é o resultado do script**
> [`estrutura/scriptsR/02-analise-exploratoria.R`](https://github.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/blob/main/estrutura/scriptsR/02-analise-exploratoria.R).
> O script produz os números; este consolidado é a leitura humana deles —
> com o porquê das decisões e o que aprender com cada resultado.

> **Alvo:** `mortalidade_60_69` — mortes por mil habitantes na faixa 60–69.

## Antes de modelar, olhar em volta

Imagine que você acabou de chegar numa cidade desconhecida para fazer uma pesquisa de campo. A primeira coisa que você faz não é sair entrevistando gente — é andar pelos bairros, ver onde estão as coisas, entender o terreno. A Análise Exploratória de Dados (EDA) é exatamente isso para um banco de dados. Antes de pedir que um modelo nos diga algo, olhamos o que os próprios dados já têm a dizer.

Esta atividade faz quatro coisas, nesta ordem:

1. Mede a **correlação** de cada variável com o alvo — para saber quem *parece* relevante.
2. Checa a razão **n/p** — para saber se dá para modelar com folga ou com cuidado.
3. Verifica o **balanço** da variável binária — para saber se os dois grupos estão pareados.
4. Confirma se há **valores faltantes** — para saber se precisamos lidar com buracos.

E depois fixa os **baselines**: os números que qualquer modelo precisa bater para provar que vale a pena existir.

---

## Passo 1 — Correlações com o alvo

Correlação é uma medida que vai de −1 a +1 e resume como duas variáveis "andam juntas":

- Perto de **+1**: quando uma sobe, a outra tende a subir também.
- Perto de **−1**: quando uma sobe, a outra tende a descer.
- Perto de **0**: nenhuma relação linear aparente.

Ordenando do mais forte para o mais fraco em relação a `mortalidade_60_69`:

| Variável | Correlação | Leitura |
|---|---|---|
| `mortalidade_alta` | 0,7649 | É o próprio alvo binarizado — não conta como preditor |
| `longevidade` | 0,4901 | **Suspeita** — vamos discutir |
| `ipdm` | 0,3977 | **Suspeita** — vamos discutir |
| `riqueza` | 0,3933 | Candidata razoável |
| `pib_per_capita` | 0,2494 | Candidata fraca mas possível |
| `distorcao_em` | 0,1277 | Quase nada |
| `ano` | 0,0847 | Praticamente nada |
| `escolaridade` | 0,0340 | Praticamente nada |

Dois nomes chamam atenção imediata: `longevidade` e `ipdm`. Mas esse brilho é uma armadilha — e é uma armadilha conceitual, não estatística.

### Por que `longevidade` e `ipdm` estão fora

Pense comigo. O que é "longevidade" em um índice de desenvolvimento? É uma medida que **resume o quanto as pessoas daquele município vivem**. A nossa variável-alvo, `mortalidade_60_69`, mede o quanto as pessoas *morrem* entre 60 e 69 anos. São duas formas de olhar para o mesmo fenômeno — uma pela vida, outra pela morte.

Se eu colocar `longevidade` como preditor e `mortalidade_60_69` como alvo, o modelo vai "acertar" não porque descobriu algo sobre o mundo, mas porque uma variável é o espelho da outra. É como perguntar "esse time vai ganhar?" e usar como preditor a resposta "esse time ganhou?". Tecnicamente funciona; cientificamente não diz nada.

O `ipdm` é ainda pior: é a **média** de riqueza + longevidade + escolaridade. Ou seja, tem longevidade dentro dele. Mesma armadilha, agora embutida.

Por isso, apesar das correlações aparentemente promissoras, **ambos são excluídos**. Ficam como preditores válidos:

`escolaridade`, `distorcao_em`, `pib_per_capita`, `ano`, `riqueza`.

Repare no desconforto: os preditores que sobraram têm **correlações fracas** com o alvo. A maior é `riqueza`, com 0,39. Isso não é um defeito da análise — é um resultado. Significa que, se existe sinal preditivo real aqui, ele **não é linear e simples**. Vamos precisar de modelos que lidem com isso com honestidade.

---

## Passo 2 — n versus p

Aqui relembramos o aviso da atividade 01:

    n = 54    p = 9    n/p = 6

Abaixo de ~10 observações por preditor, modelos começam a **decorar** em vez de **aprender**. Com 6, entramos na zona em que **parcimônia** e **regularização** deixam de ser opções e passam a ser exigências. Este número vai reaparecer nas próximas atividades como justificativa para várias decisões.

---

## Passo 3 — Balanço da variável binária

Para a parte do projeto que lida com classificação, transformamos o alvo em binário: `mortalidade_alta = 1` se o município-ano está acima da mediana, `0` caso contrário.

O resultado é:

    0: 27 observações (50%)
    1: 27 observações (50%)

Perfeito. **Balanço 50/50 por construção** — a mediana garante isso. Isso é bom para a modelagem: nenhum modelo vai poder "vencer" simplesmente chutando a classe majoritária, porque não há classe majoritária. Também significa que a acurácia de um classificador tem uma régua clara: 50% é o que se obtém jogando uma moeda.

---

## Passo 4 — Valores faltantes

    Todas as colunas: 0 NAs

Nenhum valor ausente. Não vamos precisar imputar, descartar nem modelar buracos. Uma preocupação a menos na bagagem.

---

## Baselines — as réguas contra as quais tudo será medido

Toda análise precisa de uma referência. Se o modelo não bate o baseline, ele não ganhou nada — apenas embaralhou.

**Baseline de regressão:** prever sempre a média do alvo.

    RMSE_baseline = sd(Y) = 3.8504

Traduzindo: se eu simplesmente disser "todo município-ano tem mortalidade ≈ 19,9", meu erro típico seria de 3,85 mortes por mil habitantes. Qualquer modelo de regressão precisa entregar RMSE **abaixo disso** para ter valor.

**Baseline de classificação:** chutar sempre a classe majoritária.

    Acc_baseline ≈ 50%

Porque o alvo está 50/50, chutar sempre a mesma classe acerta metade. Todo classificador precisa fazer melhor que isso.

---

## As três figuras

### Figura 1 — Como se distribui a mortalidade 60–69

![Distribuição do alvo com média, mediana e normal teórica](https://raw.githubusercontent.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/main/estrutura/scriptsR/figuras/02-analise-exploratoria_img1.png)

Este histograma mostra a forma da nossa variável-alvo. Três linhas verticais ajudam a ler:

- **Linha azul (`média`)**: o centro de gravidade da distribuição.
- **Linha verde tracejada (`mediana`)**: o valor que divide os dados em metade abaixo, metade acima.
- **Curva laranja (`normal teórica`)**: como seria se os dados fossem perfeitamente gaussianos.

Repare que a distribuição tem uma **cauda longa para a direita** — há alguns município-anos com mortalidade muito alta (Mongaguá 2022, 33,0). Isso puxa a média para cima da mediana. É uma distribuição **assimétrica**, e isso é uma informação importante: modelos que assumem normalidade dos resíduos vão ter trabalho nas próximas atividades (e, de fato, vão).

### Figura 2 — Mortalidade por município

![Boxplot da mortalidade por município](https://raw.githubusercontent.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/main/estrutura/scriptsR/figuras/02-analise-exploratoria_img2.png)

Cada caixa representa um município, resumindo todos os seus anos. A linha central da caixa é a mediana; a caixa vai do quartil 1 ao 3; os "bigodes" mostram a extensão dos dados.

O que salta aos olhos:

- **Há municípios estruturalmente diferentes entre si.** Santos, por exemplo, tem mortalidade consistentemente mais baixa; Mongaguá, mais alta. Ou seja, o *município* importa como contexto — mesmo que não o usemos como preditor numérico (não é variável quantitativa), essa heterogeneidade está nos dados.
- **A dispersão dentro de cada município também é grande.** Alguns municípios têm caixas largas — ou seja, variação ano a ano considerável.

Isso nos lembra que estamos trabalhando com **poucos municípios e poucos anos**, e que cada observação carrega peso. O modelo não vai poder "média" os efeitos como faria com milhares de dados.

### Figura 3 — Escolaridade versus mortalidade

![Dispersão escolaridade vs mortalidade com reta ajustada](https://raw.githubusercontent.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/main/estrutura/scriptsR/figuras/02-analise-exploratoria_img3.png)

Aqui está o par que a intuição substantiva mais esperaria: **mais educação, menos mortalidade adulta?** A teoria diz que sim. A intuição diz que sim. O gráfico diz... quase nada.

Os pontos estão espalhados sem formar padrão claro. A reta ajustada é quase horizontal — confirmando a correlação de 0,034 que vimos no Passo 1. A linha laranja basicamente só passa pelo centro da nuvem.

**Isso é um resultado, não um fracasso.** Significa que, neste recorte específico (Baixada Santista, 9 municípios, 6 anos), a relação linear simples entre escolaridade e mortalidade 60–69 é praticamente nula. Se vamos encontrar sinal, será:

- Com outras variáveis (riqueza, PIB, distorção);
- Ou com **interações** e **não-linearidades**;
- Ou concluindo honestamente que, com este n, não há sinal detectável — e isso é uma resposta legítima também.

Não devemos forçar um resultado que o dado não mostra. A elegância do trabalho está em resistir a essa tentação.

---

## O que fica desta atividade

1. **Preditores válidos:** `escolaridade`, `distorcao_em`, `pib_per_capita`, `ano`, `riqueza`. Excluídos por circularidade: `longevidade`, `ipdm`.
2. **Correlações são fracas** — o sinal, se existir, não é linear simples.
3. **n/p = 6** — parcimônia ou regularização são obrigatórias.
4. **Baselines fixados:** RMSE = 3,8504 (regressão) e 50% de acurácia (classificação).
5. **Distribuição do alvo é assimétrica à direita** — a normalidade dos resíduos será questão aberta.
6. **Heterogeneidade entre municípios** é real e visível.

A partir daqui, toda atividade vai comparar seus resultados **contra estes baselines**. Se o modelo não bate, é porque não bate — e diremos isso sem rodeios.

Próxima parada: uma primeira tentativa de regressão linear, para sentir na pele o que os baselines desta atividade já estavam avisando.

---

## Fundamentação Matemática e Resolução dos Exercícios (Aula 03)

### 1. Medidas de Posição, Dispersão e Variáveis Aleatórias

Para uma amostra quantitativa $x_1, \dots, x_n$, resumimos centro e espalhamento por:

$$
\bar{x} = \frac{1}{n}\sum_{i=1}^{n} x_i, \qquad s^2 = \frac{1}{n-1}\sum_{i=1}^{n}(x_i - \bar{x})^2, \qquad s = \sqrt{s^2}, \qquad \mathrm{IQR} = Q_3 - Q_1
$$

Para uma variável aleatória discreta com função de probabilidade $p(x) = P(X = x)$ ou contínua com densidade $f(x)$:

$$
\mathbb{E}[X] = \sum_x x p(x) \quad \mathrm{ou} \quad \int_{-\infty}^{\infty} x f(x) dx, \qquad \mathrm{Var}(X) = \mathbb{E}\bigl[(X - \mathbb{E}[X])^2\bigr] = \mathbb{E}[X^2] - (\mathbb{E}[X])^2
$$

> **Frase de entrega da Aula 03 (forma da distribuição de `mortalidade_60_69`):**  
> *"A taxa de mortalidade de 60 a 69 anos na Baixada Santista é **assimétrica à direita** (média $19,91$ maior que a mediana $19,53$, com cauda superior estendendo-se até $33,00$ mortes/mil hab. em Mongaguá/2022), afastando-se da simetria da Normal teórica e lembrando uma distribuição **Gama ou Lognormal** deslocada."*

### 2. Resolução dos Exercícios de Cálculo da Aula 03 (Slide 16/19)

1. **Amostra $\lbrace 4, 8, 8, 10, 20 \rbrace$ ($n = 5$):**
   - **Média:** $\bar{x} = \frac{4 + 8 + 8 + 10 + 20}{5} = \frac{50}{5} = \mathbf{10,0}$.
   - **Mediana:** Elemento central (3ª posição ordenada) $= \mathbf{8,0}$.
   - **Desvio-padrão amostral ($s$):** $s^2 = \frac{(4-10)^2 + (8-10)^2 + (8-10)^2 + (10-10)^2 + (20-10)^2}{5 - 1} = \frac{36 + 4 + 4 + 0 + 100}{4} = \frac{144}{4} = 36 \implies s = \mathbf{6,0}$.
   - *Interpretação:* Como $\bar{x} = 10 > 8$ (mediana), a média é puxada pelo valor extremo $20$, indicando **assimetria positiva (cauda à direita)**.
2. **Variável aleatória discreta com $p(0)=0,5$, $p(1)=0,3$, $p(2)=0,2$:**
   - $\mathbb{E}[X] = 0(0,5) + 1(0,3) + 2(0,2) = 0 + 0,3 + 0,4 = \mathbf{0,70}$.
   - $\mathbb{E}[X^2] = 0^2(0,5) + 1^2(0,3) + 2^2(0,2) = 0,3 + 0,8 = 1,10 \implies \mathrm{Var}(X) = 1,10 - (0,70)^2 = 1,10 - 0,49 = \mathbf{0,61}$.
3. **Poisson($\lambda = 2$) no R:**
   - $P(X = 0)$: `dpois(0, lambda = 2)` ($= e^{-2} \approx 0,1353$).
   - $P(X \ge 3) = 1 - P(X \le 2)$: `1 - ppois(2, lambda = 2)` ou `ppois(2, lambda = 2, lower.tail = FALSE)` ($\approx 0,3233$).

### 3. Resolução dos Exercícios Conceituais da Aula 03 (Slide 17/19)

- **Qual distribuição usar?** (a) Nº de peças defeituosas em um lote fixo de $n=100$: **Binomial$(100, p)$**; (b) Tempo contínuo até o próximo cliente entrar na loja: **Exponencial$(\lambda)$**; (c) Resultado único de cara ou coroa ($0/1$): **Bernoulli$(p)$**.
- **Discreta ou contínua?** Nº de filhos: **discreta** (contagem); tempo de espera: **contínua** (medida); nº de e-mails/dia: **discreta** (contagem, modelo Poisson); temperatura: **contínua** (medida).
- **Lendo um boxplot:** A **caixa** delimita o intervalo interquartil ($Q_1$, percentil $25\%$, até $Q_3$, percentil $75\%$, cobrindo os $50\%$ centrais dos dados); a **linha central** marca a **mediana** ($Q_2$); os **pontos além dos bigodes** ($Q_1 - 1,5\ \mathrm{IQR}$ ou $Q_3 + 1,5\ \mathrm{IQR}$) sinalizam **valores atípicos (*outliers*)**.

---

## Documentos complementares

**Script que gera este consolidado:**
- 🧮 [`02-analise-exploratoria.R`](https://github.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/blob/main/estrutura/scriptsR/02-analise-exploratoria.R) — **a fonte** deste documento.

**Demais documentos relacionados:**
- 📋 [Relatório técnico do script (`02-analise-exploratoria.md`)](https://github.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/blob/main/estrutura/scriptsR/02-analise-exploratoria.md) — output bruto, sem a camada didática.
- 📊 [Banco de dados (CSV)](https://github.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/blob/main/estrutura/bancoDeDados/df_ipdm_baixada_por_municipio.csv).
- 📄 [Dicionário de dados (PDF)](https://github.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/blob/main/estrutura/dicionario/dicionario_ipdm_baixada.pdf).
- 📝 [Dicionário de dados (fonte LaTeX)](https://github.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/blob/main/estrutura/dicionario/dicionario_ipdm_baixada.tex).
- 📎 [Consolidado 01 — Dicionário de variáveis](https://github.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/blob/main/consolidado/01-dicionario-variaveis.md).
