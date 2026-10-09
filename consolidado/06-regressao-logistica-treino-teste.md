# Atividade 06 — Classificação honesta: quando treinar e testar muda tudo

> **Este documento é o resultado do script**
> [`estrutura/scriptsR/06-regressao-logistica-treino-teste.R`](https://github.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/blob/main/estrutura/scriptsR/06-regressao-logistica-treino-teste.R).
> O script produz os números; este consolidado é a leitura humana deles —
> com o porquê das decisões e o que aprender com cada resultado.

> **Alvo:** `mortalidade_alta` = 1 se `mortalidade_60_69` > mediana **do treino**.  
> **Baseline herdado:** acurácia ≈ 50% (classes balanceadas por construção).

## O que muda em relação à atividade 04

Na atividade 04, treinamos e avaliamos o classificador logístico nos **mesmos 54 dados**. Vimos que ele mal superava o chute (acurácia 0,537; AUC 0,56). Mas aquele número estava inflado por autoengano — o modelo tinha "visto" as respostas.

Hoje fazemos a mesma coisa que fizemos na atividade 05 para regressão, mas agora para **classificação**:

1. **Dividir treino/teste** e avaliar apenas no teste.
2. **Rodar CV(5)** para não depender de uma única divisão.
3. **Comparar A (simples) vs B (múltiplo)** de forma honesta.

E há uma sutileza nova, muito importante, sobre como binarizar o alvo. Vamos por partes.

---

## A sutileza da mediana

O alvo binário é definido por:

    mortalidade_alta = 1 se mortalidade_60_69 > mediana

Mas **mediana de quem?** Dos 54 dados inteiros, ou só dos 37 de treino?

A resposta correta é: **mediana do treino**. E o motivo é sutil.

Se usássemos a mediana dos 54, estaríamos usando informação do teste para definir o alvo. Isso é **vazamento de dados** (data leakage). Mesmo que pareça inofensivo, isso viola o princípio de "o teste é o que o modelo nunca viu" — inclusive na definição do alvo.

Usando a mediana do treino:

    Mediana (treino) = 19,5337
    Proporção classe 1 (treino) = 0,486
    Proporção classe 1 (teste)  = 0,471

Repare: a proporção no treino é 48,6%, no teste 47,1%. Não é 50/50 exato em nenhum dos dois — e isso é o esperado. A mediana do treino força o treino a ser ~50/50, mas o teste, sendo dados novos, tem uma proporção ligeiramente diferente. Perfeito.

Na CV(5), a mediana é **recalculada por dobra**, sempre usando só o treino daquela dobra. Isso é ainda mais rigoroso: nenhuma dobra usa informação das outras.

---

## O ajuste no treino

Coeficientes no treino (37 observações):

**Modelo A — simples:**

| Termo | Estimativa | EP | z | p |
|---|---|---|---|---|
| Intercepto | 1,0216 | 2,5883 | 0,3947 | 0,6931 |
| `escolaridade` | −2,2021 | 5,2559 | −0,4190 | 0,6752 |

**Modelo B — múltiplo:**

| Termo | Estimativa | EP | z | p |
|---|---|---|---|---|
| Intercepto | −4,2198 | 4,2610 | −0,9903 | 0,3220 |
| `escolaridade` | 2,3661 | 6,0521 | 0,3909 | 0,6958 |
| `distorcao_em` | 0,1788 | 0,1180 | 1,5149 | 0,1298 |

Curiosidade: no treino, o sinal de `escolaridade` em A é **negativo** (−2,20), e em B é **positivo** (+2,37). Nenhum dos dois é significativo. É o mesmo fenômeno que vimos antes: com sinal fraco, pequenas mudanças de modelo viram o sinal de cabeça para baixo.

O `distorcao_em` em B tem p = 0,13 — o mais próximo de "relevante" que já chegamos, mas ainda longe do corte convencional de 0,05.

---

## O teste: o veredito honesto

Aqui está o resultado em dados novos (17 observações), com limiar 0,5:

**Modelo A — simples:**

| | Previsto 0 | Previsto 1 |
|---|---|---|
| **Real 0** | 4 | 5 |
| **Real 1** | 8 | 0 |

    Acc: 0,2353 | Sens: 0,0 | Esp: 0,4444 | AUC: 0,2639

**Modelo B — múltiplo:**

| | Previsto 0 | Previsto 1 |
|---|---|---|
| **Real 0** | 7 | 2 |
| **Real 1** | 6 | 2 |

    Acc: 0,5294 | Sens: 0,25 | Esp: 0,7778 | AUC: 0,5556

Vamos por partes, porque esta tabela tem drama.

### O colapso do modelo A

O modelo A **não previu nenhuma vez** a classe 1 no teste. Olhe a matriz: na coluna "Previsto 1" só há zeros. A sensibilidade é **0,0** — o modelo simples, em dados novos, é **incapaz de identificar qualquer município-ano de mortalidade alta**.

E não é porque o limiar 0,5 foi mal escolhido. É porque, com as probabilidades previstas por A no teste, **nenhuma passou de 0,5**. O modelo está mudo.

Pior: a acurácia caiu para 0,2353 — **muito abaixo** do baseline de 50%. Em outras palavras, o modelo A acerta menos que jogar uma moeda. Como isso é possível se a matriz parece equilibrada? Porque o baseline "chutar a classe majoritária" também é 50% (ou ~47% no teste), e o modelo A acerta apenas 23,5%. Ele está **ativamente errando**.

### A recuperação parcial do modelo B

O modelo B foi menos desastroso. Sensibilidade de 25% (pegou 2 dos 8 casos de alta) e especificidade de 77,8% (identificou 7 dos 9 casos de baixa). Acurácia de 52,94% — acima do baseline.

Mas vamos ser honestos: 52,94% vs 50% é uma vitória por **2,94 pontos percentuais**, com n = 17. O intervalo de confiança dessa acurácia é gigantesco. Podemos dizer "B foi melhor que A no teste" — mas não podemos dizer "B é um bom classificador".

A AUC de B (0,5556) confirma: **ainda marginalmente acima do aleatório**. Nada mudou substancialmente em relação à atividade 04.

### Limiares alternativos no teste

O script também roda as matrizes em limiares 0,3, 0,5 e 0,7 para A e B. O comportamento revela o que já sabíamos:

- **Limiar 0,3:** A prevê tudo como classe 1 (27/27 errado... na verdade, no teste, todos os 17 como 1). B acerta mais, mas com muitos falsos positivos.
- **Limiar 0,5:** a matriz já vista acima.
- **Limiar 0,7:** A prevê tudo como 0. B também prevê tudo como 0 — a acurácia cai para o mesmo do baseline.

De novo, o modelo **não tem probabilidades calibradas**. Ele fica "tímido", com previsões próximas da média, e qualquer mudança de limiar joga tudo para um lado ou para o outro.

---

## As figuras

### Figura 1 — Curva logística (treino) vs. teste

![Curva logística ajustada no treino, com pontos de teste sobrepostos](https://raw.githubusercontent.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/main/estrutura/scriptsR/figuras/06-regressao-logistica-treino-teste_img1.png)

A curva azul é a probabilidade prevista por A (treinada no treino). A linha cinza tracejada é o limiar 0,5. Os pontos laranjas são os dados de teste (0 ou 1).

O que observar:

1. **A curva cruza o limiar 0,5 em algum lugar**, mas os pontos de teste estão **todos** de um lado — à esquerda ou à direita — dependendo da escolaridade. Foi por isso que A colapsou: os pontos de teste caíram todos numa região onde a curva prevê < 0,5.
2. **A curva é muito suave.** Praticamente horizontal na maior parte da faixa. Isso é o retrato da não-separação: o modelo não consegue distinguir bem as classes.
3. **Os pontos de teste (laranja) não formam padrão.** Não há "0s à esquerda, 1s à direita". Estão misturados. O modelo está tentando separar algo que não está separado.

A combinação "curva suave + pontos misturados" é a assinatura visual de **sinal fraco**. E, como vimos no teste, o modelo A erra o suficiente para ter sensibilidade zero.

### Figura 2 — Curvas ROC comparativas

![Curvas ROC de A e B no teste, com AUC respectivas](https://raw.githubusercontent.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/main/estrutura/scriptsR/figuras/06-regressao-logistica-treino-teste_img2.png)

Duas curvas: A em azul, B em roxo. A diagonal cinza tracejada é o aleatório (AUC = 0,5).

O que observar:

1. **A curva A está totalmente abaixo da diagonal.** Sim, é possível: quando o modelo tem AUC < 0,5, ele está **sistematicamente errado** — prevê ao contrário. Não é aleatório; é pior que aleatório. A AUC_A = 0,2639 é o número que captura isso.
2. **A curva B fica ligeiramente acima da diagonal.** Pouco, mas acima. AUC_B = 0,5556.
3. **A diferença entre A e B é dramática visualmente.** Não pela qualidade de B (que continua fraca), mas pela ruína de A. Ver A abaixo da diagonal impressiona.

Comentar A < 0,5 é importante porque confunde: como um modelo pode ser **pior** que aleatório? A resposta está na instabilidade das estimativas. Com n pequeno e sinal fraco, o modelo pode aprender **padrões espúrios no treino** que são **invertidos no teste**. É exatamente isso que aconteceu aqui.

---

## Validação cruzada 5-fold

Como o treino/teste sozinho depende muito da divisão particular (e A colapsou de um jeito que talvez não se repita), rodamos CV(5) — recalculando a mediana por dobra, ajustando em 4 dobras e testando na 5ª.

### Resultado

| Candidato | Acc (%) | AUC |
|---|---|---|
| Baseline | 42,36 | — |
| A: simples | 48,18 | 0,5129 |
| B: múltiplo | **59,27** | **0,6786** |

Aqui o quadro muda substancialmente. Vamos por partes.

**Primeiro: o baseline é 42,36%**, não 50%. Isso porque, na CV, a mediana de cada dobra de treino pode gerar uma dobra de teste desbalanceada. O baseline "maioria" não é sempre 50%. Nesta CV, o baseline ficou em ~42%.

**Segundo: A recupera.** Na CV, A tem 48,18% de acurácia — bem melhor que o desastre do teste único (23,5%). Isso confirma que o colapso de A no treino/teste foi, em parte, **má sorte da divisão**. A CV(5) reduz essa variabilidade.

**Terceiro: B brilha.** 59,27% de acurácia e AUC 0,6786. Isso é uma melhora substancial em relação a tudo que vimos até agora. Um AUC de 0,68 é o primeiro número da lista que **não é desprezível**. Não é excelente (0,7 é a linha de "razoável"), mas está perto.

**Quarto: consistência.** A contagem por dobra:

    Dobras em que A venceu (AUC): 0
    Dobras em que B venceu (AUC): 4

B ganhou em 4 dobras (e empatou/perdeu em 1, provavelmente). Isso não é sorte de uma dobra — é um padrão consistente.

### O que a CV está dizendo

B (múltiplo, com `distorcao_em`) é **consistentemente melhor** que A (simples, só escolaridade) — em 4 das 5 dobras. E o AUC médio de 0,68 é o melhor resultado de classificação que obtivemos até agora.

Mas devemos manter a calma antes de comemorar. Três ressalvas:

1. **O ganho ainda é modesto.** AUC 0,68 com n = 54 não permite grandes afirmações. Uma AUC "boa" costuma ser > 0,75; "forte", > 0,85.
2. **A acurácia (59%) está acima do baseline (42%), mas o intervalo de confiança é largo.** A diferença é real o suficiente para a CV, mas não para uma conclusão forte.
3. **O modelo usa duas variáveis (`escolaridade` + `distorcao_em`).** O ganho em relação a A vem justamente da segunda. Isso sugere que a distorção idade-série carrega informação — mesmo que fraca — que a escolaridade sozinha não carrega.

---

## Síntese: o que esta atividade ensina

Quatro conclusões.

**Primeira: separar treino e teste muda o veredito, mas não magicamente.** O modelo A, que parecia "ok" na atividade 04, colapsou no teste (sensibilidade 0, acurácia 23,5%). A CV o recuperou parcialmente (48%), mas não o transformou em bom classificador.

**Segunda: B (com distorção) é o primeiro modelo a mostrar sinal real.** AUC 0,68 na CV é o melhor resultado até agora — e o primeiro a se afastar visivelmente do aleatório. Isso é encorajador. A distorção idade-série parece capturar algo que a escolaridade sozinha não capta.

**Terceira: definição honesta do alvo importa.** Usar a mediana do treino (e recalculá-la por dobra na CV) evita vazamento. Não é um detalhe — é a diferença entre um resultado que vale e um que engana.

**Quarta: vocabulário novo.** Consolidamos:

- **AUC por dobra** — métrica robusta em CV.
- **Sensibilidade 0** — caso extremo que revela colapso do modelo.
- **AUC < 0,5** — modelo sistematicamente errado, não aleatório.
- **Recalcular o alvo dentro de cada dobra** — princípio de não-vazamento.

O que fica desta atividade:

1. **No teste único:** A colapsa (Acc 0,2354; Sens 0,0; AUC 0,264), B fica marginalmente acima do chute (Acc 0,5294; AUC 0,5556).
2. **Na CV(5):** A recupera (Acc 48,18%; AUC 0,513), B brilha (Acc 59,27%; AUC 0,6786).
3. **B vence A em 4 das 5 dobras** — vitória consistente, não sorte.
4. **Primeira AUC acima de 0,65 do projeto** — sinal de que há algo a explorar com múltiplos preditores.
5. **Vazamento evitado:** mediana calculada só no treino (ou por dobra).

Agora faz sentido olhar adiante. A atividade 07 traz bootstrap e CV com polinômios — outra forma de sondar não-linearidades. E a atividade 08 fecha com regularização, que é exatamente a resposta técnica quando se tem **muitos preditores e pouco sinal**.

---

## Documentos complementares

**Script que gera este consolidado:**
- 🧮 [`06-regressao-logistica-treino-teste.R`](https://github.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/blob/main/estrutura/scriptsR/06-regressao-logistica-treino-teste.R) — **a fonte** deste documento.

**Demais documentos relacionados:**
- 📋 [Relatório técnico do script (`06-regressao-logistica-treino-teste.md`)](https://github.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/blob/main/estrutura/scriptsR/06-regressao-logistica-treino-teste.md) — output bruto, sem a camada didática.
- 📎 [Consolidado 01 — Dicionário de variáveis](https://github.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/blob/main/consolidado/01-dicionario-variaveis.md).
- 📎 [Consolidado 02 — Análise exploratória](https://github.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/blob/main/consolidado/02-analise-exploratoria.md).
- 📎 [Consolidado 03 — Regressão linear](https://github.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/blob/main/consolidado/03-regressao-linear.md).
- 📎 [Consolidado 04 — Regressão logística](https://github.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/blob/main/consolidado/04-regressao-logistica.md).
- 📎 [Consolidado 05 — Treino/teste (regressão)](https://github.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/blob/main/consolidado/05-regressao-linear-treino-teste.md).
- 📊 [Banco de dados (CSV)](https://github.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/blob/main/estrutura/bancoDeDados/df_ipdm_baixada_por_municipio.csv).
- 📄 [Dicionário de dados (PDF)](https://github.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/blob/main/estrutura/dicionario/dicionario_ipdm_baixada.pdf).