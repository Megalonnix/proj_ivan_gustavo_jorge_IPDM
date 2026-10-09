# Atividade 05 — Treino e teste: a arte de não enganar a si mesmo

> **Este documento é o resultado do script**
> [`estrutura/scriptsR/05-regressao-linear-treino-teste.R`](https://github.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/blob/main/estrutura/scriptsR/05-regressao-linear-treino-teste.R).
> O script produz os números; este consolidado é a leitura humana deles —
> com o porquê das decisões e o que aprender com cada resultado.

> **Alvo:** `mortalidade_60_69` (mortes por mil hab., 60–69).  
> **Baseline herdado:** RMSE = 3,8504 (sd de Y).

## O problema que vamos resolver hoje

Nas atividades 03 e 04, ajustamos modelos nos **54 dados inteiros** e depois olhamos o desempenho — também nos 54 dados. Isso tem um nome técnico e feio: **autoengano**.

O raciocínio é simples de entender com uma analogia. Imagine que você estuda para uma prova decorando **o gabarito das questões**. Você tira 10 na prova. Mas isso não diz nada sobre o quanto você aprendeu — porque a prova era exatamente o que você já tinha visto. Um aluno honesto precisa de **questões novas** para saber se de fato aprendeu.

A mesma coisa vale para modelos. Se eu ajusto um modelo em 54 observações e depois meço o erro nas mesmas 54, o modelo tem vantagem indevida — ele "viu" as respostas. A solução é dividir os dados:

- **Treino:** o modelo aprende aqui.
- **Teste:** o modelo é avaliado aqui — em dados que nunca viu.

E, para sermos ainda mais rigorosos, uma segunda técnica chamada **validação cruzada** (CV), que usa cada observação como teste uma vez.

---

## Treino e teste: divisão 70/30

A divisão padrão é separar 70% para treino e 30% para teste. Com n = 54, isso dá:

    n_treino = 37
    n_teste  = 17

Uma semente de aleatoriedade (`set.seed(1)`) garante que a divisão seja reproduzível — quem rodar o script em outra máquina obtém exatamente os mesmos 37 e 17.

### Os dois candidatos

Vamos comparar dois modelos que já conhecemos:

- **A — simples:** `mortalidade ~ escolaridade`
- **B — múltiplo:** `mortalidade ~ escolaridade + distorcao_em`

E, além deles, um terceiro competidor que serve de referência mínima:

- **Baseline — média:** prevê sempre a média do alvo no **treino**.

Se um modelo de verdade não bate a média, ele não merece existir.

### O ajuste no treino

Coeficientes ajustados nos 37 dados de treino:

**Modelo A — simples:**

| Termo | Estimativa | EP | t | p |
|---|---|---|---|---|
| Intercepto | 24,0136 | 5,0905 | 4,7174 | < 0,001 |
| `escolaridade` | −8,8190 | 10,3339 | −0,8534 | 0,3992 |

**Modelo B — múltiplo:**

| Termo | Estimativa | EP | t | p |
|---|---|---|---|---|
| Intercepto | 20,4344 | 8,0746 | 2,5307 | 0,0162 |
| `escolaridade` | −5,6044 | 11,8388 | −0,4734 | 0,6390 |
| `distorcao_em` | 0,1191 | 0,2072 | 0,5747 | 0,5692 |

Nada mudou de figura: nenhum dos coeficientes é significativo. Mas isso agora importa menos — em treino/teste, quem julga é o **teste**.

### Os resultados no teste

| Candidato | RMSE | MAE | R² |
|---|---|---|---|
| Baseline (média do treino) | **3,6782** | 2,9734 | — |
| A: simples | 3,8314 | 3,1914 | −0,1187 |
| B: múltiplo | **3,7887** | 3,0999 | −0,0939 |

Esta tabela merece uma leitura lenta, porque é o coração da atividade.

**Primeiro: o baseline ganhou.** A média do treino teve RMSE 3,6782 — o menor de todos. Traduzindo: os modelos de regressão, quando confrontados com dados que nunca viram, **erraram mais que simplesmente dizer a média**.

**Segundo: R² negativo.** Um R² de −0,119 significa que o modelo é pior que o baseline de média. Quando R² é negativo, é isso que ele está te dizendo: "não use este modelo — use a média". Não é uma sutileza matemática; é um alerta.

**Terceiro: B levemente melhor que A no teste (RMSE 3,79 vs 3,83).** Mas ambos perdem do baseline. A diferença entre A e B é pequena demais para ser levada a sério — e a CV, veremos, vai inverter essa ordem.

### O que aprendemos

Em dados novos, **nossos modelos pioram a previsão em relação a não fazer nada**. Isso é um resultado sobre o poder preditivo real da escolaridade e da distorção neste recorte. Não é um defeito do método — é uma descoberta.

---

## Validação cruzada 5-fold (CV(5))

O treino/teste tem um problema de sorte: uma divisão particular pode ter sido fácil ou difícil. Se os 17 pontos do teste caíram em uma região "calma" dos dados, o modelo parece bom; se caíram em uma região caótica, parece péssimo. Isso é variância da avaliação.

A **validação cruzada k-fold** resolve isso da forma mais elegante possível: cada observação é testada uma vez.

O procedimento com k = 5:

1. Divida os 54 dados em 5 dobras de tamanho aproximadamente igual.
2. Para cada dobra j = 1, …, 5:
   - Treine o modelo nas outras 4 dobras.
   - Meça o erro na dobra j.
3. Tire a média dos 5 erros.

Assim, cada observação é treinada 4 vezes e testada 1 vez. É o mesmo dado, reaproveitado com honestidade.

### Resultado da CV(5)

| Candidato | RMSE_CV |
|---|---|
| Baseline | **3,8425** |
| A: simples | 3,8945 |
| B: múltiplo | 4,0319 |

De novo, o **baseline ganha**. A média de Y, calculada em cada fold de treino, tem o menor RMSE médio. Os dois modelos ficam atrás — o múltiplo bem atrás.

E aqui aparece uma informação que o treino/teste isolado não tinha dado:

    Dobras em que A venceu B: 1
    Dobras em que B venceu A: 4

Interessante. Na CV(5), B venceu em 4 das 5 dobras. Mas o **RMSE médio** de B é **pior** que o de A (4,03 vs 3,89). Como isso é possível?

Porque B venceu por pouco nas 4 dobras em que venceu, e perdeu feio na dobra em que perdeu. Quando a média é calculada, essa derrota feia puxa o RMSE médio de B para cima. É a diferença entre "quem ganha mais vezes" e "quem ganha com melhor margem média".

**Este é um dos aprendizados mais úteis da CV:** contar vitórias por dobra é uma métrica diferente de comparar RMSE médio. Nenhuma das duas é universalmente "certa" — depende do que você quer otimizar. Aqui, a média favorece A, a contagem favorece B. A escolha precisa ser justificada, não apenas declarada.

Uma referência útil: o desvio-padrão de Y é:

    sd(Y) = 3,8504

O RMSE_CV do baseline (3,8425) é essencialmente igual a sd(Y). Isso **não é coincidência** — se você prevê sempre a média, seu erro quadrático médio é, por definição, a variância. A CV apenas confirmou essa identidade matemática nos dados.

Já o RMSE_CV de A (3,8945) é ligeiramente **maior** que sd(Y). Ou seja, o modelo simples, avaliado honestamente pela CV, é pior que simplesmente dizer "a mortalidade média é 19,9 em todo município e ano". Esse é o veredito.

---

## O teste de volatilidade: 200 splits aleatórios

Uma última ferramenta antes das figuras. Vimos que a escolha específica dos 37/17 afeta o resultado. E se fizéssemos **200 divisões diferentes** e olhássemos a distribuição dos MSEs?

O script faz exatamente isso. O resultado é a **figura 3**, e o aprendizado é: o MSE de teste não é um número único — é uma **distribuição**. Dependendo de como você corta os dados, o modelo parece melhor ou pior. A CV foi inventada justamente para reduzir essa variabilidade.

---

## As três figuras

### Figura 1 — Treino vs. teste no plano

![Pontos de treino e teste com a reta ajustada no treino](https://raw.githubusercontent.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/main/estrutura/scriptsR/figuras/05-regressao-linear-treino-teste_img1.png)

Os pontos cinzas são as observações de treino. Os pontos laranjas são as de teste. A reta azul é a ajustada apenas no treino.

O que observar:

1. **A reta foi ajustada só nos cinzas.** Os laranjas estavam "escondidos" durante o ajuste. Olhar para eles depois é a única avaliação honesta.
2. **A reta é quase horizontal.** Reflete o β₁ = −8,82 com EP 10,33 do treino — não significativo.
3. **Os pontos laranjas estão espalhados por toda a faixa vertical.** Não há concentração em torno da reta. É o retrato visual do RMSE ≈ 3,83: o modelo erra muito em dados novos.

Se a reta capturasse alguma coisa real, esperaríamos que os pontos laranjas se alinhassem com ela. Não se alinham.

### Figura 2 — Previsto vs. real

![Dispersão previsto vs real para A e B, com linha identidade](https://raw.githubusercontent.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/main/estrutura/scriptsR/figuras/05-regressao-linear-treino-teste_img2.png)

Este é um dos gráficos mais úteis em avaliação de modelos. Cada ponto tem:

- Eixo X: valor **real** de mortalidade.
- Eixo Y: valor **previsto** pelo modelo.

A linha tracejada laranja é a **identidade** (y = x): se o modelo fosse perfeito, todos os pontos estariam exatamente sobre ela.

Dois modelos no gráfico:

- Pontos **azuis** (círculos): modelo A (simples).
- Pontos **roxos** (triângulos): modelo B (múltiplo).

O que observar:

1. **Nenhum dos modelos "abraça" a diagonal.** Os pontos estão espalhados em torno dela, sem correlação visível.
2. **A nuvem é praticamente vertical.** Isso é revelador: as previsões têm pouca variação (o modelo quase sempre chuta perto da média), mas os valores reais variam muito. Ou seja, o modelo **não acompanha a variação do alvo** — só devolve valores próximos da média.
3. **A e B produzem nuvens quase idênticas.** Consistente com o RMSE próximo (3,83 vs 3,79). Adicionar `distorcao_em` não mudou a forma da previsão — só deslocou um pouco para os lados.

Este gráfico, mais que qualquer outro, captura o problema. O modelo não é ruim porque tem viés alto — é ruim porque **não tem informação suficiente para se mover**. Ele responde à variação real do alvo com um quase-monotônico "não sei, chuto a média".

### Figura 3 — Volatilidade do MSE em 200 splits

![Histograma do MSE em 200 divisões treino/teste aleatórias](https://raw.githubusercontent.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/main/estrutura/scriptsR/figuras/05-regressao-linear-treino-teste_img3.png)

O histograma mostra a distribuição dos MSEs de teste ao longo de 200 divisões aleatórias. Três linhas verticais marcam referências:

- **Linha azul:** média dos MSEs de A nos 200 splits.
- **Linha roxa tracejada:** média dos MSEs de B nos 200 splits.
- **Linha laranja pontilhada:** o MSE da CV(5) de A (3,8945²).

O que observar:

1. **A distribuição é larga.** O MSE de teste varia consideravelmente de split para split — confirmando que uma única divisão treino/teste pode ser enganosa.
2. **A média dos 200 splits fica próxima do valor da CV(5).** Isso é um alívio: a CV(5) está fazendo um bom trabalho de resumir o "erro típico" do modelo, sem depender de uma única divisão.
3. **A linha roxa (B) está um pouco à direita da azul (A) na média.** Coerente com o RMSE_CV maior de B.
4. **Toda a distribuição está acima de sd(Y)² ≈ 14,82.** Ou seja, em **nenhum** dos 200 splits o modelo bateu o baseline de média. Isso é um veredito forte.

Se, em algum split, o modelo tivesse vencido o baseline por acaso, você veria barras à esquerda de sd(Y)² — mas como o baseline RMSE é 3,6782 (ao quadrado: ~13,53), e toda a nuvem está acima disso, sabemos: **o resultado não é sorte de uma divisão ruim. É o desempenho real do modelo.**

---

## Síntese: o que esta atividade ensina

Três conclusões para guardar.

**Primeira: o veredito é duro, mas honesto.** Os modelos de regressão linear não batem o baseline de média quando avaliados em dados novos. RMSE de A na CV: 3,89, contra 3,84 do baseline. Traduzindo: a escolaridade (e a distorção) não têm poder preditivo detectável sobre mortalidade 60–69 neste recorte.

**Segunda: vocabulário novo, agora sólido.** Aprendemos:

- **Treino/teste** — separação para avaliação honesta.
- **Validação cruzada k-fold** — reaproveitamento sistemático dos dados.
- **Baseline de média** — a régua mínima que todo modelo precisa superar.
- **Volatilidade do erro** — MSE é uma distribuição, não um número.

**Terceira: divergência entre critérios.** A CV mostrou que B venceu em 4 de 5 dobras, mas tem RMSE médio pior. Isso não é contradição — é lembrança de que "vantagem consistente" e "vantagem média" são medidas diferentes, e que o analista precisa declarar qual está usando.

O que fica desta atividade:

1. **Modelos A e B perdem do baseline** em treino/teste e em CV(5).
2. **RMSE de A na CV: 3,8945.** Baseline: 3,8425. sd(Y): 3,8504.
3. **R² negativo** no teste — sinal formal de que o modelo é pior que a média.
4. **Volatilidade alta entre splits** — uma única divisão treino/teste é insuficiente para julgar.
5. **Em 200 splits, nenhum bateu o baseline.** O resultado não é sorte ruim; é desempenho real.

Agora faz sentido perguntar: será que a **forma** do modelo é o problema? E se tentássemos algo que permita não-linearidades e interações? A atividade 06 muda a pergunta para classificação e testa em treino/teste também. E a atividade 08 vai trazer regularização, que é uma resposta técnica ao "modelos demais, sinal de menos".

---

## Documentos complementares

**Script que gera este consolidado:**
- 🧮 [`05-regressao-linear-treino-teste.R`](https://github.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/blob/main/estrutura/scriptsR/05-regressao-linear-treino-teste.R) — **a fonte** deste documento.

**Demais documentos relacionados:**
- 📋 [Relatório técnico do script (`05-regressao-linear-treino-teste.md`)](https://github.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/blob/main/estrutura/scriptsR/05-regressao-linear-treino-teste.md) — output bruto, sem a camada didática.
- 📎 [Consolidado 01 — Dicionário de variáveis](https://github.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/blob/main/consolidado/01-dicionario-variaveis.md).
- 📎 [Consolidado 02 — Análise exploratória](https://github.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/blob/main/consolidado/02-analise-exploratoria.md).
- 📎 [Consolidado 03 — Regressão linear](https://github.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/blob/main/consolidado/03-regressao-linear.md).
- 📎 [Consolidado 04 — Regressão logística](https://github.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/blob/main/consolidado/04-regressao-logistica.md).
- 📊 [Banco de dados (CSV)](https://github.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/blob/main/estrutura/bancoDeDados/df_ipdm_baixada_por_municipio.csv).
- 📄 [Dicionário de dados (PDF)](https://github.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/blob/main/estrutura/dicionario/dicionario_ipdm_baixada.pdf).