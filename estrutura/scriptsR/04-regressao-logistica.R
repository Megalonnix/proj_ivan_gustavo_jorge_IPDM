# =============================================================
# ATIVIDADE 04 - REGRESSÃO LOGÍSTICA
# Y: mortalidade_alta (mort > mediana)
# =============================================================
if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) {
  caminho_script <- rstudioapi::getSourceEditorContext()$path
  if (nzchar(caminho_script) && dir.exists(dirname(caminho_script))) {
    setwd(dirname(caminho_script))
  }
}

arquivo_local <- file.path("..", "bancoDeDados", "df_ipdm_baixada_por_municipio.csv")
url_github    <- "https://raw.githubusercontent.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/main/estrutura/bancoDeDados/df_ipdm_baixada_por_municipio.csv"

origem_dados <- if (file.exists(arquivo_local)) arquivo_local else url_github
dados_brutos <- read.csv(origem_dados, sep = ";", dec = ",", fileEncoding = "latin1",
                         check.names = FALSE, stringsAsFactors = FALSE)

dados <- data.frame(
  escolaridade      = as.numeric(dados_brutos[[6]]),
  mortalidade_60_69 = as.numeric(dados_brutos[[8]])
)

mediana_mort <- median(dados$mortalidade_60_69)
dados$mortalidade_alta <- as.integer(dados$mortalidade_60_69 > mediana_mort)
y <- dados$mortalidade_alta; x <- dados$escolaridade

cazul <- "#276DC3"; claranja <- "#E66101"; croxo <- "#5E3C99"
pasta_fig <- "figuras"; if (!dir.exists(pasta_fig)) dir.create(pasta_fig, recursive = TRUE)

buffer <- character(0)
add <- function(...) { txt <- paste0(...); cat(txt, "\n"); buffer <<- c(buffer, txt) }
add_print <- function(x) {
  out <- capture.output(print(x)); cat(paste(out, collapse = "\n"), "\n")
  buffer <<- c(buffer, out)
}

m <- glm(mortalidade_alta ~ escolaridade, family = binomial, data = dados)
add(""); add("================ MODELO LOGÍSTICO ================")
out <- capture.output(printCoefmat(coef(summary(m)), signif.legend = FALSE))
cat(paste(out, collapse = "\n"), "\n"); buffer <- c(buffer, out)

b0 <- coef(m)[1]; b1 <- coef(m)[2]
add("Equação (logit): ", round(b0, 4), " + ", round(b1, 4), " × escolaridade")
add("Razão de chances exp(β1) = ", round(exp(b1), 4))
add("Interpretação: cada +1 em escolaridade multiplica a chance de",
    "mortalidade alta por ", round(exp(b1), 4), ".")

esc_ex <- c(0.40, 0.50, 0.60)
logit_ex <- b0 + b1 * esc_ex
odds_ex  <- exp(logit_ex); p_ex <- odds_ex / (1 + odds_ex)
add(""); add("Tabela logit/odds/p:")
add_print(data.frame(escolaridade = esc_ex, logit = round(logit_ex, 3),
                     odds = round(odds_ex, 3), p = round(p_ex, 3)))

x_estrela <- -b0 / b1
add("Fronteira de decisão (p = 0.5): x* = ", round(x_estrela, 3))

arq1 <- file.path(pasta_fig, "04-regressao-logistica_img1.png")
png(arq1, width = 800, height = 700); par(mar = c(4,4,1,1), pty = "s")
plot(dados$escolaridade, y, pch = 19, col = "steelblue",
     xlab = "Escolaridade", ylab = "P(mortalidade alta)",
     main = "Curva S: probabilidade prevista")
curve(1 / (1 + exp(-(b0 + b1 * x))), add = TRUE, lwd = 3, col = "orange")
abline(h = c(0,1), col = "gray", lty = 3)
abline(v = x_estrela, lty = 2)
dev.off()

p <- predict(m, type = "response"); yhat <- as.integer(p > 0.5)
tab <- table(real = y, previsto = yhat)
add(""); add("Matriz de confusão (0.5):"); add_print(tab)
VP <- tab["1","1"]; FN <- tab["1","0"]; FP <- tab["0","1"]; VN <- tab["0","0"]
add("Acurácia: ", round(mean(yhat == y), 3))
add("Precisão: ", round(VP/(VP+FP), 3))
add("Recall:   ", round(VP/(VP+FN), 3))
add("Espec.:   ", round(VN/(VN+FP), 3))

add(""); add("Matrizes nos limiares 0.3 / 0.5 / 0.7:")
for (L in c(0.3, 0.5, 0.7)) {
  add(""); add("--- limiar ", L, " ---")
  add_print(table(real = y, previsto = as.integer(p > L)))
}

ord <- order(p, decreasing = TRUE)
tpr <- cumsum(y[ord]) / sum(y)
fpr <- cumsum(1 - y[ord]) / sum(1 - y)
AUC <- mean(outer(p[y==1], p[y==0], ">"))

arq2 <- file.path(pasta_fig, "04-regressao-logistica_img2.png")
png(arq2, width = 700, height = 700); par(mar = c(4,4,1,1), pty = "s")
plot(c(0,fpr), c(0,tpr), type = "l", lwd = 3, col = "orange", xlab = "FPR", ylab = "TPR",
     main = "Curva ROC")
abline(0, 1, lty = 2, col = "gray")
for (L in c(0.7, 0.5, 0.3))
  points(mean(p[y==0] > L), mean(p[y==1] > L), pch = 19, cex = 1.2, col = "purple")
dev.off()

add(""); add("AUC: ", round(AUC, 3))

youden <- tpr - fpr; pos <- which.max(youden); melhor <- p[ord][pos]
add(""); add("Youden — limiar: ", round(melhor, 3),
             " | TPR: ", round(tpr[pos], 3), " | FPR: ", round(fpr[pos], 3))

yhat_y <- as.integer(p > melhor)
tab_y <- table(real = y, previsto = yhat_y); add_print(tab_y)

add(""); add("[OK] Figuras gravadas em: ", pasta_fig)

arquivo_md <- "04-regressao-logistica.md"
cabecalho <- c(
  "# Relatório da Atividade 04 — Regressão Logística",
  "",
  paste0("**Gerado por:** `04-regressao-logistica.R`  "),
  paste0("**Data:** ", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "  "),
  paste0("**Origem:** `", origem_dados, "`  "),
  "",
  "> **Alvo binário:** `mortalidade_alta` = 1 se mortalidade_60_69 > mediana.",
  "",
  "## Sumário",
  "",
  paste0("- Mediana = ", round(mediana_mort, 4)),
  paste0("- logit(p) = ", round(b0,4), " + ", round(b1,4), " × escolaridade"),
  paste0("- exp(β1) = ", round(exp(b1), 4)),
  paste0("- x* (p = 0.5) = ", round(x_estrela, 3)),
  paste0("- Acurácia (0.5) = ", round(mean(yhat == y), 3), " | AUC = ", round(AUC, 3)),
  paste0("- Youden = ", round(melhor, 3)),
  "",
  "## Figuras",
  "",
  paste0("- `", arq1, "` — Curva sigmoide"),
  paste0("- `", arq2, "` — ROC"),
  "",
  "## Output bruto",
  "", "```", paste(buffer, collapse = "\n"), "```",
  "",
  "## Notas",
  "",
  "exp(β1) > 1 indica que escolaridade AUMENTA a chance de mortalidade alta;",
  "exp(β1) < 1 indica que escolaridade PROTEGE (reduz a chance).",
  "O sinal esperado substantivamente é de proteção (exp(β1) < 1).",
  ""
)
writeLines(cabecalho, arquivo_md)
cat("\n[OK] Relatório gravado em:", arquivo_md, "\n")