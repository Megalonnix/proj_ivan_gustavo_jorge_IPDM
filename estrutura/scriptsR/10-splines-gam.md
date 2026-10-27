# Relatório Técnico da Atividade 10 — Splines e GAM

**Gerado por:** `10-splines-gam.R`  
**Data:** 2026-10-27 11:39:52  
**Origem:** `estrutura/bancoDeDados/df_ipdm_baixada_por_municipio.csv`  

> **Alvo:** `mortalidade_60_69`. **Preditores socioeconômicos:** `riqueza`, `escolaridade`, `distorcao_em`. **Controle estrutural:** `municipio`, `ano`.

## Sumário executivo

- Linha de Base (média): MSE_CV = 14,7647 | RMSE_CV = 3,8425
- MQO Linear (x1+x2+x3): MSE_CV = 15,0907 | RMSE_CV = 3,8847
- Melhor Spline Natural em x1: df = 4 | MSE_CV = 14,4319 | RMSE_CV = 3,7989
- GAM Socioeconômico: MSE_CV = 15,5234 | RMSE_CV = 3,9400
- GAM Semiparamétrico (municipio + s(ano) + s(riqueza)): MSE_CV = 5,5315 | RMSE_CV = 2,3519

## Output bruto

```
=============================================================
LABORATÓRIO AULA 10: SPLINES E GAM NO BANCO IPDM BAIXADA SANTISTA
Resposta (y): mortalidade_60_69 | Preditores: riqueza (x1), escolaridade (x2), distorcao_em (x3)
n = 54 observações em 5 dobras de validação cruzada
=============================================================
1. Linha de Base (Média): CV(5) MSE = 14,7647 | RMSE = 3,8425
2. MQO Linear (y ~ x1 + x2 + x3): CV(5) MSE = 15,0907 | RMSE = 3,8847

3. Spline Natural em x1 (Riqueza) com df = 2:8:
     df  MSE_CV RMSE_CV
df=2  2 16.1033  4.0129
df=3  3 14.5393  3.8130
df=4  4 14.4319  3.7989
df=5  5 15.6281  3.9532
df=6  6 15.6916  3.9613
df=7  7 17.4376  4.1758
df=8  8 18.4365  4.2938
Melhor Spline Natural em x1: df = 4 (MSE = 14,4319, RMSE = 3,7989)

4. GAM Socioeconômico (y ~ s(x1) + s(x2) + s(x3)): CV(5) MSE = 15,5234 | RMSE = 3,9400

Graus de Liberdade Efetivos (edf) do GAM Socioeconômico:
     s(riqueza) s(escolaridade) s(distorcao_em) 
           1.00            1.00            1.77 

5. GAM Semiparamétrico Estrutural (y ~ municipio + s(ano, k=5) + s(riqueza, k=4)):
   CV(5) MSE = 5,5315 | RMSE = 2,3519
   edf s(ano) = 3,91 | edf s(riqueza) = 1,00

================ QUADRO COMPARATIVO DE CV(5) ================
                                            Modelo                        Tipo
1                            Linha de Base (Média)                   Constante
2                   MQO Linear Múltiplo (x1+x2+x3)          Paramétrico Rígido
3               Melhor Spline Natural (df=4 em x1) Semiparamétrico (Spline x1)
4           GAM Socioeconômico (s(x1)+s(x2)+s(x3))     Não-Paramétrico Aditivo
5 GAM Semiparamétrico (municipio + s(ano) + s(x1)) Aditivo Estrutural (Painel)
   MSE_CV RMSE_CV Ganho_MSE_vs_Base
1 14.7647  3.8425              0,0%
2 15.0907  3.8847            -2,21%
3 14.4319  3.7989             2,25%
4 15.5234  3.9400            -5,14%
5  5.5315  2.3519            62,54%

Frase de diagnóstico da relação: No bloco socioeconômico puro, o preditor que claramente não é uma reta é a 'distorcao_em' (x3), com edf = 1,77 (enquanto 'riqueza' e 'escolaridade' foram reduzidos a retas pelo GAM penalizado, com edf = 1,00). A curva de distorção idade-série sobe de forma acentuada entre 8% e 17% (aumentando a mortalidade de idosos em cerca de +3,5 mortes por mil ao sinalizar vulnerabilidade socioeconômica municipal), mas atinge um platô de saturação a partir de 18%. Já nas splines naturais em x1 (riqueza), o modelo com df = 4 capturou o platô e o repique industrial de Cubatão, batendo a linha de base (MSE 14,43 vs 14,76). Por fim, ao unir o GAM à estrutura da nossa Pergunta 1 (municipio + s(ano, k=5) + s(riqueza, k=4)), o suavizador temporal captura o pico não-linear da pandemia (edf = 3,91) e reduz o MSE de validação cruzada de 14,76 para 5,53 (RMSE = 2,35).

[OK] Figuras geradas com sucesso.
```

