# Relatório da Atividade 03 — Regressão Linear

**Gerado por:** `03-regressao-linear.R`  
**Data:** 2026-10-08 19:00:24  
**Origem:** `../bancoDeDados/df_ipdm_baixada_por_municipio.csv`  

> **Alvo:** `mortalidade_60_69` (mortes por mil hab., 60–69).

## Sumário executivo

- Simples: `mortalidade = 20.9266 + -2.0959 × escolaridade`
- R² = 0.0012 | RSE = 3.885
- IC 95% β1 (analítico) = [-19.2201; 15.0283]
- IC 95% β1 (bootstrap) = [-18.8741; 11.8109]
- Shapiro p = 0.00925
- Múltipla (+ distorcao_em): R² = 0.017 | R² aj = -0.0215
- Correlação escolaridade × distorção = -0.4531

## Figuras

- `figuras/03-regressao-linear_img1.png` — Dispersão + reta + resíduos
- `figuras/03-regressao-linear_img2.png` — Resíduos vs ajustados (simples)
- `figuras/03-regressao-linear_img3.png` — Viés-variância
- `figuras/03-regressao-linear_img4.png` — Bootstrap β1
- `figuras/03-regressao-linear_img5.png` — Simples vs múltipla
- `figuras/03-regressao-linear_img6.png` — Resíduos vs ajustados (múltipla)

## Output bruto

```

================ MODELO SIMPLES ================
             Estimate Std. Error t value  Pr(>|t|)    
(Intercept)   20.9266     4.1904  4.9940 7.034e-06 ***
escolaridade  -2.0959     8.5337 -0.2456     0.807    

Equação: mortalidade = 20.9266 + -2.0959 × escolaridade
IC 95%:
                 2.5 %   97.5 %
(Intercept)   12.51799 29.33515
escolaridade -19.22011 15.02830
R² = 0.0012 | R² aj = -0.018 | RSE = 3.885
Interpretação: cada +1 em escolaridade muda a mortalidade em -2.0959 mortes por mil hab. (sinal negativo — mais educação, menos mortalidade).

Previsões:
  escolaridade mortalidade_prev
1         0.35           20.193
2         0.45           19.983
3         0.55           19.774
4         0.65           19.564

Shapiro (simples): W = 0.9399 | p = 0.00925

================ BOOTSTRAP ================
β1 MQO: -2.0959
EP bootstrap: 7.9221
IC 95%: [-18.8741; 11.8109]

================ MODELO MÚLTIPLO ================
             Estimate Std. Error t value Pr(>|t|)  
(Intercept)  16.47350    6.45716  2.5512  0.01378 *
escolaridade  1.84722    9.58907  0.1926  0.84801  
distorcao_em  0.15466    0.17042  0.9075  0.36839  

================ SIMPLES vs MÚLTIPLA ================
                     Modelo     R2   R2_aj    RSE p
1    Simples (escolaridade) 0.0012 -0.0180 3.8850 1
2 Múltipla (+ distorcao_em) 0.0170 -0.0215 3.8916 2
Correlação escolaridade × distorcao_em: -0.4531
Shapiro (múltipla): W = 0.9213 | p = 0.00168

[OK] Figuras gravadas em: figuras
```

## Notas

Y está em mortes por mil habitantes. β1 negativo indica associação inversa
entre escolaridade e mortalidade adulta. A múltipla adiciona distorção
idade-série — ambos preditores educacionais, sem circularidade com o alvo.

