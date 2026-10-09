# Relatório da Atividade 02 — Diagnóstico, Baseline e EDA

**Gerado por:** `02-analise-exploratoria.R`  
**Data:** 2026-10-08 21:09:22  
**Origem:** `../bancoDeDados/df_ipdm_baixada_por_municipio.csv`  

> **Alvo:** `mortalidade_60_69` (mortes por mil hab. na faixa 60–69).

## Sumário executivo

- n = 54 | p_válidos = 9 | n/p = 6
- Mediana do alvo = 19.3986
- Baseline regressão (sd Y) = 3.8504
- Baseline classificação = 50 %

## Preditores

Válidos: `escolaridade`, `distorcao_em`, `pib_per_capita`, `riqueza`, `ano`.
Excluídos por circularidade: `longevidade`, `ipdm`.

## Figuras geradas

- `figuras/02-analise-exploratoria_img1.png` — Histograma do alvo + Normal teórica
- `figuras/02-analise-exploratoria_img2.png` — Boxplot do alvo por município
- `figuras/02-analise-exploratoria_img3.png` — Dispersão Escolaridade × Mortalidade

## Output bruto

```
================ PROTOCOLO DE DIAGNÓSTICO ================

--- Passo 1: Correlações com mortalidade_60_69 ---
mortalidade_60_69  mortalidade_alta       longevidade              ipdm           riqueza    pib_per_capita 
           1.0000            0.7649            0.4901            0.3977            0.3933            0.2494 
     distorcao_em               ano      escolaridade 
           0.1277            0.0847            0.0340 
Leitura: longevidade e ipdm aparecem como altamente correlacionados —
por isso são EXCLUÍDOS como preditores (circularidade conceitual).
Preditores válidos: escolaridade, distorcao_em, pib_per_capita, riqueza.

--- Passo 2: n vs p ---
n = 54 | p_válidos = 9 | n/p = 6
Diagnóstico: n/p < 10 ⇒ parcimônia ou regularização.

--- Passo 3: Balanço (mortalidade_alta) ---

 0  1 
27 27 

  0   1 
0.5 0.5 

--- Passo 4: NAs ---
         cod_ibge         municipio               ano           riqueza       longevidade      escolaridade 
                0                 0                 0                 0                 0                 0 
             ipdm mortalidade_60_69      distorcao_em    pib_per_capita  mortalidade_alta 
                0                 0                 0                 0                 0 

================ BASELINES ================
Baseline regressão (RMSE = sd(Y)): 3.8504
Baseline classificação: 50 %
Unidade de Y: mortes por mil habitantes na faixa 60–69.

================ RESUMO NUMÉRICO ================
      ano          riqueza        longevidade      escolaridade         ipdm        mortalidade_60_69  distorcao_em  
 Min.   :2014   Min.   :0.3210   Min.   :0.5600   Min.   :0.3340   Min.   :0.4423   Min.   :13.94     Min.   : 8.20  
 1st Qu.:2016   1st Qu.:0.3782   1st Qu.:0.6200   1st Qu.:0.4580   1st Qu.:0.4953   1st Qu.:17.19     1st Qu.:14.10  
 Median :2019   Median :0.4150   Median :0.6435   Median :0.4905   Median :0.5167   Median :19.40     Median :16.48  
 Mean   :2019   Mean   :0.4325   Mean   :0.6477   Mean   :0.4871   Mean   :0.5224   Mean   :19.91     Mean   :16.37  
 3rd Qu.:2022   3rd Qu.:0.4988   3rd Qu.:0.6697   3rd Qu.:0.5363   3rd Qu.:0.5548   3rd Qu.:22.07     3rd Qu.:18.20  
 Max.   :2024   Max.   :0.5750   Max.   :0.7560   Max.   :0.6020   Max.   :0.6040   Max.   :33.00     Max.   :26.80  
 pib_per_capita   mortalidade_alta
 Min.   : 20064   Min.   :0.0     
 1st Qu.: 30885   1st Qu.:0.0     
 Median : 37397   Median :0.5     
 Mean   : 59246   Mean   :0.5     
 3rd Qu.: 46298   3rd Qu.:1.0     
 Max.   :270119   Max.   :1.0     

[OK] Figuras gravadas em: figuras
```

## Notas

Baseline de regressão = sd(Y). Se RMSE_CV < sd(Y), o modelo tem sinal real.
Como o alvo é binarizado pela mediana, o baseline de classificação é ~50%.

