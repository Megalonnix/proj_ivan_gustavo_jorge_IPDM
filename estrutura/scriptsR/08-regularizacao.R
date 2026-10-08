# =============================================================
# ATIVIDADE 08 - EXPANSÃO E REGULARIZAÇÃO
# Y: mortalidade_60_69
# =============================================================
if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) {
  caminho_script <- rstudioapi::getSourceEditorContext()$path
  if (nzchar(caminho_script) && dir.exists(dirname(caminho_script))) {
    setwd(dirname(caminho_script))
  }
}

if (!requireNamespace("glmnet", quietly = TRUE)) {
  stop("Instale o pacote glmnet: install.packages('glmnet')")
}
library(glmnet)

arquivo_local <- file.path("..", "bancoDeDados", "df_ipdm_baixada_por_municipio.csv")
url_github    <- "https://raw.githubusercontent.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/main/estrutura/bancoDeDados/df_ipdm_baixada_por_municipio.csv"
origem_dados <- if (file.exists(arquivo_local)) arquivo_local else url_github

dados_brutos <- read.csv(origem_dados, sep = ";", dec = ",", fileEncoding = "latin1",
                         check.names = FALSE, stringsAsFactors = FALSE)

dados <- data.frame(
  ano               = as.integer(dados_brutos[[3]]),
  riqueza           = as.numeric(dados_brutos[[4]]),
  escolaridade      = as.numeric(dados_brutos[[6]]),
  mortalidade_60_69 = as.numeric(dados_brutos[[8]]),
  distorcao_em      = as.numeric(dados_brutos[[9]]),
  pib_per_capita    = as.numeric(dados_brutos[[10]])
)

# Expansão: criar termos polinomiais e interações
dados$escolaridade2 <- dados$escolaridade^2
dados$distorcao_x_esc <- dados$distorcao_em * dados$escolaridade

X <- as.matrix(dados[, c("escolaridade","escolaridade2","distorcao_em",
                         "distorcao_x_esc","pib_per_capita","riqueza","ano")])
y <- dados$mortalidade_60_69
n <- nrow(X); p <- ncol(X)

cazul <- "#276DC3"; claranja <- "#E66101"; croxo <- "#5E3C99"
pasta_fig <- "figuras"; if (!dir.exists(pasta_fig)) dir.create(pasta_fig, recursive = TRUE)

buffer <- character(0)
add <- function(...) { txt <- paste0(...); cat(txt, "\n"); buffer <<- c(buffer, txt) }
add_print <- function(x) {
  out <- capture.output(print(x)); cat(paste(out, collapse = "\n"), "\n")
  buffer <<- c(buffer, out)
}

# MQO de referência
m_mqo <- lm(mortalidade_60_69 ~ escolaridade + escolaridade2 + distorcao_em +
              distorcao_x_esc + pib_per_capita + riqueza + ano, data = dados)
add(""); add("================ MQO DE REFERÊNCIA ================")
add("R² = ", round(summary(m_mqo)$r.squared, 4),
    " | R² aj = ", round(summary(m_mqo)$adj.r.squared, 4))

set.seed(1)
cv_ridge <- cv.glmnet(X, y, alpha = 0)
cv_lasso <- cv.glmnet(X, y, alpha = 1)
cv_enet  <- cv.glmnet(X, y, alpha = 0.5)

add(""); add("================ CROSS-VALIDATION glmnet ================")
add_print(data.frame(
  Modelo = c("Ridge (α=0)", "ElasticNet (α=0.5)", "Lasso (α=1)"),
  Lambda_min = round(c(cv_ridge$lambda.min, cv_enet$lambda.min, cv_lasso$lambda.min), 4),
  MSE_min    = round(c(min(cv_ridge$cvm), min(cv_enet$cvm), min(cv_lasso$cvm)), 4),
  Lambda_1se = round(c(cv_ridge$lambda.1se, cv_enet$lambda.1se, cv_lasso$lambda.1se), 4)
))

arq1 <- file.path(pasta_fig, "08-regularizacao_img1.png")
png(arq1, width = 800, height = 700); par(mar = c(4,4,2,1), pty = "s")
plot(cv_lasso); title("Curva em U — Lasso", line = 2.2)
dev.off()

arq2 <- file.path(pasta_fig, "08-regularizacao_img2.png")
png(arq2, width = 800, height = 700); par(mar = c(4,4,2,1), pty = "s")
plot(cv_ridge); title("Curva em U — Ridge", line = 2.2)
dev.off()

m_ridge_path <- glmnet(X, y, alpha = 0)
m_lasso_path <- glmnet(X, y, alpha = 1)

arq3 <- file.path(pasta_fig, "08-regularizacao_img3.png")
png(arq3, width = 1100, height = 700)
par(mfrow = c(1,2), mar = c(4,4,2,1), pty = "s")
plot(m_ridge_path, xvar = "lambda"); title("Ridge (L2)", line = 2.2)
plot(m_lasso_path, xvar = "lambda"); title("Lasso (L1)", line = 2.2)
dev.off()

coef_r <- coef(cv_ridge, s = "lambda.1se")
coef_l <- coef(cv_lasso, s = "lambda.1se")
add(""); add("================ COEFICIENTES (λ.1se) ================")
add("--- Ridge ---"); add_print(round(as.matrix(coef_r), 4))
add(""); add("--- Lasso ---"); add_print(round(as.matrix(coef_l), 4))

sobrev_r <- rownames(coef_r)[as.vector(coef_r) != 0]
sobrev_l <- rownames(coef_l)[as.vector(coef_l) != 0]
add(""); add("Sobreviventes Ridge: ", paste(sobrev_r, collapse = ", "))
add("Sobreviventes Lasso: ", paste(sobrev_l, collapse = ", "))

# Teste 70/30
set.seed(1); idx <- sample(seq_len(n), floor(0.7*n))
Xtr <- X[idx,]; Xte <- X[-idx,]; ytr <- y[idx]; yte <- y[-idx]

pred_mqo <- predict(m_mqo, newdata = dados[-idx,])
cv_l_tr <- cv.glmnet(Xtr, ytr, alpha = 1)
cv_r_tr <- cv.glmnet(Xtr, ytr, alpha = 0)
pred_l <- as.vector(predict(cv_l_tr, Xte, s = "lambda.1se"))
pred_r <- as.vector(predict(cv_r_tr, Xte, s = "lambda.1se"))

rmse <- function(y, yh) sqrt(mean((y - yh)^2))
add(""); add("================ TESTE (RMSE) ================")
add_print(data.frame(
  Modelo = c("Baseline (média treino)", "MQO", "Ridge (1se)", "Lasso (1se)"),
  RMSE = round(c(rmse(yte, rep(mean(ytr), length(yte))),
                 rmse(yte, pred_mqo), rmse(yte, pred_r), rmse(yte, pred_l)), 4)
))

add(""); add("[OK] Figuras em: ", pasta_fig)

arquivo_md <- "08-regularizacao.md"
cabecalho <- c(
  "# Relatório da Atividade 08 — Regularização",
  "",
  paste0("**Gerado por:** `08-regularizacao.R`  "),
  paste0("**Data:** ", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "  "),
  paste0("**Origem:** `", origem_dados, "`  "),
  "",
  "> **Alvo:** `mortalidade_60_69`. Predictores válidos (excluídos ipdm e longevidade).",
  "",
  "## Sumário executivo",
  "",
  paste0("- n = ", n, " | p = ", p, " (com expansão polinomial)"),
  paste0("- MQO: R² = ", round(summary(m_mqo)$r.squared, 4),
         " | R² aj = ", round(summary(m_mqo)$adj.r.squared, 4)),
  "",
  "### CV-glmnet (λ.1se)",
  paste0("- Ridge: λ = ", round(cv_ridge$lambda.1se, 4)),
  paste0("- ENet : λ = ", round(cv_enet$lambda.1se, 4)),
  paste0("- Lasso: λ = ", round(cv_lasso$lambda.1se, 4)),
  "",
  "### Sobreviventes",
  paste0("- Ridge: ", paste(sobrev_r, collapse = ", ")),
  paste0("- Lasso: ", paste(sobrev_l, collapse = ", ")),
  "",
  "## Figuras",
  "",
  paste0("- `", arq1, "` — Curva em U (Lasso)"),
  paste0("- `", arq2, "` — Curva em U (Ridge)"),
  paste0("- `", arq3, "` — Trilhas de coeficientes"),
  "",
  "## Output bruto",
  "", "```", paste(buffer, collapse = "\n"), "```",
  "",
  "## Notas",
  "",
  "Ridge encolhe sem zerar; Lasso zera e faz seleção.",
  "Regra do 1 SE: preferir λ.1se (mais parcimonioso, perda dentro do ruído).",
  ""
)
writeLines(cabecalho, arquivo_md)
cat("\n[OK] Relatório em:", arquivo_md, "\n")