# Atividade 09 — Da exploração à pergunta

**Gerado por:** `09-escolha-da-pergunta.R` · **Data:** 2026-10-27 11:39 · **Banco:** IPDM, Baixada Santista (n = 54)

## 1. Duas perguntas candidatas

| Campo | Pergunta 1 (escolhida) | Pergunta 2 (concorrente) |
|---|---|---|
| 1. Pergunta | Quanto a mortalidade de 60 a 69 anos varia com *onde* (município) e *quando* (ano) — e quais municípios ficam acima do esperado para o seu ano? | Só com indicadores sociais, dá para antecipar quais município-anos terão mortalidade de 60 a 69 anos acima da mediana? |
| 2. Resposta Y | `mortalidade_60_69` · quantitativa contínua · mortes por mil hab. | `mortalidade_alta` (1 = acima da mediana do treino) · binária · sem unidade |
| 3. Preditores X | `municipio` (9 níveis) e `ano` como categoria (6 níveis) · p = 13 | `riqueza`, `escolaridade`, `distorcao_em` · p = 3 |
| 4. Tipo | supervisionado · regressão · **inferência** | supervisionado · classificação · **predição** |
| 5. Métrica | RMSE e MAE (mortes por mil hab.) em CV(5) | AUC e acurácia em CV(5) |
| 6. Linha de base | RMSE de prever sempre a média do treino: 3,84 (MAE = 2,97) | AUC = 0,50; acurácia da classe majoritária: 42,4% |
| 7. Dono do problema | Secretarias de saúde da Baixada: decidir onde priorizar a atenção à população de 60 a 69 anos | Gestão regional de saúde: sinalizar risco com indicadores sociais já divulgados, sem esperar o dado de óbito |

## 2. Linha de base e modelo (validação cruzada, 5 dobras)

| Pergunta | Modelo | Linha de base | Modelo (média ± dp) | Métrica de apoio | Erro removido |
|---|---|---|---|---|---|
| P1 | `lm`: município + ano | RMSE 3,84 | RMSE **2,20** (±0,25) | MAE **1,71** | **42,6%** |
| P1 (teste extra) | `lm`: município + ano + 3 indicadores sociais | RMSE 3,84 | RMSE 2,44 (±0,44) | MAE 1,88 | 36,4% |
| P2 | `glm`: riqueza + escolaridade + distorção | AUC 0,50 · Acc 42,4% | AUC **0,68** (±0,21) | Acc **64,4%** | 38,2% |
| P1 → P2 (dominância) | `lm` da P1 cortado na mediana do treino | AUC 0,50 · Acc 42,4% | AUC **0,89** (±0,11) | Acc **86,7%** | **77,0%** |

“Erro removido” é a fração do erro da linha de base que o modelo elimina (RMSE na P1; taxa de erro de classificação na P2). Além disso, a última linha testa a **dominância direta** na mesma régua (AUC e acurácia): ao dicotomizar a predição contínua da P1 pela mediana do treino de cada dobra, obtemos AUC = 
0,89 e acurácia = 86,7%, superando com folga o próprio `glm` da P2 (AUC = 0,68). Ou seja, a P1 resolve também a P2 com qualidade superior, enquanto um rótulo binário não devolve taxas de mortalidade.

## 3. Diagnóstico do banco (os quatro comandos)

- **Vazamento.** A maior correlação com Y é `longevidade` (0,49): longe de 1, sem alarme numérico. Mas o dicionário mostra que `longevidade` já contém a taxa de mortalidade de 60–69 e que o `ipdm` contém `longevidade` — o Y escondido em X, que a correlação não denuncia. Ficam **fora** das duas perguntas.
- **Tamanho.** n = 54. P1 tem p = 13 dummies (n/p = 4,2): apertado, mas o painel é perfeitamente balanceado — cada categoria aparece ao menos 6 vezes e o erro é medido fora da amostra (CV). P2 tem p = 3 (n/p = 18,0).
- **Balanço.** Classes 27 / 27: 50/50 por construção na base cheia (mediana), mas nas dobras de teste o chute na maioria do treino acerta só 42,4%. Dicotomizar descarta a magnitude do óbito; por isso a P2 também é avaliada por AUC.
- **Faltantes.** Nenhum: nada a imputar.
- **Dependência (extra).** Cada município aparece 6 vezes (painel longitudinal). Na CV aleatória, anos do mesmo município caem no treino e no teste, o que é otimista para a P2 (que quer generalizar para município novo).

## 4. Escolha

Escolhemos a **Pergunta 1**. Ela remove **42,6%** do erro da linha de base (RMSE **2,20** contra 3,84; MAE 1,71 contra 2,97), e mesmo quando cortada na mediana para responder à Pergunta 2 atinge **AUC = 0,89** (acurácia de **86,7%**), superando o próprio modelo logístico da Pergunta 2 (AUC = 0,68, acurácia = 64,4%).

**O que ela mostra.** Desvios da média geral (19,91 mortes por mil hab.): Mongaguá (+4,02) e Itanhaém (+2,36) ficam estruturalmente acima; Santos (-4,65) fica abaixo. No eixo temporal, o ano de maior mortalidade é 2022 (+4,75, choque pandêmico) e o de menor é 2024 (-3,48). Somar os três indicadores sociais a município e ano leva o RMSE de 2,20 para 2,44 (piora por variância: excesso de parâmetros colineares com o efeito fixo de município para n = 54).

**Correção de rota.** As Atividades 03–08 nunca usaram `municipio` e, quando usaram `ano`, foi como reta contínua (Atividade 08). Tratar os dois como categorias (efeitos fixos aditivos de painel) muda completamente o quadro em relação à conclusão preliminar de que a mortalidade seria “imprevisível”.

**Limites.** Em dado observacional, os efeitos medem associação estrutural, não causa direta: o pico de mortalidade em 2020–2022 reflete o choque da COVID-19, mas o modelo não isola mecanismos biológicos. A P1 descreve e decompõe os 9 municípios e 6 anos observados; como `ano` entra como fator, ela não extrapola anos futuros sem hipótese paramétrica adicional.

## 5. O que as próximas aulas podem mudar

Suavizadores não-paramétricos (Aulas 09–10: Kernel, Splines e GAM) permitem modelar a trajetória não-linear de `ano` e `riqueza` sem gastar tantos graus de liberdade, enquanto árvores e ensembles (Aulas 11–12) permitem testar interações município × ano; a pergunta volta para revisão depois da Aula 12.

