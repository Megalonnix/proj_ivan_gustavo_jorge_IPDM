# Análise Exploratória — IPDM da Baixada Santista

## 1. Objetivo

Antes de ajustar qualquer modelo, é preciso **entender os dados**: o que cada
variável representa, de que tipo ela é, como se distribui, e que relações
preliminares aparecem entre preditor e resposta. Este script cumpre duas
tarefas das aulas iniciais:

- **Aula 2** — construir o dicionário de variáveis e tipar corretamente cada
  coluna no R.
- **Aula 3** — realizar a análise exploratória (EDA): posição, dispersão,
  forma da distribuição, relações bivariadas e contagem de faltantes.

A saída deste script é o banco consolidado
(`df_ipdm_baixada_por_municipio.csv`), usado por todos os módulos seguintes.

## 2. Construção do banco

### 2.1 Filtragem

A base original do IPDM cobre os 645 municípios paulistas. Filtramos os
**nove municípios da Região Metropolitana da Baixada Santista** (Bertioga,
Cubatão, Guarujá, Itanhaém, Mongaguá, Peruíbe, Praia Grande, Santos, São
Vicente), resultando em **54 observações** (9 municípios × 6 anos: 2014,
2016, 2018, 2020, 2022, 2024).

### 2.2 Do formato longo ao formato wide

A base original vem em formato **longo** — cada linha é um
município-ano-indicador. Foi necessário pivotar para **wide**, com uma linha
por município-ano e uma coluna por indicador. O IPDM final é calculado como
**média aritmética simples das três dimensões** (Riqueza, Longevidade,
Escolaridade), conforme a metodologia da Fundação Seade.

### 2.3 Tipagem das variáveis (Aula 2)

| Variável | Tipo estatístico | Tipo no R | Justificativa |
|----------|------------------|-----------|---------------|
| `cod_ibge` | Identificador | `factor` | Código é rótulo, não quantidade. Guardá-lo como número permitiria operações sem sentido (média de código IBGE) e o induziria a entrar como preditor contínuo num `lm()` por engano. |
| `Municipio` | Qualitativa nominal | `factor` | Habilita boxplot por grupo, contrastes e futuros modelos com efeitos fixos. |
| `Ano` | Quantitativa discreta | `integer` | Não é usado como preditor ordinal; mantido numérico para preservar uso aritmético. |
| Dimensões do IPDM (Riqueza, Longevidade, Escolaridade, IPDM) | Quantitativa contínua | `double` | Índices em [0, 1]. |
| Mortalidade 60–69 | Quantitativa contínua | `double` | Taxa por mil habitantes. |
| PIB per capita | Quantitativa contínua | `double` | R$ de 2024. |

O dicionário completo está em `estrutura/dicionario/dicionario_ipdm_baixada.pdf`.

## 3. EDA — o que foi feito

### 3.1 Inspeção estrutural

- `str()`, `dim()`, `head()` — confirmam 54 linhas e as colunas esperadas.
- `colSums(is.na(...))` — o banco resultante **não apresenta valores
  faltantes** após o pivot; nenhuma imputação foi necessária.
- `sapply(..., class)` — verifica a tipagem final.

### 3.2 Resumo de uma quantitativa (PIB per capita)

- `summary()` — posição (mínimo, Q1, mediana, Q3, máximo).
- `sd()` — dispersão amostral.
- `skewness()` e `kurtosis()` — forma da distribuição.
- **Histograma** com densidade Normal sobreposta (média e desvio amostrais).
- **Boxplot** — mediana, quartis e outliers pela regra 1,5 × IQR.

### 3.3 Relações bivariadas

- **Dispersão** PIB per capita × mortalidade 60–69 — primeiro olhar sobre a
  relação que será modelada no script 1.
- **Boxplot por grupo** — mortalidade 60–69 por município, para verificar
  heterogeneidade sistemática entre unidades.

## 4. Resultados esperados

- **Assimetria forte à direita** no PIB per capita: média bem acima da
  mediana, `skewness > 0` e `kurtosis > 3`. O pólo industrial de Cubatão
  (PIB per capita de ~R$ 170 mil a ~R$ 270 mil, contra ~R$ 20 mil a ~R$ 90
  mil dos demais) domina essa cauda.
- **Histograma com fraca aderência à Normal**: a curva Normal ajustada
  subestima a frequência dos valores altos. Isso é esperado — o PIB per
  capita em regiões com polos industriais não segue Normal. (Nota: a OLS
  **não exige normalidade do preditor**, apenas dos resíduos. A comparação
  aqui é descritiva, não diagnóstica.)
- **Boxplot por município** com medianas distintas de mortalidade,
  evidência de heterogeneidade entre unidades que reforça a ressalva sobre
  a estrutura de painel nos módulos seguintes.

## 5. Discussão — outliers: por que não os removemos

Os boxplots do PIB per capita acusam pontos acima do bigode superior
(observações além de Q3 + 1,5 × IQR). Esses pontos correspondem, com alta
probabilidade, a **Cubatão**. Não são erro de digitação — são fato econômico
real da região.

A decisão metodológica foi **manter os outliers** no banco e em todos os
modelos subsequentes. Três razões:

1. **O boxplot existe para revelar outliers, não para escondê-los.** Usar
   `outline = FALSE` maquiaria a EDA — contra o espírito do que a Aula 3
   pede (slide 9: "outliers: valores muito fora — erro de digitação ou caso
   real? O boxplot os aponta").

2. **Amostra pequena.** Com 54 observações, cada linha pesa ~2% do total.
   Excluir reduz poder estatístico e encolhe o intervalo do preditor,
   tornando o coeficiente do script 1 ainda mais instável.

3. **Ponto de alta alavancagem.** Cubatão tem valor extremo no preditor.
   Removê-lo altera substancialmente a inclinação estimada — o que, por si
   só, é informação relevante e deve ser **reportada**, não silenciada.

**Tratamento adotado:** o script 1 apresenta a OLS completa como modelo
principal **e** uma versão auxiliar sem Cubatão, lado a lado, para reportar
a sensibilidade do coeficiente. A discussão final menciona o ponto como
fonte de incerteza — não como valor a excluir.

**Direções de aprofundamento** (registradas, fora do escopo atual): erros-padrão
robustos (HC3) e regressão quantílica — alternativas mais elegantes do que
exclusão manual quando há pontos influentes.

## 6. Amarração com os módulos seguintes

- O CSV salvo mantém os **nomes longos originais** das colunas para que os
  scripts 1–4 funcionem sem alteração (cada um renomeia localmente via
  `grepl`).
- A decisão de manter outliers informa diretamente o script 1: modelo
  principal com amostra completa + análise de sensibilidade sem Cubatão.
- A tipagem de `Municipio` como `factor` habilita, em versões futuras,
  modelos com efeitos fixos (`lm(y ~ x + Municipio)`), que endereçariam a
  violação de i.i.d. discutida no script 1.