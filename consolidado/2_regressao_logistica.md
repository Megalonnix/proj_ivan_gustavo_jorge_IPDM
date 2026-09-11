# Regressão Logística — Mortalidade alta × PIB per capita

## 1. Objetivo

Modelar a probabilidade de um município/ano apresentar taxa de mortalidade
60–69 **acima da mediana da amostra**, em função do PIB per capita. A
regressão logística é a extensão natural do modelo linear quando o alvo é
binário, e permite leitura direta em termos de *chance* (odds) relativa.

## 2. Construção da variável binária

`mortalidade_alta = 1` se a taxa de mortalidade 60–69 da observação está
acima da **mediana da amostra completa**; `0` caso contrário. O corte pela
mediana garante divisão 27/27 entre as classes — didaticamente limpo e
dispensa a adoção de um limiar clínico externo, que não tem consenso na
literatura para essa faixa etária específica.

## 3. Especificação

    logit(P(Y = 1)) = β0 + β1 · PIB per capita

- Interpretação dos coeficientes via **odds ratio** (OR = exp(β)).
- OR < 1 → aumento do preditor reduz a chance do evento (mortalidade alta).
- OR > 1 → aumento do preditor eleva a chance.

## 4. Resultado

O sinal estimado para β1 é **negativo** — consistente com a regressão linear
e com a hipótese teórica: PIB per capita mais alto se associa a menor
probabilidade de mortalidade acima da mediana.

O OR associado ao PIB per capita deve ser lido como o fator multiplicativo
na *chance* de mortalidade alta para cada R$ 1,00 adicional no PIB. Como a
escala do PIB é grande (dezenas a centenas de milhares de reais), o efeito
por real é naturalmente minúsculo — o que importa é o efeito acumulado ao
longo da faixa observada.

O **Pseudo-R² de McFadden** dá a ordem de grandeza do ganho explicativo em
relação ao modelo nulo. Valores baixos (típicos em logística aplicada a
fenômenos sociais) indicam que o PIB, sozinho, discrimina pouco entre
municípios acima e abaixo da mediana.

![](https://raw.githubusercontent.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/main/estrutura/scriptsR/figuras/fig2_logistica_sigmoide.png)

A curva sigmoide mostra a probabilidade prevista em função do PIB, com os
pontos observados (0/1) sobrepostos. A inclinação da curva traduz a força
do efeito: quanto mais plana, mais fraca a associação.

## 5. Discussão e limitações

Assim como no script 1, a estrutura de painel enfraquece as garantias
assintóticas dos testes. Adicionalmente, a discretização em 0/1 via mediana
descarta informação (a magnitude da mortalidade), o que é um trade-off
consciente: ganha-se em interpretação probabilística e comparabilidade com
classificadores, perde-se em resolução.

A leitura conjunta com a regressão linear é o que sustenta a conclusão — os
dois modelos apontam na mesma direção teórica.