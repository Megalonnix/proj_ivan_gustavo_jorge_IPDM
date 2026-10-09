# Atividade 01 — Conhecendo o terreno: dicionário de variáveis e tipagem

> **Alvo do projeto:** `mortalidade_60_69` (mortes por mil habitantes na faixa 60–69).
> Leia isso como uma promessa: toda decisão a seguir gira em torno desse número.

## Por que começar por aqui?

Antes de qualquer modelo, precisamos saber com o que estamos trabalhando. É o equivalente
a um pedreiro olhar a planta antes de assentar o primeiro tijolo. Se você não sabe o que
cada coluna significa, qual é o tipo dela e o que ela representa na vida real, qualquer
coeficiente que aparecer depois vira chute com casas decimais.

O banco é o `df_ipdm_baixada_por_municipio.csv`. Ele descreve **9 municípios da Baixada
Santista** ao longo de **6 anos** (2014, 2016, 2018, 2020, 2022 e 2024), totalizando
**54 observações**. Cada linha é um par (município, ano) — ou seja, um retrato daquele
lugar naquele momento.

## O que temos em mãos

| Coluna | O que é | Tipo estatístico |
|---|---|---|
| `cod_ibge` | Identificador do município | Identificador (não entra em modelo) |
| `municipio` | Nome do município | Qualitativa nominal |
| `ano` | Ano da observação | Quantitativa discreta |
| `riqueza` | Índice 0–1 | Quantitativa contínua |
| `longevidade` | Índice 0–1 | Quantitativa contínua |
| `escolaridade` | Índice 0–1 | Quantitativa contínua |
| `ipdm` | Índice 0–1 (composto) | Quantitativa contínua |
| `mortalidade_60_69` | **NOSSO ALVO** | Quantitativa contínua |
| `distorcao_em` | % distorção idade-série no EM | Quantitativa contínua |
| `pib_per_capita` | R$ de 2024 | Quantitativa contínua |

**Não há valores faltantes.** Zero NAs em todas as colunas. Isso é sorte — significa que
não vamos precisar decidir entre imputar, descartar ou modelar os buracos. Uma preocupação
a menos.

## A decisão mais importante desta atividade: por que o IPDM *não* é o alvo

Essa merece uma conversa calmamente explicada, porque é o tipo de coisa que, se passar
batido, contamina tudo o que vem depois.

O IPDM (Índice Paulista de Desenvolvimento Municipal) **é construído como uma média de
três componentes**: riqueza, longevidade e escolaridade. Ele não é uma medida
independente — ele é um *resumo* dessas três coisas.

Se usássemos o IPDM como alvo e, ao mesmo tempo, colocássemos `escolaridade` como
preditor, estaríamos cometendo uma **circularidade**: uma das variáveis do lado direito
da equação é *parte* da variável do lado esquerdo. O modelo "acertaria" não porque
aprendeu algo sobre o mundo, mas porque estava olhando para uma pergunta viciada. É
como prever o resultado de um campeonato usando como preditor a pontuação de um dos
times — o resultado já está embutido.

Por isso trocamos o alvo. Agora é **`mortalidade_60_69`**: uma medida externa, de
desfecho real, que *não* foi usada para construir o IPDM. Faz sentido substantivo
perguntar o que explica a mortalidade adulta nessa faixa — e é isso que vamos fazer.

## Preditores que sobraram (e os que foram descartados)

**Fora, por circularidade conceitual:**
- `longevidade` — na prática é o *inverso* da mortalidade; usá-la como preditor seria
  prever a morte com a própria vida.
- `ipdm` — contém longevidade dentro dele.

**Dentro, como preditores válidos:**
- `escolaridade`
- `distorcao_em`
- `pib_per_capita`
- `ano`
- `riqueza`

## Um número que vale memorizar: n/p

Temos **n = 54 observações** e, tirando alvo e identificadores, algo em torno de
**p = 9 preditores potenciais**. A razão é:

    n/p = 54/9 = 6

Regra de bolso em estatística: abaixo de ~10 observações por preditor, o modelo começa
a decorar o passado em vez de aprender padrões. Com 6, já estamos na zona em que
**parcimônia** (escolher poucos preditores, com critério) ou **regularização**
(encolher os coeficientes) deixam de ser luxo e passam a ser necessidade.

Isso não é um problema — é um aviso. Vamos carregá-lo com a gente pelas próximas sete
atividades.

## O que fica desta atividade

1. **Sabemos o que cada coluna é** — inclusive o que *não* colocar no modelo.
2. **O alvo é `mortalidade_60_69`**, uma variável de desfecho real.
3. **n/p = 6** — a partir daqui, toda modelagem precisa ser enxuta.
4. **Não há NAs** — limpamos essa preocupação da mesa.

Próxima parada: diagnóstico exploratório, baselines e um primeiro olhar sobre a
distribuição do alvo.