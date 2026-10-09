# Atividade 04 — Regressão logística: quando a curva também não salva

> **Este documento é o resultado do script**
> [`estrutura/scriptsR/04-regressao-logistica.R`](https://github.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/blob/main/estrutura/scriptsR/04-regressao-logistica.R).
> O script produz os números; este consolidado é a leitura humana deles —
> com o porquê das decisões e o que aprender com cada resultado.

> **Alvo:** `mortalidade_alta` = 1 se `mortalidade_60_69` > mediana.  
> **Baseline herdado:** acurácia ≈ 50% (classes balanceadas por construção).

## Por que trocar a reta por uma curva?

Na atividade anterior, tentamos descrever a mortalidade como uma função linear da escolaridade. Deu em nada — e aprendemos bastante com esse nada.

Agora fazemos uma pergunta diferente. Em vez de "**quanto** muda a mortalidade?", perguntamos "**qual é a probabilidade** de um município-ano estar no grupo de mortalidade alta?". Duas mudanças conceituais importantes:

1. **O alvo vira binário.** Cada observação é 0 ou 1, não mais um número contínuo. Binarizamos pela mediana: quem está acima dela é "alta mortalidade" (1), quem está abaixo é "baixa" (0). Como vimos na atividade 02, isso dá exatamente 27 e 27 — 50/50.

2. **O modelo vira uma curva sigmoide.** Uma reta poderia prever valores como −5 ou +100, que não fazem sentido para uma probabilidade (que precisa estar entre 0 e 1). A **logística** resolve isso ao comprimir qualquer reta para o intervalo (0,1), através da função logística.

O resultado é a **curva em S** que dá nome à regressão logística.

---

## O modelo, por dentro

O modelo ajustado foi:

    logit(p) = −1,7776 + 3,6486 × escolaridade

O **logit** é o logaritmo da razão de chances (*odds*):

    logit(p) = log( p / (1−p) )

Por que usar logit em vez de modelar p diretamente? Porque o logit transforma probabilidades (limitadas entre 0 e 1) em uma escala que vai de −∞ a +∞, onde a matemática da regressão linear funciona bem. Depois, a função logística desfaz a transformação.

### A tabela de coeficientes

| Termo | Estimativa | EP | z | p |
|---|---|---|---|---|
| Intercepto | −1,7776 | 2,1935 | −0,8104 | 0,4177 |
| `escolaridade` | 3,6486 | 4,4655 | 0,8171 | **0,4139** |

Vamos por partes, com a mesma calma da atividade anterior.

**O sinal é positivo.** β₁ = +3,6486. Isso significa: à medida que a escolaridade sobe, o logit de "mortalidade alta" também sobe. Ou seja, o modelo está dizendo que **mais escolaridade está associada a mais chance de mortalidade alta** — o oposto da intuição substantiva.

**Mas o coeficiente não é significativo.** O erro-padrão (4,47) é maior do que a estimativa (3,65). A razão z é 0,817 — ou seja, o coeficiente está a menos de um erro-padrão de zero. O valor-p é 0,4139: se não houvesse relação alguma, teríamos 41% de chance de observar um coeficiente tão extremo. Não há evidência.

**Compare com a atividade 03.** Lá, o modelo linear deu β₁ = −2,10 (negativo, protetor). Aqui, o logístico dá β₁ = +3,65 (positivo, prejudicial). **Os sinais se contradizem** — e ambos são não-significativos.

Isso merece uma pausa. Não é que a realidade tenha mudado entre uma análise e outra. É que, quando o sinal é fraco, **modelos diferentes amplificam ruídos diferentes** e podem apontar para lados opostos. A única conclusão honesta é: **não sabemos qual é o sinal**.

### A razão de chances exp(β₁)

Em logística, costumamos interpretar exp(β₁), que é a **razão de chances**:

    exp(3,6486) = 38,4221

Tradução literal: cada +1 em escolaridade multiplica a chance de mortalidade alta por **38,42**.

Mas atenção: escolaridade é um índice **0–1**. Um "+1" seria uma variação completa de 0 a 1 — algo que não ocorre em nenhuma observação real (os valores vão de 0,334 a 0,602). Portanto, o número 38,42 é matematicamente correto mas substantivamente enorme apenas porque a escala do preditor é pequena.

Uma leitura mais útil: um aumento de 0,10 em escolaridade (aproximadamente o desvio-padrão) multiplicaria a chance por:

    exp(3,6486 × 0,10) = exp(0,3649) ≈ 1,44

Ou seja, +44% de chance. Ainda é um efeito grande em teoria — mas, repetindo, **não significativo**. Esses 44% são ruído amplificado, não descoberta.

## O ponto de virada: x* = 0,487

A pergunta natural em classificação: **a partir de qual valor de escolaridade a probabilidade prevista cruza 0,5?** Ou seja, onde o modelo "decide" que a observação é de mortalidade alta?

Isso acontece quando o logit é zero:

    0 = −1,7776 + 3,6486 × x*  
    x* = 1,7776 / 3,6486 = **0,487**

O valor 0,487 cai dentro da faixa observada de escolaridade (0,334 a 0,602), o que é bom — não é uma extrapolação. Mas ele fica praticamente na **mediana da variável** (que é ~0,49). Ou seja, o modelo está essencialmente dividindo a amostra em duas metades pela escolaridade, o que é exatamente o que a mediana faz com a mortalidade. Nada surpreendente — e, veremos, nada útil.

---

## A primeira matriz de confusão da nossa vida

Aqui entra um conceito novo. Em regressão, olhávamos RMSE e R². Em **classificação**, olhamos uma tabela chamada **matriz de confusão**, que organiza os acertos e erros em quatro categorias:

| | Previsto 0 | Previsto 1 |
|---|---|---|
| **Real 0** | Verdadeiro Negativo (VN) | Falso Positivo (FP) |
| **Real 1** | Falso Negativo (FN) | Verdadeiro Positivo (VP) |

No nosso caso, com limiar 0,5:

| | Previsto 0 | Previsto 1 |
|---|---|---|
| **Real 0** | 14 | 13 |
| **Real 1** | 12 | 15 |

Traduzindo: dos 27 município-anos de mortalidade baixa, o modelo acertou 14 e errou 13. Dos 27 de mortalidade alta, acertou 15 e errou 12. É quase um cara-ou-coroa.

### As métricas derivadas

| Métrica | Fórmula | Valor | Leitura |
|---|---|---|---|
| Acurácia | (VP+VN)/total | 0,537 | 53,7% de acerto geral |
| Precisão | VP/(VP+FP) | 0,536 | quando diz "alta", acerta 53,6% |
| Recall (sensibilidade) | VP/(VP+FN) | 0,556 | encontra 55,6% dos casos reais de alta |
| Especificidade | VN/(VN+FP) | 0,519 | encontra 51,9% dos casos reais de baixa |

Compare com o baseline:

    Acurácia_baseline = 50%
    Acurácia_modelo   = 53,7%

Ganho de 3,7 pontos percentuais. É positivo — mas é o tipo de ganho que some se você mudar uma observação de lugar. Dado o tamanho da amostra, esse ganho é indistinguível de sorte.

### Curiosidade didática: precisão e recall

Essas duas métricas merecem um comentário porque costumam confundir.

- **Precisão** responde: *"das vezes que o modelo gritou 'alta!', quantas ele acertou?"* — mede a qualidade dos alarmes.
- **Recall** responde: *"dos casos que realmente eram alta, quantos o modelo pegou?"* — mede a cobertura.

Em aplicações médicas, geralmente se prefere **recall alto** (não deixar passar doente). Em spam, geralmente se prefere **precisão alta** (não jogar e-mail bom no lixo). Nosso problema aqui não tem uma preferência clara — e, dado que nenhuma métrica passa de 0,56, o debate é mais didático que prático.

---

## Limiares: 0,3, 0,5 e 0,7

A matriz acima usa o limiar padrão de 0,5 — se a probabilidade prevista passa disso, classificamos como "alta". Mas esse limiar é uma **escolha**, não uma imposição da matemática. Vale ver o que acontece em outros limiares:

**Limiar 0,3:**

```
    previsto
real  1
   0 27
   1 27
```

Todos os 54 casos são classificados como "alta". Acurácia = 50%. É o chute puro e simples, mas com uma roupagem diferente.

**Limiar 0,5:** (já visto acima) — 53,7%.

**Limiar 0,7:**

```
    previsto
real  0
   0 27
   1 27
```

Todos os 54 casos são classificados como "baixa". Acurácia = 50%. De novo, chute puro.

Esse comportamento é revelador: o modelo **não tem probabilidades bem calibradas** para separar as classes. Ele é muito "medroso" — quase todas as previsões ficam longe de 0 ou 1. Basta um limiar um pouco mais permissivo (0,3) para todo mundo virar "alta"; basta um pouco mais exigente (0,7) para todo mundo virar "baixa".

Isso é o retrato matemático do que já suspeitávamos: **o modelo praticamente não tem sinal**.

---

## AUC: a métrica que ignora o limiar

Existe uma métrica que resolve o problema de "qual limiar escolher": a **área sob a curva ROC** (AUC).

A curva ROC (Receiver Operating Characteristic) foi criada na Segunda Guerra Mundial para avaliar radares militares. Ela plota, para cada limiar possível:

- **Eixo X — FPR (taxa de falsos positivos):** quando dizemos "alta" mas é baixa.
- **Eixo Y — TPR (taxa de verdadeiros positivos, o mesmo que recall):** quando dizemos "alta" e é alta.

A curva começa em (0,0), termina em (1,1) e descreve o trade-off entre sensibilidade e especificidade conforme o limiar varia.

A AUC é a **área sob essa curva**, e tem uma interpretação elegante:

> A AUC é a probabilidade de que o modelo dê uma probabilidade maior a um caso positivo aleatório do que a um caso negativo aleatório.

Escala:

- **AUC = 0,5:** o modelo é aleatório (a curva é a diagonal).
- **AUC = 1,0:** o modelo é perfeito (a curva é um canto reto).

**Nosso resultado: AUC = 0,56.**

Traduzindo para probabilidade: o modelo tem 56% de chance de ordenar corretamente um par aleatório (caso positivo, caso negativo). Se fosse uma moeda, seria 50%. Se fosse um modelo útil, seria acima de 0,7.

O modelo está **marginalmente acima da moeda**. Esse 0,56 é o tipo de número que, com n = 54, pode perfeitamente ser ruído. Não é possível afirmar que há sinal real com essa AUC.

---

## Youden: qual o "melhor" limiar?

Se tivermos que escolher um limiar único, um critério razoável é o **índice de Youden**:

    J = TPR − FPR

Ele maximiza simultaneamente sensibilidade e especificidade. O limiar que atinge esse ponto ótimo foi:

| Métrica | Valor |
|---|---|
| Limiar ótimo (Youden) | 0,477 |
| TPR | 0,815 |
| FPR | 0,630 |
| Youden (J) | 0,185 |

Confusão nesse limiar:

| | Previsto 0 | Previsto 1 |
|---|---|---|
| **Real 0** | 10 | 17 |
| **Real 1** | 8 | 19 |

Aqui vemos um comportamento mais assimétrico: o modelo acerta 19 dos 27 casos de "alta" (bom recall) mas erra 17 dos 27 casos de "baixa" (muita sensibilidade). É um trade-off clássico — o modelo prefere "gritar alta" para não perder casos. Mas o Youden resultante é baixíssimo (0,185, contra um máximo teórico de 1,0). O "melhor" limiar do modelo é, honestamente, ainda ruim.

---

## As duas figuras

### Figura 1 — A curva sigmoide

![Curva logística: probabilidade prevista de mortalidade alta em função da escolaridade](https://raw.githubusercontent.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/main/estrutura/scriptsR/figuras/04-regressao-logistica_img1.png)

Esta figura é o retrato do modelo. Os pontos azuis são os dados reais (0 ou 1). A curva laranja é a probabilidade prevista pelo modelo. A linha vertical tracejada marca x* = 0,487 — onde a probabilidade cruza 0,5.

O que observar:

1. **A curva é suave, mas pouco inclinada.** Ela sai de valores baixos (mas não muito próximos de 0) à esquerda e chega a valores altos (mas não muito próximos de 1) à direita. É uma S "preguiçosa".

2. **Os pontos 0 e 1 estão espalhados por toda a faixa horizontal.** Em baixa escolaridade, há pontos tanto em 0 quanto em 1. Em alta escolaridade, idem. O modelo não consegue separar bem as duas classes.

3. **A linha vertical x* passa pelo meio da nuvem.** Sem marcar uma fronteira natural — porque não há uma fronteira natural nos dados.

Uma curva sigmoide "saudável" seria muito mais íngreme, com os pontos 0 concentrados à esquerda e os pontos 1 à direita. Aqui, é praticamente uma reta levemente inclinada — sinal de que a informação disponível não permite separação.

### Figura 2 — A curva ROC

![Curva ROC: TPR vs FPR, com pontos em limiares 0.3, 0.5, 0.7](https://raw.githubusercontent.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/main/estrutura/scriptsR/figuras/04-regressao-logistica_img2.png)

A curva laranja é a ROC. A diagonal cinza tracejada é o "aleatório" (AUC = 0,5). Os pontos roxos marcam os limiares 0,7, 0,5 e 0,3 sobre a curva.

O que observar:

1. **A curva ROC está muito próxima da diagonal.** Não há "barriga" — não há região onde o modelo claramente ganhe do aleatório. A AUC = 0,56 captura esse "quase nada".

2. **Os pontos dos limiares são reveladores.** O ponto de limiar 0,5 fica perto da diagonal, e os pontos 0,3 e 0,7 deslizam para os extremos — confirmando o que vimos na seção anterior: o modelo não tem calibração útil.

3. **Compare com o que seria um bom classificador:** uma curva que sobe rápido para o canto superior esquerdo, "abraçando" a área. Aqui, a curva segue timidamente a diagonal.

---

## Síntese: o que esta atividade ensina

Duas conclusões merecem ser guardadas.

**Primeira: nem toda mudança de modelo melhora o resultado.**

A atividade 03 (linear) deu β₁ negativo, não significativo. A atividade 04 (logístico) deu β₁ positivo, também não significativo. **Os sinais se contradizem**. Isso não é um problema do script nem uma incoerência metodológica — é o sintoma clássico de **sinal fraco em amostra pequena**. Modelos diferentes amplificam ruídos diferentes. Se houvesse sinal real, ambos tenderiam a concordar sobre a direção.

**Segunda: classificação exige vocabulário novo — e cuidado com ele.**

Aprendemos hoje:

- **Matriz de confusão**, precisão, recall, especificidade.
- **Limiar de decisão** como uma escolha, não uma imposição.
- **AUC** como métrica livre de limiar.
- **Youden** como critério para escolher um limiar.

Todas essas métricas ficaram na faixa "chute honesto": acurácia 0,537, AUC 0,56, Youden 0,185. Nenhuma linha de corte dessas salva o modelo.

O que fica desta atividade:

1. **Modelo logístico:** logit(p) = −1,7776 + 3,6486 × escolaridade. Não significativo (p = 0,41).
2. **exp(β₁) = 38,42**, mas o número é enganoso pela escala do preditor, e não significativo de qualquer forma.
3. **x* = 0,487** — fronteira de decisão dentro da faixa dos dados, mas no meio da distribuição.
4. **Acurácia 0,537 | AUC 0,56** — marginalmente acima do aleatório.
5. **Sinal contradiz o modelo linear.** Ambos não significativos. Não sabemos qual é o sinal, e essa é a resposta honesta.
6. **AUC e Youden são ferramentas novas** — que vamos reusar nas próximas atividades com outros preditores e modelos.

A próxima pergunta natural: será que o problema é o modelo, ou é a forma como estamos usando os dados? A atividade 05 começa a testar **separação treino/teste** e **validação cruzada** — técnicas que nos protegem contra autoengano.

---

## Documentos complementares

**Script que gera este consolidado:**
- 🧮 [`04-regressao-logistica.R`](https://github.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/blob/main/estrutura/scriptsR/04-regressao-logistica.R) — **a fonte** deste documento.

**Demais documentos relacionados:**
- 📋 [Relatório técnico do script (`04-regressao-logistica.md`)](https://github.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/blob/main/estrutura/scriptsR/04-regressao-logistica.md) — output bruto, sem a camada didática.
- 📎 [Consolidado 01 — Dicionário de variáveis](https://github.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/blob/main/consolidado/01-dicionario-variaveis.md).
- 📎 [Consolidado 02 — Análise exploratória](https://github.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/blob/main/consolidado/02-analise-exploratoria.md).
- 📎 [Consolidado 03 — Regressão linear](https://github.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/blob/main/consolidado/03-regressao-linear.md).
- 📊 [Banco de dados (CSV)](https://github.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/blob/main/estrutura/bancoDeDados/df_ipdm_baixada_por_municipio.csv).
- 📄 [Dicionário de dados (PDF)](https://github.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/blob/main/estrutura/dicionario/dicionario_ipdm_baixada.pdf).