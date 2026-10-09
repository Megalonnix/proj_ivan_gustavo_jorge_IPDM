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

## Documentos complementares

**Script que gera este consolidado:**
- 🧮 [`02-analise-exploratoria.R`](https://github.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/blob/main/estrutura/scriptsR/02-analise-exploratoria.R) — **a fonte** deste documento.

**Demais documentos relacionados:**
- 📋 [Relatório técnico do script (`02-analise-exploratoria.md`)](https://github.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/blob/main/estrutura/scriptsR/02-analise-exploratoria.md) — output bruto, sem a camada didática.
- 📊 [Banco de dados (CSV)](https://github.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/blob/main/estrutura/bancoDeDados/df_ipdm_baixada_por_municipio.csv).
- 📄 [Dicionário de dados (PDF)](https://github.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/blob/main/estrutura/dicionario/dicionario_ipdm_baixada.pdf).
- 📝 [Dicionário de dados (fonte LaTeX)](https://github.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/blob/main/estrutura/dicionario/dicionario_ipdm_baixada.tex).
- 📎 [Consolidado 01 — Dicionário de variáveis](https://github.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/blob/main/consolidado/01-dicionario-variaveis.md).