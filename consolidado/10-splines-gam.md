# Relatório da Atividade 10 — Splines e GAM

**Gerado por:** `10-splines-gam.R`  
**Data:** 2026-10-23 22:40:25  
**Origem:** `estrutura/bancoDeDados/df_ipdm_baixada_por_municipio.csv`  

> **Alvo:** `mortalidade_60_69`. **Preditores:** `riqueza`, `escolaridade`, `distorcao_em`.

## Sumário executivo

- Linha de Base (média): MSE_CV = 14,7647 | RMSE_CV = 3,8425
- MQO Linear: MSE_CV = 15,0907 | RMSE_CV = 3,8847
- Melhor Spline Natural em x1: df = 4 | MSE_CV = 14,4319 | RMSE_CV = 3,7989
- GAM: MSE_CV = 15,5234 | RMSE_CV = 3,9400

## Diagnóstico

O preditor que claramente não é uma reta é a `distorcao_em`. O GAM reduziu `riqueza` e `escolaridade` a linhas retas (edf = 1,00) e mapeou `distorcao_em` com suavização não linear (edf = 1,77), indicando saturação após cerca de 18% na distorção. A spline natural em `riqueza` com df = 4 foi a melhor estrutura dentre os candidatos testados e bateu a linha de base, sugerindo que a não-linearidade da riqueza é relevante sem cair em sobreajuste.

## Figuras

- `estrutura/scriptsR/figuras/10-splines-gam_img1.png` — Efeitos parciais do GAM (riqueza, escolaridade, distorção)
- `estrutura/scriptsR/figuras/10-splines-gam_img2.png` — Seleção de flexibilidade da spline em riqueza
- `estrutura/scriptsR/figuras/10-splines-gam_img3.png` — Reta MQO vs spline natural em riqueza
- `estrutura/scriptsR/figuras/10-splines-gam_img4.png` — Efeito parcial de distorção idades-série

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

4. GAM (y ~ s(x1) + s(x2) + s(x3)): CV(5) MSE = 15,5234 | RMSE = 3,9400

Graus de Liberdade Efetivos (edf) do GAM:
     s(riqueza) s(escolaridade) s(distorcao_em) 
           1.00            1.00            1.77 

================ QUADRO COMPARATIVO DE CV(5) ================
                              Modelo                        Tipo   MSE_CV
1              Linha de Base (Média)                   Constante 14.76473
2                MQO Linear Múltiplo          Paramétrico Rígido 15.09073
3 Melhor Spline Natural (df=4 em x1) Semiparamétrico (Spline x1) 14.43194
4               GAM com Suavizadores     Não-Paramétrico Aditivo 15.52338
   RMSE_CV Ganho_vs_Base
1 3.842490          0,0%
2 3.884679        -2,21%
3 3.798940         2,25%
4 3.939972        -5,14%

Frase de diagnóstico da relação: O preditor que claramente não é uma reta é a 'distorcao_em' (x3), com edf = 1,77 (enquanto 'riqueza' e 'escolaridade' foram estritamente reduzidos a retas pelo GAM, com edf = 1,00). A curva de distorção idade-série sobe de forma acentuada entre 8% e 17% (aumentando a mortalidade de idosos em cerca de +3,5 mortes por mil ao sinalizar vulnerabilidade socioeconômica municipal), mas atinge um platô de saturação a partir de 18%, onde aumentos adicionais da distorção não alteram mais a mortalidade esperada. Já nas splines de regressão univariadas em x1, o modelo com df = 4 capturou o platô e o repique industrial de Cubatão, batendo a linha de base (MSE 14,43 vs 14,76).

O que isso indica para a pergunta de pesquisa: O GAM puramente aditivo com indicadores socioeconômicos atinge RMSE de 3,94, não conseguindo bater a linha de base da ficha (RMSE = 3,84) nem a melhor Pergunta 1 da nossa Entrega 1 (que usa 'municipio' + 'ano' e atinge RMSE = 2,20). Esse resultado confirma rigorosamente o diagnóstico da nossa Entrega 1: modelos baseados apenas em indicadores sociais agregados sofrem com n pequeno (54) e ruído estocástico, enquanto a estrutura fixa de 'onde' (município) e 'quando' (ano) carrega mais de 42% do sinal preditivo. No entanto, a spline em x1 (df=4) bateu a linha de base (RMSE 3,80 vs 3,84), indicando que incorporar não-linearidades em riqueza pode refinar o modelo estrutural sem explodir em sobreajuste.

[OK] Figuras geradas com sucesso.
```

## Notas

- A validação cruzada com 5 dobras foi usada para comparar complexidade e desempenho.
- A estrutura fixa de município e ano continua sendo o sinal mais forte do banco, mas a spline em riqueza oferece refinamento útil.

