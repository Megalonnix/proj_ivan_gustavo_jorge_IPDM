# Relatório da Atividade 01 — Dicionário de Variáveis e Tipagem

**Gerado por:** `01-dicionario-variaveis.R`  
**Data:** 2026-10-08 21:09:16  
**Origem:** `../bancoDeDados/df_ipdm_baixada_por_municipio.csv`  

> **Alvo do projeto:** `mortalidade_60_69` (por mil hab.).
> O IPDM NÃO é mais o alvo: ele é composto por riqueza + longevidade +
> escolaridade, e usá-lo como resposta gera circularidade com os preditores.

## 1. Dimensões

- Observações (n) = 54
- Preditores potenciais (p) = 9
- Municípios = 9
- Anos = 2014, 2016, 2018, 2020, 2022, 2024
- n/p = 6 — modelagem parcimoniosa.

## 2. Dicionário

```
                                      Coluna_Original  Nome_Padronizado      Tipo_Estatistico  Tipo_R
1                                            cod_ibge          cod_ibge         Identificador  factor
2                                           Municipio         municipio   Qualitativa Nominal  factor
3                                                 Ano               ano Quantitativa Discreta integer
4                                Riqueza [índice 0-1]           riqueza Quantitativa Contínua numeric
5                            Longevidade [índice 0-1]       longevidade Quantitativa Contínua numeric
6                           Escolaridade [índice 0-1]      escolaridade Quantitativa Contínua numeric
7                                   IPDM [índice 0-1]              ipdm Quantitativa Contínua numeric
8   Taxas de mortalidade  60 a 69 anos (por mil hab.) mortalidade_60_69 Quantitativa Contínua numeric
9  Taxas de distorção idade-série no Ensino Médio (%)      distorcao_em Quantitativa Contínua numeric
10      Produto Interno Bruto per capita (R$ de 2024)    pib_per_capita Quantitativa Contínua numeric
   Valores_Distintos Nulos
1                  9     0
2                  9     0
3                  6     0
4                 47     0
5                 44     0
6                 48     0
7                 50     0
8                 54     0
9                 54     0
10                45     0
```

## 3. Classes

```
         cod_ibge         municipio               ano           riqueza       longevidade      escolaridade 
         "factor"          "factor"         "integer"         "numeric"         "numeric"         "numeric" 
             ipdm mortalidade_60_69      distorcao_em    pib_per_capita 
        "numeric"         "numeric"         "numeric"         "numeric" 
```

## 4. Amostra

```
  cod_ibge municipio  ano riqueza longevidade escolaridade      ipdm mortalidade_60_69 distorcao_em pib_per_capita
1  3506359  Bertioga 2014   0.575       0.609        0.363 0.5156667          17.69156     17.26543       46417.74
2  3506359  Bertioga 2016   0.559       0.639        0.440 0.5460000          16.23510     16.45526       45937.18
3  3506359  Bertioga 2018   0.548       0.653        0.483 0.5613333          17.12161     16.79530       46417.74
4  3506359  Bertioga 2020   0.553       0.672        0.551 0.5920000          22.19854     15.07601       41444.84
5  3506359  Bertioga 2022   0.519       0.633        0.508 0.5533333          25.42855     13.30000       34785.52
```

## 5. Nota metodológica

Preditores **circulares** com o alvo (excluídos dos modelos):
- `longevidade` — componente do IPDM, altamente correlacionado com mortalidade.
- `ipdm` — composto que contém longevidade.

Preditores **válidos** para mortalidade_60_69:
`escolaridade`, `distorcao_em`, `pib_per_capita`, `ano`, `riqueza`.

