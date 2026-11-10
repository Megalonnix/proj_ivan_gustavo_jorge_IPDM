# Teoria do Aprendizado Estatístico — Pesquisa sobre Mortalidade Prematura de Idosos e Desenvolvimento Municipal (IPDM / IPRS)

**Alunos:**
- **Ivan Guimarães dos S. da Silva** — RA `0051352421038`
- **Gustavo Geminiano** — RA `0051352511009`
- **Jorge Sugano Suzart** — RA `0051352511005`

**Professor:** Prof. Dr. João Paulo Ferreira de Mello  
**Disciplina:** Teoria do Aprendizado Estatístico — Curso Superior de Tecnologia em Ciência de Dados (Fatec Baixada Santista — Rubens Lara)  

---

Estudo longitudinal e transversal da mortalidade de 60 a 69 anos e dos indicadores socioeconômicos do Índice Paulista de Responsabilidade Social (IPRS/IPDM — Fundação SEADE), com foco no painel dos nove municípios da Região Metropolitana da Baixada Santista em seis edições bienais (2014–2024, $n = 54$ observações município–ano) e na base estadual paulista ($n = 645$ municípios).

A pergunta norteadora da Entrega 1 é: **quanto a mortalidade de 60 a 69 anos na Baixada Santista depende de onde (município) e de quando (ano)?** As dimensões `riqueza`, `escolaridade`, `distorcao_em` e `pib_per_capita` atuam como preditores socioeconômicos explicativos, enquanto `longevidade` e `ipdm` (que incorporam deterministicamente a própria taxa de mortalidade em sua construção) são excluídos da modelagem supervisionada para evitar vazamento de informação (*data leakage*).

## Mapa do Repositório

| Caminho | Conteúdo |
|---|---|
| [consolidados-aulas/](consolidados-aulas/) | Relatórios canônicos das atividades e pasta `graficos/` separada por etapa |
| [estrutura/codigos/](estrutura/codigos/) | Scripts R numerados (`01` a `11`), auditorias `*-numeros.txt` e tabelas `.csv` geradas |
| [estrutura/bancoDeDados/](estrutura/bancoDeDados/) | Base estadual original, dicionário CSV e recorte longitudinal da Baixada Santista |
| [entregas/entrega-1/](entregas/entrega-1/) | Script R, CSVs, auditoria, artigo Rnw/PDF, referências BibTeX e modelo do professor |
| [slides_aulas/](slides_aulas/) | Slides das aulas 01 a 12 |
| [consolidados-aulas/dicionario/](consolidados-aulas/dicionario/) | Dicionário formal de variáveis em LaTeX/PDF |

## Aulas e resultados

Os prefixos identificam atividades; 02 foi dividida em exploração ampla e segmentada, e as antigas atividades 05/06 foram reunidas. As métricas abaixo são do protocolo de cada atividade e não formam um ranking único. A atividade 10 oferece a comparação nas mesmas dobras externas.

| Atividade / aula | Relatório | Resultado ou diagnóstico |
|---|---|---|
| 01 / 02 | [Dicionário](consolidados-aulas/01-dicionario-variaveis.md) | 54 observações; sem faltantes |
| 02a / 03 | [Exploração ampla](consolidados-aulas/02a-analise-exploratoria-ampla.md) | Mortalidade média 19,91 por mil |
| 02b / 03 | [Exploração segmentada](consolidados-aulas/02b-analise-exploratoria-segmentada.md) | Médias por município e ano; trajetórias do painel |
| 03 / 04 | [Regressão linear](consolidados-aulas/03-regressao-linear.md) | Diagnósticos e intervalos por bootstrap |
| 04 / 05 | [Regressão logística](consolidados-aulas/04-regressao-logistica.md) | Classificação e curva ROC; métricas de ajuste não são CV |
| 05 / 06 | [Avaliação e seleção](consolidados-aulas/05-avaliacao-selecao-modelos.md) | Base RMSE CV5 = 3,8599; compara regressão e classificação |
| 06 / 07 | [Reamostragem](consolidados-aulas/06-metodos-reamostragem.md) | Grau 1 RMSE CV5 = 3,8945; IC bootstrap de β inclui zero |
| 07 / 08 | [Regularização](consolidados-aulas/07-expansao-regularizacao.md) | Elastic Net p = 19: RMSE CV = 2,3121; seleção de lambda interna |
| 08 / 09 | [Suavização](consolidados-aulas/08-metodos-suavizacao.md) | Kernel: MSE CV5 = 12,4573 (escolha de h nas mesmas dobras) |
| 09 / 10 | [Splines e GAM](consolidados-aulas/09-splines-modelos-aditivos.md) | GAM estrutural RMSE CV5 ≈ 2,35 |
| 10 / 11 | [Árvores e florestas](consolidados-aulas/10-arvores-florestas.md) | MQO estrutural RMSE 2,2022; floresta 3,1419; seleção interna à CV externa |
| 11 / 12 | [Agrupamento e PCA](consolidados-aulas/11-agrupamento-pca.md) | PC1+PC2: 75,64%; K = 2; silhueta 0,3546 |

Na comparação da atividade 10, **MQO com município e ano continua campeão provisório**. A poda 1-SE seleciona uma árvore sem divisões. As cinco dobras aleatórias avaliam interpolação no painel; não demonstram capacidade de prever anos futuros ou municípios novos. O ranking não inclui uma validação externa da regularização, cujo lambda foi selecionado na própria CV da atividade 07.

## Reproduzir

Instale R e os pacotes:

```r
install.packages(c("rpart", "randomForest", "glmnet", "mgcv", "cluster", "knitr"))
# splines é distribuído com R.
```

Na raiz deste repositório:

```bash
bash reproduzir.sh
```

Ou execute uma atividade individualmente:

```bash
Rscript estrutura/codigos/10-arvores-florestas.R
Rscript estrutura/codigos/11-agrupamento-pca.R
```

Os scripts usam a base local, fixam as sementes (`set.seed(1)`) e exportam as métricas e saídas de auditoria para `estrutura/codigos/*-numeros.txt`. Os relatórios em `consolidados-aulas/` estão integralmente sincronizados com os números das auditorias e incluem a fundamentação matemática e a resolução completa dos exercícios de todas as aulas (Aulas 01 a 12). Modelos das etapas finais também exportam predições, dobras e grupos para CSV. Versões de R/pacotes podem afetar resultados; a execução de validação usou R 4.5.2 e registra `sessionInfo()` nas novas auditorias.

A seleção de hiperparâmetros em 10 ocorre dentro do treino de cada dobra externa. Em 11, Y só é consultada depois do agrupamento. PCA e clusters são exploratórios; para usá-los como preditores, o pré-processamento deve ser reaprendido dentro de cada treino.

## Entrega formal

```bash
cd entregas/entrega-1
Rscript entrega-1-pergunta.R
Rscript -e 'knitr::knit2pdf("entrega-1-pergunta.Rnw")'
```

A compilação requer uma distribuição LaTeX com os pacotes declarados no Rnw e BibTeX. Alternativa com Tectonic:

```bash
Rscript -e 'knitr::knit("entrega-1-pergunta.Rnw")'
tectonic entrega-1-pergunta.tex
```

O artigo carrega o mesmo script que produz `entrega-1-resultados.csv`, `entrega-1-escalas.csv` e `entrega-1-numeros.txt`; os valores do texto continuam interpolados por `Sexpr`. O relatório [escolha-da-pergunta.md](entregas/entrega-1/escolha-da-pergunta.md) preserva a discussão original da escolha.
