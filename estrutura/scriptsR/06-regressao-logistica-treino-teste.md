# Relatório da Atividade 06 — Classificação

**Gerado por:** `06-regressao-logistica-treino-teste.R`  
**Data:** 2026-10-08 19:02:10  
**Origem:** `../bancoDeDados/df_ipdm_baixada_por_municipio.csv`  

> **Alvo:** `mortalidade_alta` = 1 se mortalidade > mediana do TREINO.

## Sumário

- n_treino = 37 | n_teste = 17
- Mediana (treino) = 19.5337
- A: Acc = 0.2353 | AUC = 0.2639
- B: Acc = 0.5294 | AUC = 0.5556
- CV(5): Acc_A = 48.18% (AUC 0.5129) | Acc_B = 59.27% (AUC 0.6786)
- **Vencedor: B: múltiplo**

## Figuras

- `figuras/06-regressao-logistica-treino-teste_img1.png` — Curva logística + teste
- `figuras/06-regressao-logistica-treino-teste_img2.png` — ROC (A vs B)

## Output bruto

```

================ BINARIZAÇÃO ================
Mediana (treino): 19.5337
Prop. classe 1 treino: 0.486
Prop. classe 1 teste:  0.471

--- A: simples ---
             Estimate Std. Error z value Pr(>|z|)
(Intercept)    1.0216     2.5883  0.3947   0.6931
escolaridade  -2.2021     5.2559 -0.4190   0.6752
--- B: múltiplo ---
             Estimate Std. Error z value Pr(>|z|)
(Intercept)   -4.2198     4.2610 -0.9903   0.3220
escolaridade   2.3661     6.0521  0.3909   0.6958
distorcao_em   0.1788     0.1180  1.5149   0.1298

================ TESTE (limiar 0.5) ================
--- A ---
    prev
real 0 1
   0 4 5
   1 8 0
Acc: 0.2353 | Sens: 0 | Esp: 0.4444 | AUC: 0.2639
--- B ---
    prev
real 0 1
   0 7 2
   1 6 2
Acc: 0.5294 | Sens: 0.25 | Esp: 0.7778 | AUC: 0.5556

Matrizes nos limiares 0.3/0.5/0.7:

--- limiar 0.3 ---
A:
    previsto
real 1
   0 9
   1 8
B:
    previsto
real 0 1
   0 2 7
   1 1 7

--- limiar 0.5 ---
A:
    previsto
real 0 1
   0 4 5
   1 8 0
B:
    previsto
real 0 1
   0 7 2
   1 6 2

--- limiar 0.7 ---
A:
    previsto
real 0
   0 9
   1 8
B:
    previsto
real 0
   0 9
   1 8

================ CV(5) ================
    Candidato Acc_pct    AUC
1    Baseline   42.36     NA
2  A: simples   48.18 0.5129
3 B: múltiplo   59.27 0.6786
Dobras A venceu (AUC): 0 | B venceu: 4

[OK] Figuras em: figuras
```

## Notas

Mediana recalculada por dobra. Classes ~50/50 por construção.
AUC independente de limiar; melhor critério para escolher entre A e B.

