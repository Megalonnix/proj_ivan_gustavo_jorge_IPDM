# Atividade 01 — Conhecendo o terreno: dicionário de variáveis e tipagem

> **Este documento é o resultado do script**
> [`estrutura/scriptsR/01-dicionario-variaveis.R`](https://github.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/blob/main/estrutura/scriptsR/01-dicionario-variaveis.R).
> O script produz os números; este consolidado é a leitura humana deles —
> com o porquê das decisões e o que aprender com cada resultado.

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

Seguindo a régua da **Aula 02 (slides 10 e 11)**, separamos rigorosamente o **tipo estatístico** da variável (o que ela representa matematicamente) do **tipo de armazenamento no R** (`class()` / `typeof()`), garantindo que códigos identificadores como `cod_ibge` jamais sejam tratados como números em médias ou regressões:

| Coluna | O que é | Tipo estatístico | Tipo no R | Domínio / Unidade |
|---|---|---|---|---|
| `cod_ibge` | Identificador oficial do município (IBGE) | Identificador (qualitativa nominal) | `factor` / `character` | 9 códigos de 7 dígitos (rótulo, não número) |
| `municipio` | Nome do município da Baixada Santista | Qualitativa nominal | `factor` (9 níveis) | Bertioga, Cubatão, ..., São Vicente |
| `ano` | Ano da edição bienal do IPDM | Quantitativa discreta / ordinal | `integer` ou `factor` | $\{2014, 2016, 2018, 2020, 2022, 2024\}$ |
| `riqueza` | Indicador sintético de Riqueza | Quantitativa contínua | `numeric` (`double`) | $[0,321;\; 0,575]$ (índice $[0, 1]$) |
| `longevidade` | Indicador sintético de Longevidade | Quantitativa contínua | `numeric` (`double`) | $[0,560;\; 0,756]$ (índice $[0, 1]$, **excluído**) |
| `escolaridade` | Indicador sintético de Escolaridade | Quantitativa contínua | `numeric` (`double`) | $[0,334;\; 0,602]$ (índice $[0, 1]$) |
| `ipdm` | Índice Paulista de Desenv. Municipal | Quantitativa contínua | `numeric` (`double`) | $[0,442;\; 0,604]$ (composto, **excluído**) |
| `mortalidade_60_69` | **NOSSO ALVO ($Y$)** | Quantitativa contínua | `numeric` (`double`) | $[13,94;\; 33,00]$ (óbitos por mil hab.) |
| `distorcao_em` | Atraso idade-série no Ensino Médio | Quantitativa contínua | `numeric` (`double`) | $[8,20;\; 26,80]$ ($\%$) |
| `pib_per_capita` | PIB municipal per capita | Quantitativa contínua | `numeric` (`double`) | $[20.064;\; 270.119]$ (R\$ de 2024) |

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
- `municipio` (qualitativa nominal)

## Um número que vale memorizar: n/p

Temos **n = 54 observações** e, tirando alvo e identificadores, algo em torno de
**p = 9 preditores potenciais**. A razão é:

    n/p = 54/9 = 6

Regra de bolso em estatística: abaixo de ~10 observações por preditor, o modelo começa
a decorar o passado em vez de aprender padrões. Com 6, já estamos na zona em que
**parcimônia** (escolher poucos preditores, com critério) ou **regularização**
(encolher os coeficientes) deixam de ser luxo e passam a ser necessidade.

Isso não é um problema — é um aviso. Vamos carregá-lo com a gente pelas próximas
atividades.

## O que fica desta atividade

1. **Sabemos o que cada coluna é** — inclusive o que *não* colocar no modelo.
2. **O alvo é `mortalidade_60_69`**, uma variável de desfecho real.
3. **n/p = 6** — a partir daqui, toda modelagem precisa ser enxuta.
4. **Não há NAs** — limpamos essa preocupação da mesa.

Próxima parada: diagnóstico exploratório, baselines e um primeiro olhar sobre a
distribuição do alvo.

---

## Fundamentação Teórica e Resolução dos Exercícios (Aulas 01 e 02)

### 1. A Equação Fundamental do Aprendizado Estatístico (Aula 01)

Dados $p$ preditores $X = (X_1, \dots, X_p)$ e uma resposta quantitativa $Y$, assumimos o modelo populacional:

$$Y = f(X) + \varepsilon, \qquad \text{com } \mathbb{E}[\varepsilon] = 0 \text{ e } \varepsilon \perp X.$$

Para uma estimativa $\hat{Y} = \hat{f}(X)$ e um ponto fixo $X = x_0$, o erro quadrático esperado decompõe-se em duas parcelas:

$$\mathbb{E}\bigl[(Y - \hat{Y})^2\bigr] = \mathbb{E}\bigl[(f(X) + \varepsilon - \hat{f}(X))^2\bigr] = \underbrace{\bigl[f(X) - \hat{f}(X)\bigr]^2}_{\text{Erro Redutível}} + \underbrace{\text{Var}(\varepsilon)}_{\text{Erro Irredutível}}.$$

*(Demonstração pedida no slide 20/22 da Aula 01: expandindo o quadrado $((f(X)-\hat{f}(X)) + \varepsilon)^2$, como $\varepsilon$ é independente de $X$ e $\mathbb{E}[\varepsilon] = 0$, o termo cruzado $2[f(X)-\hat{f}(X)]\mathbb{E}[\varepsilon] = 0$ anula-se e $\mathbb{E}[\varepsilon^2] = \text{Var}(\varepsilon)$).*

### 2. Exercícios da Aula 01 (Slides 19 e 20/22)

1. **Cálculo do Erro Esperado:** Em $x_0$, se $f(x_0) - \hat{f}(x_0) = 0,4$ e $\text{Var}(\varepsilon) = 0,25$:
   $$\mathbb{E}\bigl[(Y - \hat{Y})^2\bigr] = (0,4)^2 + 0,25 = 0,16 + 0,25 = \mathbf{0,41},$$
   sendo **$0,25$ a parcela irredutível** (teto que nenhum modelo pode baixar sem novas variáveis).
2. **Classificação de Problemas:**
   - *(a) Prever preço de imóvel:* **Supervisionado · Regressão** ($Y$ quantitativa contínua).
   - *(b) Separar clientes em perfis sem rótulos:* **Não-supervisionado · Agrupamento** (não há $Y$).
   - *(c) Decidir se e-mail é spam:* **Supervisionado · Classificação** ($Y$ qualitativa binária).
   - *(d) Estimar nota final de aluno (0 a 10):* **Supervisionado · Regressão** ($Y$ quantitativa).

### 3. Exercícios da Aula 02 (Slides 14 e 15/17)

| Item | Variável | Tipo Estatístico | Tipo no R |
|---|---|---|---|
| **a)** | Temperatura ($^\circ\text{C}$) | Quantitativa contínua | `numeric` (`double`) |
| **b)** | Estado civil | Qualitativa nominal | `factor` |
| **c)** | Nº de acessos a um site | Quantitativa discreta | `integer` |
| **d)** | Faixa de renda (baixa/média/alta) | Qualitativa ordinal | `ordered` (`factor(..., ordered = TRUE)`) |
| **e)** | CEP | Identificador / Qualitativa nominal | `character` ou `factor` |
| **f)** | Nota de 0 a 10 | Quantitativa contínua (ou discreta) | `numeric` (`double`) |

- **Por que código (`cd_uf`, `cod_ibge`, CEP) não é número?** Porque os dígitos são apenas rótulos arbitrários de identificação: somar dois códigos IBGE ou tirar a média de CEPs não tem significado algébrico nem métrico; se entrarem como `numeric` num `lm()`, o R ajustará uma inclinação linear espúria sobre a numeração cadastral.
- **Por que usar `ordered` para faixa de renda?** Um `character` comum ordena categorias em ordem alfabética (`"alta"`, `"baixa"`, `"media"`), destruindo a hierarquia natural ($\text{baixa} < \text{média} < \text{alta}$) em tabelas, gráficos de barras e contrastes ordinais.

---

## Documentos complementares

**Script que gera este consolidado:**
- 🧮 [`01-dicionario-variaveis.R`](https://github.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/blob/main/estrutura/scriptsR/01-dicionario-variaveis.R) — **a fonte** deste documento.

**Demais documentos relacionados:**
- 📄 [Dicionário de dados (PDF)](https://github.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/blob/main/estrutura/dicionario/dicionario_ipdm_baixada.pdf) — versão formatada, para leitura.
- 📝 [Dicionário de dados (fonte LaTeX)](https://github.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/blob/main/estrutura/dicionario/dicionario_ipdm_baixada.tex) — para editar/recompilar.
- 📊 [Banco de dados (CSV)](https://github.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/blob/main/estrutura/bancoDeDados/df_ipdm_baixada_por_municipio.csv) — os dados brutos.
- 📋 [Relatório técnico do script (`01-dicionario-variaveis.md`)](https://github.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/blob/main/estrutura/scriptsR/01-dicionario-variaveis.md) — output bruto do script, sem a camada didática.
