# Relatório da Atividade 09 — Métodos de Suavização

**Gerado por:** `09-metodos-suavizacao.R`  
**Data:** 2026-10-23 22:29:38  
**Origem:** `../bancoDeDados/df_ipdm_baixada_por_municipio.csv`  

> **Alvo:** `mortalidade_60_69`. **Preditor principal:** `riqueza`.

## Sumário executivo

- Melhor KNN: k = 20 | MSE_CV = 12.5767
- Melhor Kernel: h = 0.007 | MSE_CV = 12.4573
- Reta MQO: MSE_CV = 13.4295 | RMSE_CV = 3.6646

## Diagnóstico da relação

> A relação entre Riqueza e Mortalidade 60-69 anos NÃO é puramente uma reta. Ela apresenta um patamar elevado de mortalidade em municípios com índice de riqueza entre 0,35 e 0,42 (Itanhaém, Mongaguá e Peruíbe com taxas atingindo 23 a 32 por mil), uma queda acentuada em cidades de alta renda (Santos com mortalidade abaixo de 15 por mil), mas um repique não-linear intermediário em Cubatão (onde a riqueza é alta, ~0,51, mas a mortalidade chega a 21 por mil devido ao polo industrial). Por capturar esses patamares e inflexões locais sem forçar uma inclinação constante, o Kernel com h = 0,0070 supera o MQO com menor MSE de validação cruzada (12,46 vs 13,43).

## Figuras

- `figuras/09-metodos-suavizacao_img1.png` — Ajuste real: reta, KNN e kernel ótimo
- `figuras/09-metodos-suavizacao_img2.png` — Curvas em U de validação (KNN e Kernel)
- `figuras/09-metodos-suavizacao_img3.png` — Estrutura local da relação
- `figuras/09-metodos-suavizacao_img4.png` — Dinâmica temporal e choque da pandemia

## Output bruto

```
=============================================================
RESULTADOS DA VALIDAÇÃO CRUZADA (5 DOBRAS)
Y: mortalidade_60_69 | X: riqueza
               Modelo  MSE_CV RMSE_CV Ganho_vs_Reta
1            Reta MQO 13.4295  3.6646          0.0%
2          KNN (k=20) 12.5767  3.5464         6.35%
3 Kernel NW (h=0.007) 12.4573  3.5295         7.24%

[OK] Figuras geradas em: figuras
```

## Notas

- O kernel gaussiano captura a suavidade da relação local sem impor uma fórmula rígida.
- A validação cruzada com 5 dobras foi usada para escolher o nível de flexibilidade.

