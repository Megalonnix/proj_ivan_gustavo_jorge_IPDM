# ==============================================================================
# 0. ANÁLISE EXPLORATÓRIA — IPDM Baixada Santista
# ==============================================================================
# Cobre as tarefas das Aulas 2 e 3:
#   Aula 2 -> tipagem correta das variáveis (código vira factor, não número)
#   Aula 3 -> EDA: posição, dispersão, histograma, boxplot, dispersão,
#             densidade Normal sobreposta, contagem de faltantes
# ==============================================================================

if (!require('pacman')) install.packages('pacman')
pacman::p_load(readr, dplyr, tidyr, moments)

# ------------------------------------------------------------------- caminhos
caminho_base <- paste0(
  "C:/Users/Ivan/Documents/Pasta-Documentos-PC-antigo/",
  "GITHUB-Meus-Repositorios/PesquisaTeoAprendiEstati_2026_v2/",
  "proj_ivan_gustavo_jorge_(IPDM)"
)
caminho_banco <- file.path(caminho_base, "estrutura", "bancoDeDados")
caminho_fig   <- file.path(caminho_base, "estrutura", "scriptsR", "figuras")
if (!dir.exists(caminho_fig)) {
  dir.create(caminho_fig, recursive = TRUE, showWarnings = FALSE)
}
stopifnot(dir.exists(caminho_fig))

# ---------------------------------------------------------------- importação
df_ipdm <- read_csv2(
  file.path(caminho_banco, "dados_ipdm.csv"),
  locale = locale(encoding = "Latin1"),
  show_col_types = FALSE
)
df_ipdm <- df_ipdm %>% select(-`...12`)

# -------------------------------------------------- filtragem Baixada Santista
baixada_santista <- c(
  "Santos", "Guarujá", "São Vicente",
  "Praia Grande", "Cubatão", "Itanhaém",
  "Mongaguá", "Bertioga", "Peruíbe"
)
df_ipdm_baixada <- df_ipdm %>% filter(Municipio %in% baixada_santista)

# ==============================================================================
# EDA PRELIMINAR (formato longo, antes do pivot)
# ==============================================================================
cat("\n--- Estrutura (formato longo) ---\n");   str(df_ipdm_baixada)
cat("\n--- Dimensão ---\n");                    print(dim(df_ipdm_baixada))
cat("\n--- Faltantes por coluna ---\n");        print(colSums(is.na(df_ipdm_baixada)))
cat("\n--- Primeiras linhas ---\n");            print(head(df_ipdm_baixada))

# ==============================================================================
# FORMATO WIDE + CÁLCULO DO IPDM
# ==============================================================================
wide <- df_ipdm_baixada %>%
  mutate(rotulo = coalesce(na_if(`Indicador 5`, ""), na_if(`Indicador 4`, ""))) %>%
  filter(!is.na(rotulo)) %>%
  select(cod_ibge, Municipio, Ano, rotulo, Valor) %>%
  pivot_wider(names_from = rotulo, values_from = Valor)

wide <- wide %>%
  mutate(IPDM = (`Indicador Riqueza` + `Indicador Longevidade` + `Indicador Escolaridade`) / 3) %>%
  rename(
    `Riqueza [índice 0-1]`      = `Indicador Riqueza`,
    `Longevidade [índice 0-1]`  = `Indicador Longevidade`,
    `Escolaridade [índice 0-1]` = `Indicador Escolaridade`,
    `IPDM [índice 0-1]`         = IPDM
  ) %>%
  relocate(`Riqueza [índice 0-1]`, `Longevidade [índice 0-1]`,
           `Escolaridade [índice 0-1]`, `IPDM [índice 0-1]`, .after = Ano)

# ==============================================================================
# AULA 2 — TIPAGEM CORRETA DAS VARIÁVEIS
# ==============================================================================
# cod_ibge é IDENTIFICADOR (rótulo), não quantidade -> vira factor
# Municipio é qualitativa nominal -> factor
# (Ano poderia virar ordered se quiséssemos tratá-lo como ordinal de triênios,
#  mas mantemos integer para preservar uso numérico adiante.)
wide <- wide %>%
  mutate(
    cod_ibge  = factor(cod_ibge),
    Municipio = factor(Municipio)
  )

# ==============================================================================
# AULA 3 — EDA DO BANCO FINAL
# ==============================================================================
# Cópia com nomes curtos APENAS para os gráficos e resumos abaixo;
# o CSV salvo no final mantém os nomes longos originais.
eda <- wide
names(eda)[grepl("^Taxas de mortalidade", names(eda))] <- "mortalidade_60_69"
names(eda)[grepl("^Produto Interno Bruto", names(eda))] <- "pib_per_capita"

cat("\n--- Estrutura do banco final ---\n");    str(eda)
cat("\n--- Classes por coluna ---\n");           print(sapply(eda, function(x) class(x)[1]))
cat("\n--- Faltantes por coluna ---\n");         print(colSums(is.na(eda)))
cat("\n--- Resumo geral ---\n");                 print(summary(eda))

# ---------------------------------------- Posição + dispersão (PIB per capita)
cat("\n--- PIB per capita ---\n")
print(summary(eda$pib_per_capita))
cat("Desvio-padrão amostral:", round(sd(eda$pib_per_capita), 2), "\n")
cat("Assimetria (skewness):", round(moments::skewness(eda$pib_per_capita), 3), "\n")
cat("Curtose:",              round(moments::kurtosis(eda$pib_per_capita), 3), "\n")

# --- Gráfico 1: histograma com densidade Normal sobreposta (slide 19, Aula 3)
png(file.path(caminho_fig, "fig0_eda_pib_hist.png"),
    width = 800, height = 800, res = 110)
par(mar = c(4, 4, 2, 1), pty = "s")
hist(eda$pib_per_capita, prob = TRUE,
     col = "lightblue", border = "white",
     main = "PIB per capita — histograma + Normal",
     xlab = "PIB per capita (R$ de 2024)")
curve(dnorm(x, mean(eda$pib_per_capita), sd(eda$pib_per_capita)),
      add = TRUE, lwd = 3, col = "darkorange")
dev.off()

# --- Gráfico 2: boxplot da mesma variável
png(file.path(caminho_fig, "fig0_eda_pib_boxplot.png"),
    width = 800, height = 800, res = 110)
par(mar = c(4, 4, 2, 1), pty = "s")
boxplot(eda$pib_per_capita, col = "lightblue",
        main = "Boxplot — PIB per capita",
        ylab = "PIB per capita (R$ de 2024)")
dev.off()

# --- Gráfico 3: dispersão entre duas quantitativas
png(file.path(caminho_fig, "fig0_eda_pib_mortalidade.png"),
    width = 800, height = 800, res = 110)
par(mar = c(4, 4, 2, 1), pty = "s")
plot(eda$pib_per_capita, eda$mortalidade_60_69,
     pch = 19, col = "steelblue",
     xlab = "PIB per capita (R$ de 2024)",
     ylab = "Mortalidade 60-69 (por mil hab.)",
     main = "PIB per capita x Mortalidade 60-69")
dev.off()

# --- Gráfico 4: quantitativa por grupo (boxplot por município)
png(file.path(caminho_fig, "fig0_eda_mortalidade_por_municipio.png"),
    width = 950, height = 800, res = 110)
par(mar = c(8, 4, 2, 1), pty = "s")
boxplot(mortalidade_60_69 ~ Municipio, data = eda,
        col = "lightblue", las = 2,
        main = "Mortalidade 60-69 por município",
        ylab = "Mortalidade (por mil hab.)",
        xlab = "")
dev.off()

# ==============================================================================
# PERSISTÊNCIA (mantém nomes longos originais para compatibilidade com 1..4)
# ==============================================================================
df_ipdm_baixada_por_municipio <- wide

write.csv2(
  df_ipdm_baixada_por_municipio,
  file = file.path(caminho_banco, "df_ipdm_baixada_por_municipio.csv"),
  row.names = FALSE,
  fileEncoding = "Latin1"
)

cat("\nScript 0 concluído. Figuras em:", caminho_fig, "\n")


# ==============================================================================
# MICRO-RELATÓRIO — SCRIPT 0 (Análise Exploratória)
# ==============================================================================
# Este bloco documenta as decisões metodológicas e as leituras esperadas dos
# resultados. Ele NÃO é executado; serve como guia para a redação do trabalho
# e para releitura futura do código.
#
# ------------------------------------------------------------------------------
# 1. TIPAGEM DAS VARIÁVEIS (Aula 2)
# ------------------------------------------------------------------------------
# Decisões:
#   - cod_ibge: inteiro -> factor. Justificativa: é identificador (rótulo),
#     não quantidade. Guardá-lo como número permitiria operações sem sentido
#     (média de código IBGE) e induziria o R a tratá-lo como preditor
#     contínuo num lm() por engano. O slide 14 da Aula 2 é explícito sobre
#     esse erro clássico.
#   - Municipio: character -> factor. É qualitativa nominal; o factor
#     habilita boxplot por grupo, contrastes e futuros modelos com efeitos
#     fixos por município (aprofundamento natural).
#   - Ano: mantido integer. Poderia ser ordered (2014 < 2016 < ...), mas
#     como não o usamos como preditor ordinal nem o incluímos em nenhum
#     modelo (até o momento), mantê-lo numérico evita conversões
#     desnecessárias adiante.
#
# ------------------------------------------------------------------------------
# 2. EDA DAS VARIÁVEIS QUANTITATIVAS (Aula 3)
# ------------------------------------------------------------------------------
# Estratégia:
#   - Resumo (summary + sd + skewness + kurtosis) para posição, dispersão
#     e forma.
#   - Histograma com densidade Normal sobreposta: compara a forma empírica
#     com a Normal teórica ajustada pela média/desvio da amostra. Aderência
#     visual forte sugeriria Normal; desvios (cauda longa à direita, pico
#     estreito, bimodalidade) indicam assimetria ou mistura de populações.
#   - Boxplot: revela mediana, quartis e OUTLIERS segundo a regra 1,5*IQR.
#   - Dispersão (PIB x mortalidade): primeiro olhar sobre a relação bivariada
#     que será modelada no script 1.
#   - Boxplot por município: verifica se há heterogeneidade sistemática
#     entre municípios, o que dialoga com a estrutura de painel discutida
#     na Aula 4 (slide 14, "outliers e alavancagem") e nos consolidados.
#
# ------------------------------------------------------------------------------
# 3. OUTLIERS — POR QUE NÃO OS REMOVEMOS
# ------------------------------------------------------------------------------
# O boxplot do PIB per capita acusa pontos acima do bigode superior. Eles
# correspondem, com alta probabilidade, a Cubatão (PIB per capita ~170-270
# mil, muito acima do resto). Essa observação NÃO é erro de digitação: é o
# polo industrial de Cubatão, fato econômico real da região.
#
# Decisão: MANTER os outliers no banco e nos modelos subsequentes.
# Justificativas:
#   (a) O boxplot existe para REVELAR outliers, não para escondê-los.
#       Usar outline = FALSE maquia a EDA — contra o espírito do slide 9
#       da Aula 3.
#   (b) A amostra tem 54 observações. Cada linha pesa ~2% do total. Excluir
#       reduz poder estatístico e encolhe o intervalo do preditor, tornando
#       o coeficiente do script 1 ainda mais instável.
#   (c) O outlier é ponto de alta ALAVANCAGEM (PIB extremo). Removê-lo
#       altera a inclinação estimada de forma substancial — o que, por si,
#       é informação relevante e deve ser reportada, não silenciada.
#
# Tratamento adotado:
#   - Mantém-se a OLS completa como modelo principal.
#   - No script 1, inclui-se uma versão auxiliar SEM Cubatão, lado a lado,
#     para reportar a sensibilidade do coeficiente ao ponto extremo.
#   - A discussão final menciona o ponto como fonte de incerteza, e não
#     como valor a ser excluído.
#   - Direções de aprofundamento (registradas, fora do escopo): erros-padrão
#     robustos (HC3) e regressão quantílica.
#
# ------------------------------------------------------------------------------
# 4. LEITURA ESPERADA DOS RESULTADOS
# ------------------------------------------------------------------------------
# Após rodar este script, espera-se:
#   - summary(pib_per_capita) com média MUITO acima da mediana (assimetria
#     à direita puxada por Cubatão). Se média ~ mediana, algo está errado
#     com a importação.
#   - skewness > 0 e kurtosis > 3 (cauda longa à direita e pico agudo),
#     coerente com a distribuição de PIB per capita em regiões com polos
#     industriais.
#   - Histograma com densidade Normal sobreposta mostrando clara falta de
#     aderência na cauda direita: a Normal SUBESTIMA a frequência de valores
#     altos. Isso reforça que a Normal não é um bom modelo descritivo para
#     essa variável — embora a OLS não exija normalidade do PREDITOR, só
#     dos resíduos.
#   - Boxplot por município: mortalidade 60-69 com medianas distintas entre
#     municípios, evidência de heterogeneidade que justifica a ressalva
#     sobre painel nos consolidados.
#   - colSums(is.na(...)) zerado ou quase: banco limpo, sem imputação
#     necessária.
#
# ------------------------------------------------------------------------------
# 5. AMARRAÇÃO COM OS PRÓXIMOS SCRIPTS
# ------------------------------------------------------------------------------
# - O CSV salvo mantém os nomes longos originais para que os scripts 1-4
#   funcionem sem alteração (eles renomeiam localmente via grepl).
# - A decisão de manter outliers informa diretamente o script 1: o modelo
#   principal será OLS completa, e a comparação com/sem Cubatão aparece
#   como análise de sensibilidade.
# - A tipagem de Municipio como factor habilita, em versões futuras, modelos
#   com efeitos fixos (lm com + Municipio), que endereçariam a violação de
#   i.i.d. levantada na discussão do script 1.
# ==============================================================================
