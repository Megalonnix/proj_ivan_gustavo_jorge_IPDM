# Conclusões da Pesquisa — IPDM da Baixada Santista

- **Disciplina:** Teoria do Aprendizado Estatístico
- **Integrantes:** Ivan, Gustavo, Jorge
- **Escopo:** Testar modelos de aprendizado supervisionado sobre o IPDM
(Fundação Seade) para os 9 municípios da Baixada Santista, 2014–2024.

---

## Nota de propósito deste documento

Este relatório **não é um relato de resultados positivos**. É um documento de
**reflexão metodológica**.

A pesquisa foi conduzida com o objetivo explícito de **testar modelos** de
aprendizado supervisionado sobre um banco real — não de produzir um modelo
preditivo operacional. Essa distinção orienta toda a leitura que segue.

Consequentemente, o valor deste documento não está na magnitude dos números
obtidos (que são modestos, e o leitor deve saber disso desde o início), e sim
naquilo que a experiência de **aplicar o protocolo completo a um banco
pequeno e ruidoso** revelou sobre:

- o comportamento real dos métodos quando o sinal é fraco;
- as armadilhas que só aparecem em amostras pequenas;
- a diferença entre "modelo que pontua bem numa métrica" e "modelo útil";
- o papel de um caso atípico como fenômeno substantivo, não como ruído.

O leitor que buscar aqui um "resultado bonito" não o encontrará. O leitor que
buscar **o que se aprende quando o resultado não é bonito** — esse é o
público-alvo deste relatório.

---

## 1. Objetivo e natureza do trabalho

O objetivo declarado **não é produzir um modelo preditivo operacional**, e sim
**exercitar o protocolo de modelagem supervisionada** — ajuste, diagnóstico,
avaliação out-of-sample, seleção — sobre um banco real, pequeno e ruidoso,
como é típico em dados públicos municipais brasileiros.

Essa distinção é importante para a leitura dos resultados: **o mérito do
trabalho está no rigor do método**, não na magnitude dos números obtidos.

## 2. O que foi executado

Seis módulos, em complexidade crescente, cobrindo as Aulas 2 a 6 do curso:

| Módulo | Conteúdo |
|--------|----------|
| 0 | Análise exploratória, tipagem de variáveis, dicionário |
| 1 | Regressão linear (simples + múltipla) na amostra completa |
| 2 | Regressão logística com três limiares de decisão |
| 3 | Regressão linear com split treino/teste (70/30) |
| 4 | Regressão logística com split, matriz de confusão e ROC |
| 5 | Protocolo treino/validação/teste, viés-variância, seleção |

Em todos os módulos foram produzidos: código reprodutível, figuras
diagnósticas, micro-relatórios no próprio `.R` e consolidados em Markdown.

## 3. Achado empírico central — Cubatão

O resultado substantivo mais consistente do trabalho **não é um coeficiente**,
é um caso atípico:

> **Cubatão tem PIB per capita de R$ 170 mil a R$ 270 mil — de 3 a 10 vezes
> o dos demais municípios — mas sua mortalidade 60–69 está na média dos
> vizinhos mais pobres (~18–21 por mil hab.).**

Esse município **contraria a hipótese renda–saúde** e reaparece como
perturbador em todos os módulos:

| Efeito | Com Cubatão | Sem Cubatão |
|--------|-------------|-------------|
| R² linear (amostra completa) | 0,062 | **0,311** |
| β₁ logístico (amostra completa) | −5,25 × 10⁻⁶ | −9,22 × 10⁻⁵ |
| AUC logística (amostra completa) | 0,690 | **0,737** |
| R² linear (teste, script 3) | 0,019 | **−0,022** |

**Interpretação:** Cubatão mascara a relação na amostra completa, mas
removê-lo não é solução — quando ele cai no teste (scripts 3 e 4), o modelo
treinado sem conhecê-lo faz previsões piores que a média. O ponto não é
ruído a ser deletado: é **fenômeno substantivo** que merece investigação
própria (composição populacional, exposição ambiental histórica, acesso a
serviços).

## 4. Peculiaridades metodológicas reveladas

### 4.1 O caso da AUC alta enganosa

No script 4, o modelo logístico produziu **AUC = 0,868** com coeficientes
estatisticamente nulos (p = 0,986) e probabilidades previstas todas no
intervalo **[0,508; 0,514]**. O classificador nunca escolhe uma classe
distinta — apenas ranqueia internamente de forma residualmente favorável.

**Lição:** AUC mede ranking, não utilidade. Uma métrica isolada pode
"aprovar" um modelo inútil. Só a inspeção conjunta (faixa de probabilidades,
matrizes de confusão em vários limiares, curva de calibração) revela o
problema.

### 4.2 A curva que não é U

No script 5, o erro de teste em função do grau do polinômio **não** forma o
U clássico dos slides:

- Graus 1–3: erro de teste desce (viés caindo, como esperado).
- Graus 5+: **colapso numérico** do `poly()` — MSE de treino explode para
  10³³, ou seja, o modelo nem consegue ajustar o treino.

**Lição:** em variáveis com escala extrema (PIB de 20 mil a 270 mil), a
flexibilidade não é uma escolha estatística — é limitada por condicionamento
numérico. A correção natural (padronizar antes de gerar o polinômio) não foi
aplicada no script, mas é a direção de aprofundamento.

### 4.3 A escolha de modelo dominada pelo split

No script 5, os mesmos dois candidatos (M1 rígido e M2 flexível) foram
avaliados em dois splits diferentes:

| Split | Modelo escolhido | RMSE teste |
|-------|------------------|------------|
| 70/30 | M1 (rígido) | 4,82 |
| 60/20/20 | M2 (flexível) | 2,73 |

A escolha **mudou com o split**, e o RMSE final caiu para quase metade —
não porque o modelo ficou melhor, mas porque o teste da Parte B tem
observações mais fáceis.

**Lição:** em amostra pequena (n=54), decisões de seleção são dominadas pela
partição aleatória, não pelo mérito dos candidatos. Reportar uma única
métrica é enganoso; reportar a sensibilidade ao split é o que torna a
análise honesta.

## 5. Limitações estruturais (declaradas)

1. **Amostra pequena.** 54 observações, apenas 9 unidades verdadeiramente
   independentes (estrutura de painel). Toda métrica tem variância alta.

2. **Split por linha, não por unidade.** O mesmo município aparece em treino
   e teste em anos diferentes — vazamento leve de "identidade". O split
   correto em painéis é por município.

3. **Vazamento mild retroativo.** A mediana usada para definir o alvo
   binário nos scripts 2 e 4 é da amostra completa, não do treino. Optamos
   por manter a comparabilidade entre módulos — trade-off explícito, não
   erro escondido.

4. **Preditor único fraco.** PIB per capita isoladamente explica pouco da
   mortalidade. Adicionar preditores correlacionados não resolve; o
   problema é falta de informação, não rigidez do modelo.

## 6. Conclusão substantiva

Aplicamos o protocolo completo de modelagem supervisionada ao IPDM da
Baixada Santista. O achado central é o seguinte:

> **Existe uma associação negativa real entre PIB per capita e mortalidade
> 60–69 na região, mas ela é fraca, sensível ao split, e mascarada por
> Cubatão — um município com PIB industrial altíssimo e mortalidade na
> média dos vizinhos mais pobres.**

Nenhum dos modelos testados tem poder preditivo suficiente para uso
operacional. As razões são estruturais e estão detalhadas abaixo.

### 6.1 Possíveis causas da não-generalização

Os números dos seis módulos convergem para um diagnóstico em **quatro
camadas**, em ordem decrescente de impacto:

**Causa 1 — Sinal intrínseco fraco do par escolhido (dominante).**

O PIB per capita, isoladamente, tem correlação baixa com mortalidade 60–69
nesta amostra. Os números:

| Métrica | Valor | Leitura |
|---------|-------|---------|
| R² full (script 1) | 0,062 | PIB explica 6% da variabilidade |
| Correlação previsto × real (teste, script 3) | 0,348 | Associação fraca |
| Amplitude das previsões / amplitude do real | 2,56 / 18,35 | Modelo ignora 86% da variação |
| Pseudo-R² McFadden (script 2) | 0,016 | Quase nulo |

**Implicação:** nenhum ajuste técnico (regularização, split diferente,
padronização) resolve falta de sinal. O problema está no **preditor** — ou
na variável resposta, ou no recorte. Refazer o split mil vezes muda o
número, não o diagnóstico.

**Causa 2 — Amostra pequena e correlacionada (estrutura de painel).**

54 linhas, mas **9 unidades verdadeiramente independentes** (uma por
município). As 6 observações do mesmo município são autocorrelacionadas.
Consequências diretas:

- Variância das métricas é enorme. Um split com seed 42 deu RMSE 4,82;
  um split 60/20/20 com o mesmo seed deu 2,73. Não é o modelo que mudou —
  é a partição.
- Testes t e F perdem garantias assintóticas. Os p-valores dos scripts 1
  e 2 são **indicativos**, não provas.
- IC 95% de β₁ no script 1 toca o zero; no script 4 o IC é tão largo que
  nem o sinal é distinguível.

**Causa 3 — Outlier de alta alavancagem (Cubatão).**

Cubatão distorce em **duas direções opostas**, dependendo de onde cai no
split:

| Cenário | Efeito observado |
|---------|------------------|
| Cubatão no treino (script 3) | R² treino cai de 0,31 → 0,035; β₁ fica 8× mais fraco |
| Cubatão no teste (script 4) | R² teste fica **negativo** (−0,022); AUC cai de 0,868 para 0,840 |
| Cubatão removido (script 1) | R² sobe para 0,311 — mas isso **esconde** um caso real |

**Implicação:** nenhuma decisão sobre Cubatão (manter, remover, ponderar)
resolve a não-generalização. Manter achata o sinal; remover esconde um
fenômeno substantivo. O ponto é **informação**, não ruído.

**Causa 4 — Instabilidade numérica dos polinômios de grau alto.**

O script 5 mostrou que graus ≥ 5 geram MSE de treino em **10³³** — falha
numérica, não sobreajuste. Com PIB variando 20.000–270.000, `poly()`
produz colunas degeneradas. **Isso não é causa da não-generalização em si**
(a não-generalização já existe no grau 1), mas inviabiliza a exploração da
faixa de flexibilidade que a Aula 6 pede.

### 6.2 Alternativas com o mesmo banco

Abaixo, cinco direções que **podem** melhorar a generalização sem trocar de
fonte de dados. Ordenadas por custo crescente de implementação e por
expectativa realista de ganho.

**Alternativa A — Split por município (`leave-one-municipality-out`).**

Em vez de separar linhas aleatoriamente, separar **municípios inteiros**.

- Treino: 8 municípios × 6 anos = 48 obs.
- Teste: 1 município × 6 anos = 6 obs.
- Repetir 9 vezes (um hold-out por município).

**Vantagem:** remove o vazamento de identidade — o modelo nunca vê o mesmo
município em treino e teste.

**Expectativa realista:** o R² de teste **cai** em relação ao split por
linha, porque o teste fica mais difícil. Mas o número reportado é **honesto**.
Se for usado como métrica de seleção, vai escolher modelos diferentes dos
atuais.

**Alternativa B — Validação cruzada agrupada por município.**

Extensão natural da anterior: `caret::groupKFold` ou implementação manual
com 9 folds (um município por fold).

**Vantagem:** usa toda a amostra (não desperdiça 1/9 por rodada), reduz a
variância da estimativa de erro.

**Expectativa realista:** dá uma **distribuição** de RMSE em vez de um
número único. Isso responde diretamente ao achado do script 5 ("o split
domina a decisão") — mostra quanta variabilidade existe.

**Alternativa C — Efeitos fixos por município e por ano.**

Modelar a heterogeneidade estrutural em vez de ignorá-la:

```r
lm(mortalidade_60_69 ~ pib_per_capita + factor(Municipio) + factor(Ano))
```

**Vantagem:** cada município e cada ano ganha um intercepto próprio. A
variação **entre** unidades é absorvida; sobra a variação **dentro** das
unidades ao longo do tempo. Isso é exatamente o que o painel oferece.

**Custo:** consome graus de liberdade (9 + 6 − 2 ≈ 13 parâmetros extras).
Com n=54, é muito. Alternativa mais parcimoniosa: **efeitos fixos só de
ano**, dado o achado do script 3 (erros concentrados em 2022).

**Expectativa realista:** R² intramostral sobe. Generalização **out-of-sample
pode não melhorar** — e isso é informação: significa que a variação que
importa é entre municípios, não dentro.

**Alternativa D — Padronizar `pib_per_capita` antes de gerar polinômios.**

Correção direta do colapso do script 5:

```r
df$pib_pad <- scale(df$pib_per_capita)
lm(mortalidade_60_69 ~ poly(pib_pad, 5), data = tr)
```

**Vantagem:** estabiliza numericamente a matriz de desenho. Permite explorar
graus 4–10 sem colapso. O U da Aula 6 finalmente aparece (ou não — e isso
é informação também).

**Expectativa realista:** **não melhora a generalização** (a curva do U
estava descendo monotonamente em graus 1–3, ou seja, a flexibilidade estava
ajudando, não prejudicando). Mas permite **verificar** se o diagnóstico
anterior era numérico ou estatístico.

**Alternativa E — Ampliar o conjunto de preditores.**

Este é o ponto onde o banco atual tem mais a oferecer e menos foi explorado.
Preditores disponíveis **não usados** até agora:

| Variável no banco | Dimensão | Uso atual |
|-------------------|----------|-----------|
| Taxas de mortalidade infantil | Longevidade | Não usado |
| Taxas de mortalidade perinatal | Longevidade | Não usado |
| Taxas de mortalidade 15–39 | Longevidade | Não usado |
| Taxa de atendimento escolar 0–3 | Escolaridade | Não usado |
| Proporção 5º ano com proficiência | Escolaridade | Não usado |
| Proporção 9º ano com proficiência | Escolaridade | Não usado |
| Consumo energia residencial | Riqueza | Não usado |
| Consumo energia comercial | Riqueza | Não usado |
| Rendimento do trabalho formal | Riqueza | Não usado |

**Atenção:** alguns desses preditores podem **reintroduzir circularidade**
— por exemplo, usar mortalidade infantil para prever mortalidade 60–69 é
defensável em desenho, mas as duas medidas são componentes da dimensão
*Longevidade* do IPDM. É um trade-off consciente: mais preditores, mais
risco de vazamento metodológico.

**Expectativa realista:** com 5–8 preditores bem escolhidos, R² full pode
subir de 0,06 para **0,3–0,5**. Mas o teste cai bastante (mais parâmetros
com n=54). O critério de sucesso deixa de ser "R² alto" e passa a ser
"ganho de teste que não seja ruído".

**Alternativa F — Mudar o alvo.**

O objetivo do trabalho é prever **mortalidade 60–69**. Nada obriga a manter
esse alvo. A literatura de saúde pública mostra que **mortalidade infantil**
tem relação muito mais forte com renda e saneamento do que mortalidade
em idosos. Usar **mortalidade infantil** como Y:

- **Vantagem esperada:** R² sobe significativamente (literatura aponta
  0,5–0,7 em cross-section de municípios).
- **Custo:** muda o objeto do estudo. Não é mais "mortalidade na terceira
  idade" — é "mortalidade na primeira infância". A narrativa muda.

Se o objetivo é **testar modelos**, mudar o alvo é permitido. Se o objetivo
é **entender mortalidade 60–69**, não é.

### 6.3 O que **não** tentar

Três armadilhas que parecem soluções e não são:

1. **Remover Cubatão do banco.** Já testado em todos os scripts. Sem ele
   o R² sobe, mas o teste cai (script 3: R² teste negativo) ou fica
   equivalente (script 4: AUC cai). O ponto **não é ruído**.

2. **Aumentar a flexibilidade do modelo.** O script 5 mostrou: a
   flexibilidade está ajudando (graus 1–3), não prejudicando. Adicionar
   graus além do ponto de colapso numérico destrói o modelo, não melhora.

3. **Refazer o split com seed diferente até dar um bom resultado.**
   Isso é a definição operacional de vazamento. Se o split 42 dá RMSE
   4,82 e o 60/20/20 dá 2,73, a leitura é "as métricas são instáveis",
   não "encontrei o split certo".

## 7. Valor do trabalho

Este é um resultado **negativo** no sentido estatístico — os modelos não
generalizam bem. Mas é um resultado **honesto, reprodutível e completo**,
com três contribuições concretas:

1. **Demonstra domínio do protocolo.** Split, validação, teste, diagnóstico
   de resíduos, análise de alavancagem, matrizes de confusão em múltiplos
   limiares — tudo aplicado no lugar certo, na ordem certa.

2. **Expõe armadilhas metodológicas reais.** A AUC alta com coeficientes
   nulos, o colapso numérico dos polinômios, a escolha de modelo dominada
   pelo split — três armadilhas que só aparecem quando se trabalha com
   dados pequenos e ruidosos de verdade.

3. **Identifica um fenômeno substantivo da região.** Cubatão não é um
   "outlier a remover". É um caso que a literatura de economia da saúde
   reconhece como interessante — e que merece investigação própria, não
   tratamento estatístico.

O trabalho cumpre o objetivo da disciplina: **testar modelos em dados
reais**, com rigor, e documentar honestamente o que foi encontrado — inclusive
quando o encontrado é "o modelo não funciona".