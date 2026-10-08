# =============================================================
# ATIVIDADE 02 - DIAGNÓSTICO 4 PASSOS, BASELINE E EDA
# Alvo: mortalidade_60_69
# =============================================================
if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) {
  caminho_script <- rstudioapi::getSourceEditorContext()$path
  if (nzchar(caminho_script) && dir.exists(dirname(caminho_script))) {
    setwd(dirname(caminho_script))
  }
}

arquivo_local <- file.path("..", "bancoDeDados", "df_ipdm_baixada_por_municipio.csv")
url_github    <- "https://raw.githubusercontent.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/main/estrutura/bancoDeDados/df_ipdm_baixada_por_municipio.csv"

if (file.exists(arquivo_local)) {
  origem_dados <- arquivo_local
  cat("[INFO] Carregando banco LOCAL.\n")
} else {
  origem_dados <- url_github
  cat("[INFO] Carregando do GitHub.\n")
}

dados_brutos <- read.csv(origem_dados, sep = ";", dec = ",", fileEncoding = "latin1",
                         check.names = FALSE, stringsAsFactors = FALSE)

dados <- data.frame(
  cod_ibge          = factor(dados_brutos[[1]]),
  municipio         = factor(dados_brutos[[2]]),
  ano               = as.integer(dados_brutos[[3]]),
  riqueza           = as.numeric(dados_brutos[[4]]),
  longevidade       = as.numeric(dados_brutos[[5]]),
  escolaridade      = as.numeric(dados_brutos[[6]]),
  ipdm              = as.numeric(dados_brutos[[7]]),
  mortalidade_60_69 = as.numeric(dados_brutos[[8]]),
  distorcao_em      = as.numeric(dados_brutos[[9]]),
  pib_per_capita    = as.numeric(dados_brutos[[10]])
)

# Alvo binário
mediana_mort <- median(dados$mortalidade_60_69)
dados$mortalidade_alta <- as.integer(dados$mortalidade_60_69 > mediana_mort)

n <- nrow(dados)
p <- 9  # preditores válidos

cazul <- "#276DC3"; claranja <- "#E66101"; cverde <- "#2CA02C"
croxo <- "#5E3C99"; cfill <- "#E0E7FF"
pasta_fig <- "figuras"; if (!dir.exists(pasta_fig)) dir.create(pasta_fig, recursive = TRUE)

buffer <- character(0)
add <- function(...) { txt <- paste0(...); cat(txt, "\n"); buffer <<- c(buffer, txt) }
add_print <- function(x) {
  out <- capture.output(print(x)); cat(paste(out, collapse = "\n"), "\n")
  buffer <<- c(buffer, out)
}

add("================ PROTOCOLO DE DIAGNÓSTICO ================")

# Passo 1 — correlações com o ALVO mortalidade_60_69
num_vars <- dados[sapply(dados, is.numeric)]
cor_y <- sort(abs(cor(num_vars, use = "complete.obs")[, "mortalidade_60_69"]), decreasing = TRUE)
add(""); add("--- Passo 1: Correlações com mortalidade_60_69 ---")
add_print(round(cor_y, 4))
add("Leitura: longevidade e ipdm aparecem como altamente correlacionados —")
add("por isso são EXCLUÍDOS como preditores (circularidade conceitual).")
add("Preditores válidos: escolaridade, distorcao_em, pib_per_capita, riqueza.")

# Passo 2 — n vs p
add(""); add("--- Passo 2: n vs p ---")
add("n = ", n, " | p_válidos = ", p, " | n/p = ", round(n / p, 2))
add("Diagnóstico: n/p < 10 ⇒ parcimônia ou regularização.")

# Passo 3 — balanço
add(""); add("--- Passo 3: Balanço (mortalidade_alta) ---")
tab_cls <- table(dados$mortalidade_alta)
add_print(tab_cls); add_print(prop.table(tab_cls))

# Passo 4 — NAs
add(""); add("--- Passo 4: NAs ---")
add_print(colSums(is.na(dados)))

# Baselines
add(""); add("================ BASELINES ================")
base_reg  <- sd(dados$mortalidade_60_69)
base_cls  <- max(table(dados$mortalidade_alta)) / n
add("Baseline regressão (RMSE = sd(Y)): ", round(base_reg, 4))
add("Baseline classificação: ", round(base_cls * 100, 2), " %")
add("Unidade de Y: mortes por mil habitantes na faixa 60–69.")

add(""); add("================ RESUMO NUMÉRICO ================")
add_print(summary(dados[, sapply(dados, is.numeric)]))

# Gráfico 1 — histograma do alvo
arq1 <- file.path(pasta_fig, "02-analise-exploratoria_img1.png")
png(arq1, width = 700, height = 700); par(mar = c(4,4,1,1), pty = "s")
hist(dados$mortalidade_60_69, prob = TRUE, col = cfill, border = "white",
     xlab = "Mortalidade 60–69 (por mil hab.)", ylab = "Densidade",
     main = "Distribuição: mortalidade_60_69")
curve(dnorm(x, mean(dados$mortalidade_60_69), sd(dados$mortalidade_60_69)),
      add = TRUE, lwd = 3, col = claranja)
abline(v = mean(dados$mortalidade_60_69),   col = cazul,  lwd = 3)
abline(v = median(dados$mortalidade_60_69), col = cverde, lwd = 3, lty = 2)
legend("topright", c("Média","Mediana","Normal teórica"),
       col = c(cazul,cverde,claranja), lwd = 3, lty = c(1,2,1), bty = "n")
dev.off()

# Gráfico 2 — boxplot por município
arq2 <- file.path(pasta_fig, "02-analise-exploratoria_img2.png")
png(arq2, width = 900, height = 700); par(mar = c(6,4,1,1), pty = "s")
boxplot(mortalidade_60_69 ~ municipio, data = dados, col = cfill, border = "gray30",
        main = "Mortalidade 60–69 por Município", xlab = "",
        ylab = "Mortalidade (por mil hab.)", las = 2)
abline(h = mean(dados$mortalidade_60_69), col = claranja, lwd = 2, lty = 2)
dev.off()

# Gráfico 3 — dispersão escolaridade × mortalidade
arq3 <- file.path(pasta_fig, "02-analise-exploratoria_img3.png")
png(arq3, width = 700, height = 700); par(mar = c(4,4,1,1), pty = "s")
plot(dados$escolaridade, dados$mortalidade_60_69, pch = 19, col = cazul,
     xlab = "Escolaridade [índice 0-1]", ylab = "Mortalidade 60–69 (por mil hab.)",
     main = "Escolaridade vs Mortalidade 60–69")
abline(lm(mortalidade_60_69 ~ escolaridade, data = dados), col = claranja, lwd = 3)
dev.off()

add(""); add("[OK] Figuras gravadas em: ", pasta_fig)

arquivo_md <- "02-analise-exploratoria.md"
cabecalho <- c(
  "# Relatório da Atividade 02 — Diagnóstico, Baseline e EDA",
  "",
  paste0("**Gerado por:** `02-analise-exploratoria.R`  "),
  paste0("**Data:** ", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "  "),
  paste0("**Origem:** `", origem_dados, "`  "),
  "",
  "> **Alvo:** `mortalidade_60_69` (mortes por mil hab. na faixa 60–69).",
  "",
  "## Sumário executivo",
  "",
  paste0("- n = ", n, " | p_válidos = ", p, " | n/p = ", round(n / p, 2)),
  paste0("- Mediana do alvo = ", round(mediana_mort, 4)),
  paste0("- Baseline regressão (sd Y) = ", round(base_reg, 4)),
  paste0("- Baseline classificação = ", round(base_cls * 100, 2), " %"),
  "",
  "## Preditores",
  "",
  "Válidos: `escolaridade`, `distorcao_em`, `pib_per_capita`, `riqueza`, `ano`.",
  "Excluídos por circularidade: `longevidade`, `ipdm`.",
  "",
  "## Figuras geradas",
  "",
  paste0("- `", arq1, "` — Histograma do alvo + Normal teórica"),
  paste0("- `", arq2, "` — Boxplot do alvo por município"),
  paste0("- `", arq3, "` — Dispersão Escolaridade × Mortalidade"),
  "",
  "## Output bruto",
  "", "```", paste(buffer, collapse = "\n"), "```",
  "",
  "## Notas",
  "",
  "Baseline de regressão = sd(Y). Se RMSE_CV < sd(Y), o modelo tem sinal real.",
  "Como o alvo é binarizado pela mediana, o baseline de classificação é ~50%.",
  ""
)
writeLines(cabecalho, arquivo_md)
cat("\n[OK] Relatório gravado em:", arquivo_md, "\n")