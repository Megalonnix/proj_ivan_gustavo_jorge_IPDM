# =============================================================
# ATIVIDADE 04 - REGRESSÃO LOGÍSTICA, CURVA S, ROC E YOUDEN
# =============================================================
# Pergunta: Escolaridade -> IPDM Alto (coluna_binaria)
# Padrão: Prof. Dr. João Paulo Ferreira de Mello (Base R First)
# Carregamento direto via GitHub
# =============================================================

# =============================================================
# PARTE 1 - LER E PREPARAR OS DADOS
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

# Resposta binária: IPDM Alto (1 se acima da mediana regional, 0 caso contrário)
mediana_ipdm <- median(dados$ipdm)
dados$coluna_binaria <- as.integer(dados$ipdm > mediana_ipdm)

y <- dados$coluna_binaria
x <- dados$escolaridade

# Cores oficiais do professor
cazul    <- "#276DC3"
claranja <- "#E66101"
cverde   <- "#2CA02C"
croxo    <- "#5E3C99"

# =============================================================
# PARTE 2 - AJUSTAR O MODELO
# =============================================================
m <- glm(coluna_binaria ~ escolaridade, family = binomial, data = dados)

cat("\n================ RESUMO DO MODELO (coeficientes) ================\n")
printCoefmat(coef(summary(m)), signif.legend = FALSE)

b0 <- coef(m)[1]  # intercepto, na escala do LOGIT
b1 <- coef(m)[2]  # coeficiente de escolaridade, na escala do LOGIT

cat("\n================ EQUAÇÃO DO MODELO (escala do logit) ================\n")
b0_fmt <- format(round(b0, 4), decimal.mark = ",")
b1_fmt <- format(round(b1, 4), decimal.mark = ",")
cat("logit(p) =", b0_fmt, "+", b1_fmt, "\u00d7 escolaridade\n")

# =============================================================
# PARTE 3 - TABELA ILUSTRATIVA: logit -> odds -> p
# =============================================================
escolaridade_exemplo <- c(0.40, 0.50, 0.60)

logit_exemplo <- b0 + b1 * escolaridade_exemplo
odds_exemplo  <- exp(logit_exemplo)
p_exemplo     <- odds_exemplo / (1 + odds_exemplo)

tabela_odds <- data.frame(
  escolaridade = escolaridade_exemplo,
  logit        = round(logit_exemplo, 3),
  odds         = round(odds_exemplo, 3),
  p            = round(p_exemplo, 3)
)

cat("\n================ TABELA: logit, odds e p para 3 valores ================\n")
print(tabela_odds)

# =============================================================
# PARTE 4 - A CURVA S / CURVA LOGÍSTICA
# =============================================================

png(file.path(dir_figuras, "04-regressao-logistica_img1.png"), width = 700, height = 700)
par(mar = c(4, 4, 1, 1), pty = "s")
plot(dados$escolaridade, y, pch = 19, col = "steelblue",
     xlab = "escolaridade", ylab = "P(IPDM Alto = 1)",
     main = "Curva S: probabilidade prevista")
curve(1 / (1 + exp(-(b0 + b1 * x))), add = TRUE, lwd = 3, col = "orange")
abline(h = c(0, 1), col = "gray", lty = 3)

x_estrela <- -b0 / b1  # fronteira de decisão, onde p = 0.5 (slide 8)
abline(v = x_estrela, lty = 2)
dev.off()

cat("\n================ FRONTEIRA DE DECISÃO (onde p = 0.5) ================\n")
cat("Escolaridade =", round(x_estrela, 3), "\n")

# =============================================================
# PARTE 5 - MATRIZ DE CONFUSÃO
# =============================================================
p <- predict(m, type = "response")
yhat <- as.integer(p > 0.5)
tab <- table(real = y, previsto = yhat)

cat("\n================ MATRIZ DE CONFUSÃO (limiar = 0.5) ================\n")
print(tab)

cat("\nAcurácia:", round(mean(yhat == y), 3), "\n")

VP <- tab["1", "1"]; FN <- tab["1", "0"]
FP <- tab["0", "1"]; VN <- tab["0", "0"]

cat("Precisão:      ", round(VP / (VP + FP), 3), "\n")
cat("Recall:        ", round(VP / (VP + FN), 3), "\n")
cat("Especificidade:", round(VN / (VN + FP), 3), "\n")

cat("\n================ MATRIZES NOS LIMIARES 0.3 / 0.5 / 0.7 ================\n")
for (L in c(0.3, 0.5, 0.7)) {
  yh <- as.integer(p > L)
  cat("\n--- limiar =", L, "---\n")
  print(table(real = y, previsto = yh))
}

# =============================================================
# PARTE 6 - CURVA ROC E AUC
# =============================================================
ord <- order(p, decreasing = TRUE)
tpr <- cumsum(y[ord]) / sum(y)
fpr <- cumsum(1 - y[ord]) / sum(1 - y)

png(file.path(dir_figuras, "04-regressao-logistica_img2.png"), width = 700, height = 700)
par(mar = c(4, 4, 1, 1), pty = "s")
plot(c(0, fpr), c(0, tpr), type = "l", lwd = 3,
     col = "orange", xlab = "FPR", ylab = "TPR",
     main = "Curva ROC")
abline(0, 1, lty = 2, col = "gray")

# pontinhos marcando os limiares 0.7 / 0.5 / 0.3 na curva
for (L in c(0.7, 0.5, 0.3)) {
  points(mean(p[y == 0] > L), mean(p[y == 1] > L),
         pch = 19, cex = 1.2, col = "purple")
}

AUC <- mean(outer(p[y == 1], p[y == 0], ">"))
cat("\n================ AUC (área sob a curva ROC) ================\n")
cat("AUC:", round(AUC, 3), "\n")

# =============================================================
# PARTE 7 - ÍNDICE DE YOUDEN
# =============================================================
# Encontra o limiar que maximiza TPR - FPR (o "meio-termo" da curva ROC)
youden <- tpr - fpr
pos_melhor <- which.max(youden)
melhor_limiar <- p[ord][pos_melhor]

points(fpr[pos_melhor], tpr[pos_melhor], pch = 19, cex = 1.3, col = "darkgreen")
text(fpr[pos_melhor] + 0.08, tpr[pos_melhor] - 0.05,
     paste0("Youden\nlimiar=", round(melhor_limiar, 2)), cex = 0.8)
dev.off()

cat("\n================ ÍNDICE DE YOUDEN ================\n")
cat("Melhor limiar:", round(melhor_limiar, 3), "\n")
cat("Nesse ponto -> TPR:", round(tpr[pos_melhor], 3),
    " FPR:", round(fpr[pos_melhor], 3), "\n\n")

yhat_youden <- as.integer(p > melhor_limiar)
tab_youden <- table(real = y, previsto = yhat_youden)
cat("Matriz de confusão no limiar de Youden:\n")
print(tab_youden)

VP_y <- tab_youden["1", "1"]; FN_y <- tab_youden["1", "0"]
FP_y <- tab_youden["0", "1"]; VN_y <- tab_youden["0", "0"]

cat("\nAcurácia:      ", round((VP_y + VN_y) / sum(tab_youden), 3), "\n")
cat("Precisão:      ", round(VP_y / (VP_y + FP_y), 3), "\n")
cat("Recall:        ", round(VP_y / (VP_y + FN_y), 3), "\n")
cat("Especificidade:", round(VN_y / (VN_y + FP_y), 3), "\n")

cat("\nFiguras salvas em:", normalizePath(dir_figuras, winslash = "/"), "\n")
cat("Arquivos:", paste(list.files(dir_figuras, pattern = "^04-regressao-logistica_img"), collapse = ", "), "\n")

# =============================================================
# Fim do script
# =============================================================
