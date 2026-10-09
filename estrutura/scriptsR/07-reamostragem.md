# Relatório da Atividade 07 — Reamostragem

**Gerado por:** `07-reamostragem.R`  
**Data:** 2026-10-08 21:10:07  
**Origem:** `../bancoDeDados/df_ipdm_baixada_por_municipio.csv`  

> **Alvo:** `mortalidade_60_69`. Predictor: `escolaridade`.

## Sumário executivo

### CV(5) — candidatos polinomiais
- Grau 1:  RMSE_CV = 3.8945
- Grau 3:  RMSE_CV = 3.942
- Grau 12: RMSE_CV = 239.9973
- Baseline (sd Y) = 3.8504

### Bootstrap β1
- β1 MQO = -2.0959
- EP analítico = 8.5337 | EP bootstrap = 7.9221
- IC 95% analítico = [-19.2201; 15.0283]
- IC 95% bootstrap = [-18.8741; 11.8109]
- 0 dentro do IC bootstrap? SIM

## Figuras

- `figuras/07-reamostragem_img1.png` — Volatilidade: splits avulsos vs CV(5)
- `figuras/07-reamostragem_img2.png` — Distribuição bootstrap de β1

## Output bruto

```

================ CV(5) — GRAUS 1, 3, 12 ================
        Candidato  RMSE_CV
grau_1     grau_1   3.8945
grau_3     grau_3   3.9420
grau_12   grau_12 239.9973
sd(Y) = 3.8504

--- Erro por dobra ---
  Dobra grau_1 grau_3  grau_12
1     1 2.9083 2.9805   3.1015
2     2 3.9910 4.0575  16.7908
3     3 4.4839 4.4775   4.0139
4     4 4.8409 4.7836   5.2158
5     5 2.8124 3.0694 536.3383

================ BOOTSTRAP β1 ================
β1 MQO:       -2.0959
EP analítico: 8.5337
EP bootstrap: 7.9221
IC 95% analítico: [-19.2201; 15.0283]
IC 95% bootstrap: [-18.8741; 11.8109]
0 dentro do IC bootstrap? SIM

[OK] Figuras em: figuras
```

## Notas

CV(5) reaproveita cada observação (treinada 4×, testada 1×).
Bootstrap não-paramétrico, B = 2000, sem hipótese de normalidade.

