# =============================================================
# ATIVIDADE 03 - REGRESSÃO LINEAR, RESÍDUOS, GRAUS E BOOTSTRAP
# =============================================================
# Pergunta: Escolaridade -> IPDM
# Padrão: Prof. Dr. João Paulo Ferreira de Mello (Base R First)
# Carregamento direto via GitHub
# =============================================================

# =============================================================
# PARTE 1 - LER E PREPARAR OS DADOS (DIRETO DO GITHUB)
# =============================================================
nome_csv    <- "df_ipdm_baixada_por_municipio.csv"
url_github  <- "https://raw.githubusercontent.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/main/estrutura/bancoDeDados/df_ipdm_baixada_por_municipio.csv"

# --- Onde o script pode estar? (Rscript, source(), RStudio ou diretório atual) ---
pontos_partida <- getwd()
args_cmd <- commandArgs(trailingOnly = FALSE)
arq_cmd  <- sub("^--file=", "", args_cmd[grep("^--file=", args_cmd)])
if (length(arq_cmd) == 1) pontos_partida <- c(dirname(normalizePath(arq_cmd)), pontos_partida)
arq_src <- tryCatch(sys.frame(1)$ofile, error = function(e) NULL)
if (!is.null(arq_src)) pontos_partida <- c(dirname(normalizePath(arq_src)), pontos_partida)
if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) {
  arq_rs <- tryCatch(rstudioapi::getSourceEditorContext()$path, error = function(e) "")
  if (nzchar(arq_rs)) pontos_partida <- c(dirname(normalizePath(arq_rs)), pontos_partida)
}

# --- Sobe nas pastas-pai até achar estrutura/bancoDeDados/<csv> ---
achar_raiz <- function(pontos) {
  for (ponto in pontos) {
    atual <- normalizePath(ponto, winslash = "/", mustWork = FALSE)
    for (nivel in 1:8) {
      if (file.exists(file.path(atual, "estrutura", "bancoDeDados", nome_csv))) return(atual)
      pai <- dirname(atual)
      if (pai == atual) break
      atual <- pai
    }
  }
  NULL
}
raiz <- achar_raiz(pontos_partida)

ler_csv <- function(f) read.csv(f, sep = ";", dec = ",", fileEncoding = "latin1",
                                check.names = FALSE, stringsAsFactors = FALSE)

# --- 1) LOCAL primeiro; 2) GitHub só se não achar localmente ---
if (!is.null(raiz)) {
  arquivo_local <- file.path(raiz, "estrutura", "bancoDeDados", nome_csv)
  cat("Dados lidos LOCALMENTE de:", arquivo_local, "\n")
  dados_brutos <- ler_csv(arquivo_local)
} else {
  cat("CSV não encontrado localmente. Buscando no GitHub...\n")
  dados_brutos <- tryCatch(ler_csv(url_github), error = function(e) {
    stop("Não achei '", nome_csv, "' nem localmente (procurei a partir de: ",
         paste(unique(pontos_partida), collapse = " | "),
         ") nem no GitHub (", url_github, ").", call. = FALSE)
  })
}

# --- Pasta de figuras: SEMPRE estrutura/scriptsR/figuras da raiz do projeto ---
dir_figuras <- if (!is.null(raiz)) file.path(raiz, "estrutura", "scriptsR", "figuras") else file.path(getwd(), "figuras")
dir.create(dir_figuras, showWarnings = FALSE, recursive = TRUE)
cat("Figuras serão salvas em:", normalizePath(dir_figuras, winslash = "/"), "\n")

dados <- data.frame(
  cod_ibge          = factor(dados_brutos[[1]]),
  municipio         = factor(dados_brutos[[2]]),
  ano               = as.integer(dados_brutos[[3]]),
  escolaridade      = as.numeric(dados_brutos[[6]]),
  ipdm              = as.numeric(dados_brutos[[7]])
)

y <- dados$ipdm
x <- dados$escolaridade

# Cores oficiais do professor
cazul    <- "#276DC3"
claranja <- "#E66101"
cverde   <- "#2CA02C"
croxo    <- "#5E3C99"
cfill    <- "#E0E7FF"

# =============================================================
# PARTE 2 - AJUSTAR O MODELO LINEAR (MQO / OLS)
# =============================================================
m <- lm(y ~ x, data = dados)
s <- summary(m)
ci <- confint(m, level = 0.95)

cat("\n================ RESUMO DO MODELO (coeficientes) ================\n")
printCoefmat(coef(s), signif.legend = FALSE)

b0 <- coef(m)[1]
b1 <- coef(m)[2]

cat("\n================ EQUAÇÃO DO MODELO (MQO) ================\n")
b0_fmt <- format(round(b0, 4), decimal.mark = ",")
b1_fmt <- format(round(b1, 4), decimal.mark = ",")
cat("IPDM =", b0_fmt, "+", b1_fmt, "× escolaridade\n")

cat("\n================ INTERVALOS DE CONFIANÇA ANALÍTICOS (95%) ================\n")
print(ci)

cat("\n================ MÉTRICAS DE ADERÊNCIA ================\n")
cat("R²:                      ", round(s$r.squared, 4), "\n")
cat("R² ajustado:             ", round(s$adj.r.squared, 4), "\n")
cat("Erro-padrão residual (s):", round(s$sigma, 4), "\n")
cat("F-statistic:             ", round(s$fstatistic[1], 4), "(p-valor:", round(pf(s$fstatistic[1], s$fstatistic[2], s$fstatistic[3], lower.tail = FALSE), 11), ")\n")

# =============================================================
# PARTE 3 - TABELA ILUSTRATIVA DE PREVISÃO PARA VALORES DE ESCOLARIDADE
# =============================================================
esc_exemplos <- c(0.35, 0.45, 0.55, 0.65)
pred_exemplos <- predict(m, newdata = data.frame(x = esc_exemplos))

tabela_pred <- data.frame(
  escolaridade  = esc_exemplos,
  ipdm_previsto = round(pred_exemplos, 4)
)
cat("\n================ TABELA: Previsões de IPDM para Valores Típicos de Escolaridade ================\n")
print(tabela_pred)

# =============================================================
# PARTE 4 - GRÁFICOS: RETA MQO, RESÍDUOS E COMPROMISSO VIÉS-VARIÂNCIA
# =============================================================

# Gráfico 1: Dispersão com Reta MQO e Resíduos Verticais (Aula 4)
png(file.path(dir_figuras, "03-regressao-linear_img1.png"), width = 700, height = 700)
par(mar = c(4, 4, 1, 1), pty = "s")
plot(x, y, pch = 19, col = cazul,
     xlab = "Escolaridade [índice 0-1]", ylab = "IPDM [índice 0-1]",
     main = "Regressão Linear e Resíduos MQO")
abline(m, col = claranja, lwd = 3)
segments(x, y, x, fitted(m), col = cverde, lwd = 1.2)
legend("topleft", legend = c("Observado", "Reta MQO", "Resíduos"),
       col = c(cazul, claranja, cverde), pch = c(19, NA, NA),
       lwd = c(NA, 3, 1.2), lty = c(NA, 1, 1), bty = "n")
dev.off()

# Gráfico 2: Resíduos vs Valores Ajustados (Aula 4)
png(file.path(dir_figuras, "03-regressao-linear_img2.png"), width = 700, height = 700)
par(mar = c(4, 4, 1, 1), pty = "s")
plot(fitted(m), resid(m), pch = 19, col = cazul,
     xlab = "Valores Ajustados", ylab = "Resíduos",
     main = "Resíduos vs Valores Ajustados")
abline(h = 0, col = claranja, lwd = 3, lty = 2)
dev.off()

# Diagnóstico de normalidade dos resíduos
shap <- shapiro.test(resid(m))
cat("\n================ DIAGNÓSTICO DE NORMALIDADE DOS RESÍDUOS ================\n")
cat("Shapiro-Wilk W:", round(shap$statistic, 4), "| p-valor:", round(shap$p.value, 5), "\n")

# Gráfico 3: Compromisso Viés-Variância (Polinômios Graus 1, 2, 4) (Aula 1)
png(file.path(dir_figuras, "03-regressao-linear_img3.png"), width = 700, height = 700)
par(mar = c(4, 4, 1, 1), pty = "s")
plot(x, y, pch = 19, col = "gray60",
     xlab = "Escolaridade [índice 0-1]", ylab = "IPDM [índice 0-1]",
     main = "Compromisso Viés-Variância (Graus 1, 2, 4)")
xx <- seq(min(x), max(x), length.out = 200)
cores_poly <- c(cazul, claranja, croxo)
graus <- c(1, 2, 4)
for (k in seq_along(graus)) {
  m_poly <- lm(y ~ poly(x, graus[k]), data = dados)
  lines(xx, predict(m_poly, newdata = data.frame(x = xx)), col = cores_poly[k], lwd = 2.5)
}
legend("topleft", legend = c("Grau 1 (Reta)", "Grau 2 (Quadrático)", "Grau 4 (Flexível)"),
       col = cores_poly, lwd = 2.5, bty = "n")
dev.off()

# =============================================================
# PARTE 5 - REAMOSTRAGEM VIA BOOTSTRAP (B = 2000)
# =============================================================
B <- 2000
set.seed(1)
b1_boot <- replicate(B, {
  i <- sample(length(y), length(y), replace = TRUE)
  coef(lm(y[i] ~ x[i]))[2]
})

se_boot <- sd(b1_boot)
ci_boot <- quantile(b1_boot, c(0.025, 0.975))

cat("\n================ INFERÊNCIA BOOTSTRAP (B = 2000) ================\n")
cat("Beta 1 Original (MQO):       ", sprintf("%.4f", b1), "\n")
cat("Erro-Padrão Bootstrap:       ", sprintf("%.4f", se_boot), "\n")
cat("IC 95% Bootstrap (Percentil): [", sprintf("%.4f", ci_boot[1]), ";", sprintf("%.4f", ci_boot[2]), "]\n")

# Gráfico 4: Distribuição Bootstrap de Beta 1 (Aula 7)
png(file.path(dir_figuras, "03-regressao-linear_img4.png"), width = 700, height = 700)
par(mar = c(4, 4, 1, 1), pty = "s")
hist(b1_boot, breaks = 30, prob = TRUE, col = cfill, border = "white",
     xlab = "Beta 1 reamostrado (Escolaridade)", ylab = "Densidade",
     main = "Distribuição Bootstrap de Beta 1 (B=2000)")
abline(v = ci_boot, col = claranja, lwd = 2, lty = 2)
abline(v = b1, col = croxo, lwd = 3)
legend("topright", legend = c("Beta 1 MQO", "IC 95% Percentil"),
       col = c(croxo, claranja), lwd = c(3, 2), lty = c(1, 2), bty = "n")
dev.off()

cat("\nFiguras salvas em:", normalizePath(dir_figuras, winslash = "/"), "\n")
cat("Arquivos:", paste(list.files(dir_figuras, pattern = "^03-regressao-linear_img"), collapse = ", "), "\n")

# =============================================================
# Fim do script
# =============================================================
