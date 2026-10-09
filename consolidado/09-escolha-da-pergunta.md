# Atividade 09 — Da exploração à pergunta

**Gerado por:** `09-escolha-da-pergunta.R` · **Data:** 2026-10-09 16:47 · **Banco:** IPDM, Baixada Santista (n = 54)

## 1. Duas perguntas candidatas

| Campo | Pergunta 1 | Pergunta 2 |
|---|---|---|
| 1. Pergunta | Quanto a mortalidade de 60 a 69 anos varia com *onde* (município) e *quando* (ano) — e quais municípios ficam acima do esperado para o seu ano? | Só com indicadores sociais, dá para antecipar quais município-anos terão mortalidade de 60 a 69 anos acima da mediana? |
| 2. Resposta Y | `mortalidade_60_69` · quantitativa contínua · mortes por mil hab. | `mortalidade_alta` (1 = acima da mediana do treino) · binária · sem unidade |
| 3. Preditores X | `municipio` (9 níveis) e `ano` como categoria (6 níveis) · p = 13 | `riqueza`, `escolaridade`, `distorcao_em` · p = 3 |
| 4. Tipo | supervisionado · regressão · **inferência** | supervisionado · classificação · **predição** |
| 5. Métrica | RMSE (mortes por mil hab.) em CV(5) | AUC e acurácia em CV(5) |
| 6. Linha de base | RMSE de prever sempre a média: 3,84 | AUC = 0,50; acurácia de chutar a classe majoritária: 42,4% |
| 7. Dono do problema | Secretarias de saúde da Baixada: decidir onde priorizar a atenção à população de 60 a 69 anos | Gestão regional de saúde: sinalizar risco com indicadores sociais já divulgados, sem esperar o dado de óbito |

## 2. Linha de base e modelo (validação cruzada, 5 dobras)

| Pergunta | Modelo | Linha de base | Modelo | Erro removido |
|---|---|---|---|---|
| P1 | `lm`: município + ano | RMSE 3,84 | RMSE **2,20** | 42,6% |
| P1 (teste extra) | `lm`: município + ano + 3 indicadores sociais | RMSE 3,84 | RMSE 2,44 | 36,4% |
| P2 | `glm`: riqueza + escolaridade + distorção | acurácia 42,4% | acurácia **64,4%** · AUC **0,68** | 38,2% |

“Erro removido” é a fração do erro da linha de base que o modelo elimina (RMSE na P1; taxa de erro na P2). É a régua comum entre as duas perguntas. As dobras são as mesmas nas duas; na P2 a mediana é recalculada dentro de cada dobra, sem olhar o teste.

## 3. Diagnóstico do banco (os quatro comandos)

- **Vazamento.** A maior correlação com Y é `longevidade` (0,49): longe de 1, sem alarme numérico. Mas o dicionário mostra que `longevidade` já contém a taxa de mortalidade de 60–69 e que o `ipdm` contém `longevidade` — o Y escondido em X, que a correlação não denuncia. Ficam **fora** das duas perguntas.
- **Tamanho.** n = 54. P1 tem p = 13 (n/p = 4,2): apertado, mas cada categoria aparece ao menos 6 vezes e o erro é medido fora da amostra (CV). P2 tem p = 3 (n/p = 18,0).
- **Balanço.** Classes 27 / 27: 50/50 por construção (mediana). A acurácia não engana, mas dicotomizar descarta informação; por isso a P2 também é avaliada por AUC.
- **Faltantes.** Nenhum: nada a imputar.
- **Dependência (extra).** Cada município aparece 6 vezes. Na CV aleatória, anos do mesmo município caem no treino e no teste, o que é otimista para a P2 (que quer generalizar para município novo).

## 4. Escolha

Escolhemos a **Pergunta 1**. Ela remove 42,6% do erro da linha de base (RMSE 2,20 contra 3,84), enquanto a Pergunta 2 remove 38,2% (acurácia 64,4%, AUC 0,68), e ainda de forma otimista (ver dependência acima).

**O que ela mostra.** Desvios da média geral (mortes por mil hab.): Mongaguá (+4,02) e Itanhaém (+2,36) ficam acima; Santos (-4,65) fica abaixo. O ano de maior mortalidade é 2022 (+4,75) e o de menor é 2024 (-3,48). Somar os três indicadores sociais a município e ano leva o RMSE de 2,20 para 2,44 (piora: excesso de parâmetros para n tão pequeno).

**Correção de rota.** As Atividades 03–08 nunca usaram `municipio` e, quando usaram `ano`, foi como número (Atividade 08). Tratar os dois como categorias é o que muda o quadro em relação à conclusão de que a mortalidade seria “imprevisível”.

**Limites.** Em dado observacional, os efeitos são associação, não causa: o pico de mortalidade coincide com o período da pandemia de COVID-19, mas os dados não provam causa. A P1 descreve e interpola os 9 municípios e 6 anos observados; como `ano` é categoria, ela não projeta anos futuros.

## 5. O que as próximas aulas podem mudar

Árvores e ensembles (Aulas 11–12) e regularização podem melhorar a P2 e permitir testar interações município × ano; a pergunta volta para revisão depois da Aula 12.

