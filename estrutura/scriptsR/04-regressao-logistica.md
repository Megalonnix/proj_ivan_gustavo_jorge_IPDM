# Relatório da Atividade 04 — Regressão Logística

**Gerado por:** `04-regressao-logistica.R`  
**Data:** 2026-10-08 19:01:02  
**Origem:** `../bancoDeDados/df_ipdm_baixada_por_municipio.csv`  

> **Alvo binário:** `mortalidade_alta` = 1 se mortalidade_60_69 > mediana.

## Sumário

- Mediana = 19.3986
- logit(p) = -1.7776 + 3.6486 × escolaridade
- exp(β1) = 38.4221
- x* (p = 0.5) = 0.487
- Acurácia (0.5) = 0.537 | AUC = 0.56
- Youden = 0.477

## Figuras

- `figuras/04-regressao-logistica_img1.png` — Curva sigmoide
- `figuras/04-regressao-logistica_img2.png` — ROC

## Output bruto

```

================ MODELO LOGÍSTICO ================
             Estimate Std. Error z value Pr(>|z|)
(Intercept)   -1.7776     2.1935 -0.8104   0.4177
escolaridade   3.6486     4.4655  0.8171   0.4139
Equação (logit): -1.7776 + 3.6486 × escolaridade
Razão de chances exp(β1) = 38.4221
Interpretação: cada +1 em escolaridade multiplica a chance demortalidade alta por 38.4221.

Tabela logit/odds/p:
  escolaridade  logit  odds     p
1          0.4 -0.318 0.727 0.421
2          0.5  0.047 1.048 0.512
3          0.6  0.412 1.509 0.601
Fronteira de decisão (p = 0.5): x* = 0.487

Matriz de confusão (0.5):
    previsto
real  0  1
   0 14 13
   1 12 15
Acurácia: 0.537
Precisão: 0.536
Recall:   0.556
Espec.:   0.519

Matrizes nos limiares 0.3 / 0.5 / 0.7:

--- limiar 0.3 ---
    previsto
real  1
   0 27
   1 27

--- limiar 0.5 ---
    previsto
real  0  1
   0 14 13
   1 12 15

--- limiar 0.7 ---
    previsto
real  0
   0 27
   1 27

AUC: 0.56

Youden — limiar: 0.477 | TPR: 0.815 | FPR: 0.63
    previsto
real  0  1
   0 10 17
   1  8 19

[OK] Figuras gravadas em: figuras
```

## Notas

exp(β1) > 1 indica que escolaridade AUMENTA a chance de mortalidade alta;
exp(β1) < 1 indica que escolaridade PROTEGE (reduz a chance).
O sinal esperado substantivamente é de proteção (exp(β1) < 1).

