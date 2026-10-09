# Relatório da Atividade 08 — Regularização

**Gerado por:** `08-regularizacao.R`  
**Data:** 2026-10-08 21:10:15  
**Origem:** `../bancoDeDados/df_ipdm_baixada_por_municipio.csv`  

> **Alvo:** `mortalidade_60_69`. Predictores válidos (excluídos ipdm e longevidade).

## Sumário executivo

- n = 54 | p = 7 (com expansão polinomial)
- MQO: R² = 0.229 | R² aj = 0.1117

### CV-glmnet (λ.1se)
- Ridge: λ = 1500.2667
- ENet : λ = 3.0005
- Lasso: λ = 1.5003

### Sobreviventes
- Ridge: (Intercept), escolaridade, escolaridade2, distorcao_em, distorcao_x_esc, pib_per_capita, riqueza, ano
- Lasso: (Intercept)

## Figuras

- `figuras/08-regularizacao_img1.png` — Curva em U (Lasso)
- `figuras/08-regularizacao_img2.png` — Curva em U (Ridge)
- `figuras/08-regularizacao_img3.png` — Trilhas de coeficientes

## Output bruto

```

================ MQO DE REFERÊNCIA ================
R² = 0.229 | R² aj = 0.1117

================ CROSS-VALIDATION glmnet ================
              Modelo Lambda_min MSE_min Lambda_1se
1        Ridge (α=0)     5.6484 14.1445  1500.2667
2 ElasticNet (α=0.5)     1.2989 14.5705     3.0005
3        Lasso (α=1)     0.5392 14.1402     1.5003

================ COEFICIENTES (λ.1se) ================
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

Sobreviventes Ridge: (Intercept), escolaridade, escolaridade2, distorcao_em, distorcao_x_esc, pib_per_capita, riqueza, ano
Sobreviventes Lasso: (Intercept)

================ TESTE (RMSE) ================
                   Modelo   RMSE
1 Baseline (média treino) 3.6782
2                     MQO 3.6363
3             Ridge (1se) 3.6782
4             Lasso (1se) 3.6782

[OK] Figuras em: figuras
```

## Notas

Ridge encolhe sem zerar; Lasso zera e faz seleção.
Regra do 1 SE: preferir λ.1se (mais parcimonioso, perda dentro do ruído).

