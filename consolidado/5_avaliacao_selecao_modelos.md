# Avaliação e Seleção de Modelos

## 1. Objetivo

As Aulas 4 e 5 ensinaram a **ajustar** modelos. Esta aula ensina a
**avaliá-los e escolhê-los**. A pergunta muda de "esse modelo se ajusta?" para
"esse modelo generaliza — e, entre vários candidatos, qual escolher?".

O script cobre quatro tarefas explícitas da Aula 6:

1. **Tarefa do slide 27** — split 70/30, dois candidatos, RMSE no teste.
2. **Protocolo de três conjuntos** — treino ajusta, validação escolhe,
   teste reporta (uma única vez).
3. **Viés–variância** — a curva do U do erro de teste em função da
   flexibilidade.
4. **Discussão de vazamento** e autocrítica retroativa dos scripts 1–4.

## 2. Fundamentos — o que muda em relação aos scripts 3 e 4

Nos scripts 3 e 4 fizemos split 70/30 (dois conjuntos). Isso basta quando o
modelo está **fixo**. Quando precisamos **escolher** entre candidatos, o
teste não pode participar da escolha — senão vaza informação e o desempenho
reportado fica "bom demais".

| Conjunto | Uso | Quantas vezes |
|----------|-----|---------------|
| Treino | ajusta (`lm`/`glm`) | muitas |
| Validação | compara e escolhe | muitas |
| Teste | reporta o escolhido | **uma vez** |

**Analogia da prova** (slide 29): treino = refazer a lista com gabarito;
validação = simulado; teste = prova final. Só a última é honesta.

**Métrica na língua do problema:** MSE para comparar, RMSE para reportar.
Aqui Y = mortalidade 60–69 (por mil hab.), então RMSE é diretamente
interpretável: *"o modelo erra tipicamente em X por mil habitantes"*.

## 3. Parte A — Tarefa explícita do slide 27

### 3.1 Split

- Split 70/30 antes de qualquer ajuste (`set.seed(42)`).
- **37 treino / 17 teste** (proporções 0,685 / 0,315).

### 3.2 Dois candidatos ajustados **só no treino**

| Modelo | Especificação |
|--------|---------------|
| **M1** (rígido) | `mortalidade ~ pib_per_capita` |
| **M2** (flexível) | `mortalidade ~ pib_per_capita + distorcao_em` |

| Modelo | R² treino | Coeficientes |
|--------|-----------|--------------|
| M1 | 0,0347 | β₀ = 20,16; β_pib = −1,03 × 10⁻⁵ |
| M2 | 0,1362 | β₀ = 15,77; β_pib = −1,50 × 10⁻⁵; β_dist = +0,281 |

### 3.3 RMSE no teste

| Modelo | RMSE teste |
|--------|------------|
| **M1 (rígido)** | **4,8186** |
| M2 (flexível) | 4,9233 |

**Δ = −0,105 → M1 escolhido.**

### 3.4 Tradução do RMSE

> O modelo escolhido (**M1**) erra a mortalidade 60–69, em média, em
> aproximadamente **4,82 por mil habitantes** — contra uma faixa observada
> de ~14 a ~33 por mil. Erro proporcionalmente grande.

**Achado importante:** adicionar `distorcao_em` **aumenta o R² de treino**
(0,035 → 0,136), mas **piora o RMSE no teste** (4,82 → 4,92). Mais
flexibilidade comprou ajuste in-sample **sem** generalizar. É a primeira
evidência de que o problema é falta de sinal, não rigidez.

## 4. Parte B — Protocolo de três conjuntos (60/20/20)

Split: **32 treino / 10 validação / 12 teste**.

### 4.1 Comparação na validação

| Modelo | RMSE validação |
|--------|----------------|
| M1 (rígido) | 6,1268 |
| **M2 (flexível)** | **6,0574** |

**Escolhido na validação: M2.** Vitória apertadíssima — diferença de 0,07,
muito menor que a variabilidade esperada com 10 observações.

### 4.2 Reporte final no teste (uma vez)

| Modelo escolhido | RMSE teste |
|------------------|------------|
| M2 (flexível) | **2,7269** |

### 4.3 Contraste com a Parte A — instabilidade amostral

| Cenário | Split | Modelo escolhido | RMSE teste |
|---------|-------|------------------|------------|
| Parte A (70/30) | 37/17 | M1 (rígido) | 4,82 |
| Parte B (60/20/20) | 32/10/12 | M2 (flexível) | 2,73 |

Duas coisas chamam atenção:

1. **O modelo escolhido mudou** (M1 vs M2) apenas por mudar o split. Os
   dois candidatos são praticamente **indistinguíveis** — a diferença entre
   eles é da ordem do ruído amostral.

2. **O RMSE do teste final caiu para quase metade** (4,82 → 2,73). Isso
   **não** significa que o modelo ficou melhor. Significa que o conjunto de
   teste da Parte B tem observações mais "fáceis" de prever (teste menor =
   mais instável).

**Lição:** em amostra pequena, decisões de seleção são **dominadas pelo
split**, não pelos méritos dos modelos. Reportar as duas versões é o que
torna a análise honesta.

## 5. Parte C — O U do erro de teste (viés-variância)

### 5.1 Números por grau

| Grau | MSE treino | MSE teste | RMSE teste |
|------|-----------|-----------|------------|
| 1 | 9,61 | 23,22 | 4,82 |
| 2 | 8,12 | 19,96 | 4,47 |
| **3** | **7,38** | **17,12** | **4,14** |
| 5 | 5,77 | **715,42** | 26,75 |
| 8 | 5,61 | **6.659,43** | 81,61 |
| 12 | **8,28 × 10³³** | **2,93 × 10⁴¹** | 5,42 × 10²⁰ |

### 5.2 Leitura visual

![](https://raw.githubusercontent.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/main/estrutura/scriptsR/figuras/fig5_u_erro.png)

O gráfico coloca **treino (azul)** e **teste (vermelho)** no mesmo eixo, em
função do grau do polinômio. Três coisas ficam visíveis:

1. **Shelf descendente nos graus 1–3.** As duas curvas caem juntas. O
   treino cai de 9,6 para 7,4; o teste cai de 23,2 para 17,1. Não há
   sacrifício de variância — a flexibilidade está **ajudando**.
2. **Salto abrupto no grau 5.** A curva do teste sai de 17,1 (grau 3) e
   salta para 715 — **30×** maior. Isto **não é o topo suave do U**; é um
   degrau vertical.
3. **Explosão catastrófica no grau 12.** Note que **as duas curvas
   explodem** — inclusive a de treino (8,28 × 10³³). Um modelo que
   sobreajustasse ainda teria erro de treino pequeno. Aqui, o erro de
   treino também é astronômico → **falha numérica**, não sobreajuste.

### 5.3 O que causou o colapso

`poly(x, g)` no R produz polinômios ortogonais, mas mesmo a ortogonalização
não salva escalas extremas em grau alto. Com PIB variando 20000–270000, os
polinômios de grau 5+ geram colunas quase degeneradas — a matriz de desenho
fica mal-condicionada e o ajuste explode.

**Correção natural** (fora do escopo do script): **padronizar** `pib_per_capita`
antes de gerar o polinômio (`scale()`), ou usar graus mais modestos. O slide
8 já avisa: *"cuidado: em grau alto, não interprete cada βⱼ isoladamente, e
não extrapole fora da faixa"*.

### 5.4 O que resta como conclusão válida

Restringindo aos graus **1–3** (a única faixa onde o modelo é válido), não
há evidência de trade-off viés-variância clássico:

- Treino cai monotonamente (7,38 → 9,61, ou seja, 22% melhor).
- Teste cai monotonamente (17,12 → 23,22, ou seja, 26% melhor).
- Não há ponto onde o teste **subir** por variância.

**Interpretação substantiva:** a rigidez do grau 1 está custando **viés**.
O grau 3 (uma curva suave) captura melhor a relação que a reta. Mas o ganho
é pequeno — porque o sinal real é fraco. Não há um "U invertido" que
sacrifique viés por variância: a flexibilidade está **ajudando** até o
limite do que é numericamente estável.

## 6. Parte D — Comparação dos candidatos no teste

### 6.1 Faixa das previsões

| Modelo | Mínimo | Máximo | Amplitude |
|--------|--------|--------|-----------|
| M1 (rígido) | 17,36 | 19,93 | **2,56** |
| M2 (flexível) | 15,13 | 20,54 | **5,41** |
| Real | 14,65 | 33,00 | 18,35 |

### 6.2 Correlação previsto × real

| Modelo | Correlação |
|--------|-----------|
| M1 | **0,348** |
| M2 | 0,236 |

### 6.3 Leitura visual

![](https://raw.githubusercontent.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/main/estrutura/scriptsR/figuras/fig5_previsto_real_candidatos.png)

O gráfico sobrepõe os dois candidatos no mesmo plano (previsto × real),
usando os mesmos 17 pontos de teste. Cada ponto aparece duas vezes — uma
vez colorido de azul (M1), outra de vermelho (M2).

O que a figura mostra:

- **Ambos os modelos produzem faixas horizontais achatadas.** M1 e M2 são
  visualmente quase indistintos na maior parte da faixa — ambos empilham
  as previsões em torno de y ≈ 18–20.
- **M2 se estende um pouco mais para baixo** (mínimo 15,1 vs 17,4 em M1),
  por causa da flexibilidade extra do preditor `distorcao_em`. Mas essa
  extensão **não coincide com os pontos reais baixos** — é ruído, não sinal.
- **Os pontos de real alto (28–33) ficam descolados** dos dois modelos.
  Nenhum dos candidatos se aproxima deles. A diagonal tracejada é um alvo
  que nenhum dos dois alcança na região de mortalidade alta.
- **Visualmente, M1 e M2 se sobrepõem** na maior parte do gráfico. Confirmam
  numericamente o que os RMSE já diziam: são equivalentes.

**Interpretação:** M2 adicionou flexibilidade — mas na direção errada. A
amplitude das previsões dobrou (2,56 → 5,41), porém a correlação com o real
**caiu** (0,348 → 0,236) e o RMSE piorou ligeiramente. O modelo ganhou
**ruído**, não **sinal**. A escolha certa é M1.

## 7. Parte E — Sensibilidade sem Cubatão

### 7.1 Números por grau (sem Cubatão)

| Grau | MSE treino | MSE teste |
|------|-----------|-----------|
| 1 | 6,06 | 26,16 |
| 2 | 6,00 | 27,23 |
| 3 | 5,75 | 27,61 |
| 5 | 5,53 | 28,25 |
| 8 | 4,80 | 218,08 |
| 12 | 4,15 | 2,33 × 10⁶ |

### 7.2 Leitura

Sem Cubatão, o padrão muda:

- **Sem "shelf" descendente.** O MSE de teste começa em 26,16 (grau 1) e
  **sobe** monotonamente até 28,25 (grau 5). O grau 1 já é o mínimo.
- **Colapso a partir do grau 8.** Mesmo fenômeno numérico do caso com
  Cubatão, mas em grau mais alto.

**Interpretação:** com Cubatão removido, o sinal fica mais forte, e o grau
1 (reta) já captura quase tudo. Flexibilidade adicional **piora** — é o U
clássico começando desde o grau 1. Isso confirma o que os scripts 1–4
sugeriam: **Cubatão é o ponto que exige flexibilidade extra**; sem ele, a
reta basta.

### 7.3 Comparação com/sem Cubatão, grau 1

| Cenário | MSE treino | MSE teste |
|---------|-----------|-----------|
| Com Cubatão | 9,61 | 23,22 |
| **Sem Cubatão** | **6,06** | **26,16** |

Contraste revelador:

- **Treino melhora** sem Cubatão (9,61 → 6,06) — a reta ajusta melhor.
- **Teste piora** sem Cubatão (23,22 → 26,16) — generaliza pior.

Motivo: o split da Parte E é diferente do split da Parte A (o `set.seed(42)`
reorganiza 48 obs em vez de 54). Os conjuntos de teste não são os mesmos. A
comparação não é controlada, mas o padrão dialoga com os scripts 3 e 4:
**a remoção de Cubatão não melhora a generalização**, porque o ponto
"atípico" continua existindo no mundo real.

## 8. Discussão e síntese

### 8.1 Achados principais

1. **Dois candidatos quase equivalentes.** M1 e M2 no teste têm RMSE 4,82
   e 4,92 — diferença dentro do ruído amostral. Adicionar `distorcao_em`
   aumenta o R² treino (0,035 → 0,136) mas **não generaliza**.

2. **A escolha depende do split, não dos modelos.** Com split 70/30, M1
   ganha; com split 60/20/20, M2 ganha. Em amostra pequena, o split
   domina o mérito.

3. **Não há U clássico.** Nos graus válidos (1–3), o teste só desce. Graus
   ≥ 5 colapsam numericamente. A flexibilidade extra, quando existe,
   **ajuda** (reduz viés) — não prejudica (não aumenta variância
   perceptivelmente). O problema é que ela quebra antes de fazer mal.

4. **Cubatão continua sendo o nó.** Com Cubatão, o grau 1 fica rígido
   demais. Sem Cubatão, o grau 1 já basta. A "necessidade de flexibilidade"
   neste banco é, em grande parte, um efeito do ponto extremo.

### 8.2 Vazamento — autocrítica retroativa

A Aula 6 (slide 23) lista três flagrantes de vazamento. Revisitando os
scripts 1–4, há dois pontos que merecem registro honesto:

**(a) Escolha de preditor usando a amostra completa.** Nos scripts 1–4
escolhemos PIB e descartamos `Longevidade`, `Riqueza`, `IPDM` por
circularidade — analisando o banco inteiro. Do ponto de vista de desenho,
é aceitável (é uma decisão baseada em metodologia, não em performance).
Mas é uma decisão que "viu" a amostra toda antes do split.

**(b) Mediana da amostra completa no alvo binário.** Em scripts 2 e 4
usamos a mediana de 54 obs para definir `mortalidade_alta`. O rigoroso
seria calcular a mediana **só no treino** e aplicá-la ao teste. Optamos
por manter a comparabilidade com o script 2 — trade-off explícito.

Nenhum dos dois é catastrófico, mas ambos merecem constar como limitação
declarada — não como erro escondido.

### 8.3 Recomendação final

Entre os candidatos considerados:

- **M1 (rígido)** é a escolha defensável. Empata tecnicamente com M2, mas
  é mais parcimonioso e não depende de um preditor que pode não estar
  disponível em produção.
- **Polinômios de grau ≥ 5** são **inutilizáveis** neste banco por
  instabilidade numérica — não porque "sobreajustam", mas porque o `poly()`
  não suporta a escala de PIB.

**Direção de aprofundamento** (não mais flexibilidade no mesmo preditor):
- Padronizar o PIB antes de gerar polinômios, para verificar se o colapso
  era numérico ou real.
- Adicionar preditores substantivamente diferentes (saneamento, estrutura
  etária, acesso a saúde).
- Modelos com efeitos fixos por município.

## 9. Amarração com os demais scripts

- **Scripts 1–2** (amostra completa): descritivos. Estabeleceram o sinal.
- **Scripts 3–4** (split 70/30): primeiros exercícios out-of-sample.
- **Script 5** (esta aula): protocolo formal. Formaliza treino/validação/teste
  e o trade-off viés-variância.
- **Fio condutor:** o achado central dos scripts 1–4 — Cubatão mascara a
  relação renda–saúde — reaparece aqui em forma de "o grau 1 basta quando
  Cubatão está fora".