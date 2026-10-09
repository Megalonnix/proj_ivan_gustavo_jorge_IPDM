# Relatório da Atividade 05 — Treino/Teste e CV(5)

**Gerado por:** `05-regressao-linear-treino-teste.R`  
**Data:** 2026-10-08 21:09:51  
**Origem:** `../bancoDeDados/df_ipdm_baixada_por_municipio.csv`  

> **Alvo:** `mortalidade_60_69`. Unidade: mortes por mil hab.

## Sumário executivo

- n_treino = 37 | n_teste = 17
- A (simples)  RMSE_teste = 3.8314
- B (múltiplo) RMSE_teste = 3.7887
- A CV(5) = 3.8945 | B CV(5) = 4.0319
- **Vencedor: A: simples**
- sd(Y) = 3.8504

## Figuras

- `figuras/05-regressao-linear-treino-teste_img1.png` — Treino + teste
- `figuras/05-regressao-linear-treino-teste_img2.png` — Previsto vs Real (A vs B)
- `figuras/05-regressao-linear-treino-teste_img3.png` — Volatilidade do MSE

## Output bruto

```

================ MODELOS (TREINO) ================
--- A: simples ---
             Estimate Std. Error t value Pr(>|t|)
(Intercept)   24.0136     5.0905  4.7174   0.0000
escolaridade  -8.8190    10.3339 -0.8534   0.3992
--- B: múltiplo ---
             Estimate Std. Error t value Pr(>|t|)
(Intercept)   20.4344     8.0746  2.5307   0.0162
escolaridade  -5.6044    11.8388 -0.4734   0.6390
distorcao_em   0.1191     0.2072  0.5747   0.5692

================ TESTE (n = 17) ================
    Candidato   RMSE    MAE      R2
1    Baseline 3.6782 2.9734      NA
2  A: simples 3.8314 3.1914 -0.1187
3 B: múltiplo 3.7887 3.0999 -0.0939

================ CV(5) ================
    Candidato RMSE_CV
1    Baseline  3.8425
2  A: simples  3.8945
3 B: múltiplo  4.0319
sd(Y) = 3.8504
Dobras A venceu: 1 | B venceu: 4

[OK] Figuras em: figuras
```

## Notas

RMSE em mortes por mil hab. A média de referência do baseline é a do TREINO.

