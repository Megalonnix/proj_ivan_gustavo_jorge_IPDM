# Relatório Técnico da Atividade 08 — Regularização

**Gerado por:** `08-regularizacao.R`  
**Data:** 2026-10-27 11:39:50  
**Origem:** `estrutura/bancoDeDados/df_ipdm_baixada_por_municipio.csv`  

> **Alvo:** `mortalidade_60_69`. Preditores válidos (excluídos ipdm e longevidade).

## Sumário executivo

- Parte A (Socioeconômica): n = 54 | p = 7 | MQO R² = 0.229 (R² aj = 0.1117)
- Parte B (Expansão Completa com model.matrix): n = 54 | p = 19 | Lasso MSE_CV (min) = 5.423 (RMSE = 2.3287)

## Figuras

- `estrutura/scriptsR/figuras/08-regularizacao_img1.png` — Curva em U (Lasso)
- `estrutura/scriptsR/figuras/08-regularizacao_img2.png` — Curva em U (Ridge)
- `estrutura/scriptsR/figuras/08-regularizacao_img3.png` — Trilhas de coeficientes

## Output bruto

```

================ PARTE A: BLOCO SOCIOECONÔMICO (p = 7) ================
MQO R² = 0.229 | R² aj = 0.1117
Correlação entre escolaridade e escolaridade² (colinearidade polinomial): 0.9969

================ CROSS-VALIDATION glmnet (p = 7) ================
                  Modelo Lambda_min MSE_min Lambda_1se
1        Ridge (alpha=0)     5.6484 14.1445  1500.2667
2 ElasticNet (alpha=0.5)     1.2989 14.5705     3.0005
3        Lasso (alpha=1)     0.5392 14.1402     1.5003

--- Regra de 1 erro-padrão no Lasso (p = 7) ---
    CV_min     EP_min Limiar_1SE     CV_1se 
   14.1402     3.0340    17.1742    15.5278 

================ COEFICIENTES (lambda.1se, p = 7) ================
--- Ridge ---
                lambda.1se
(Intercept)        19.9056
escolaridade        0.0000
escolaridade2       0.0000
distorcao_em        0.0000
distorcao_x_esc     0.0000
pib_per_capita      0.0000
riqueza             0.0000
ano                 0.0000

--- Lasso ---
                lambda.1se
(Intercept)        19.9056
escolaridade        0.0000
escolaridade2       0.0000
distorcao_em        0.0000
distorcao_x_esc     0.0000
pib_per_capita      0.0000
riqueza             0.0000
ano                 0.0000

Sobreviventes Ridge (p=7): (Intercept), escolaridade, escolaridade2, distorcao_em, distorcao_x_esc, pib_per_capita, riqueza, ano
Sobreviventes Lasso (p=7): (Intercept)

================ TESTE 70/30 (RMSE, p = 7) ================
                   Modelo   RMSE
1 Baseline (média treino) 3.6782
2                     MQO 3.6363
3             Ridge (1se) 3.6782
4             Lasso (1se) 3.6782

================ PARTE B: EXPANSÃO COMPLETA (model.matrix, p = 19) ================
             Metodo Lambda_min MSE_CV_min RMSE_CV_min Lambda_1se MSE_CV_1se
1      Ridge (p=19)     0.9417     5.1278      2.2645     3.8017     6.5572
2 ElasticNet (p=19)     0.2608     4.7591      2.1815     0.7258     5.7344
3      Lasso (p=19)     0.1431     5.4230      2.3287     0.3629     6.1450

--- Sobreviventes do Lasso na Expansão Completa (lambda.min) ---
14 x 1 sparse Matrix of class "dgCMatrix"
                     lambda.min
(Intercept)             22.3511
municipioGuarujá        -0.2980
municipioItanhaém        1.5659
municipioMongaguá        3.0949
municipioPeruíbe         0.5012
municipioSantos         -3.7383
municipioSão Vicente    -0.7343
ano_f2016               -0.2190
ano_f2020                1.5656
ano_f2022                4.9767
ano_f2024               -2.7526
riqueza                 -8.2327
escolaridade2            2.1439
pib_per_capita           0.0000

--- Sobreviventes do Lasso na Expansão Completa (lambda.1se) ---
9 x 1 sparse Matrix of class "dgCMatrix"
                     lambda.1se
(Intercept)             22.1529
municipioItanhaém        1.1318
municipioMongaguá        2.5484
municipioSantos         -3.1161
municipioSão Vicente    -0.0772
ano_f2020                1.1428
ano_f2022                4.4663
ano_f2024               -2.2226
riqueza                 -6.6260

[OK] Figuras em: estrutura/scriptsR/figuras
```

