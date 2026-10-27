# =============================================================
# ATIVIDADE 08 - EXPANSÃO E REGULARIZAÇÃO
# Y: mortalidade_60_69
# Parte A: Expansão socioeconômica (p = 7)
# Parte B: Expansão completa com model.matrix (municipio + factor(ano) + sociais, p = 19)
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

nome_csv <- "df_ipdm_baixada_por_municipio.csv"
candidatos <- c(file.path("..", "bancoDeDados", nome_csv),
                file.path("estrutura", "bancoDeDados", nome_csv),
                nome_csv)
url_github <- "https://raw.githubusercontent.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/main/estrutura/bancoDeDados/df_ipdm_baixada_por_municipio.csv"
achados <- candidatos[file.exists(candidatos)]
origem_dados <- if (length(achados) > 0) achados[1] else url_github

dados_brutos <- read.csv(origem_dados, sep = ";", dec = ",", fileEncoding = "latin1",
                         check.names = FALSE, stringsAsFactors = FALSE)

dados <- data.frame(
  municipio         = factor(dados_brutos[[2]]),
  ano               = as.integer(dados_brutos[[3]]),
  riqueza           = as.numeric(dados_brutos[[4]]),
  escolaridade      = as.numeric(dados_brutos[[6]]),
  mortalidade_60_69 = as.numeric(dados_brutos[[8]]),
  distorcao_em      = as.numeric(dados_brutos[[9]]),
  pib_per_capita    = as.numeric(dados_brutos[[10]])
)
dados$ano_f <- factor(dados$ano)

# Expansão: criar termos polinomiais e interações
dados$escolaridade2   <- dados$escolaridade^2
dados$distorcao_x_esc <- dados$distorcao_em * dados$escolaridade

X <- as.matrix(dados[, c("escolaridade","escolaridade2","distorcao_em",
                         "distorcao_x_esc","pib_per_capita","riqueza","ano")])
y <- dados$mortalidade_60_69
n <- nrow(X); p <- ncol(X)

cazul <- "#276DC3"; claranja <- "#E66101"; croxo <- "#5E3C99"
pastas_fig_candidatas <- c(file.path("estrutura", "scriptsR", "figuras"),
                           "figuras",
                           file.path("..", "scriptsR", "figuras"))
pasta_fig <- "figuras"
for (pf in pastas_fig_candidatas) {
  if (dir.exists(pf) || dir.exists(dirname(pf))) {
    pasta_fig <- pf
    break
  }
}
if (!dir.exists(pasta_fig)) dir.create(pasta_fig, recursive = TRUE)

buffer <- character(0)
add <- function(...) { txt <- paste0(...); cat(txt, "\n"); buffer <<- c(buffer, txt) }
add_print <- function(x) {
  out <- capture.output(print(x)); cat(paste(out, collapse = "\n"), "\n")
  buffer <<- c(buffer, out)
}

# MQO de referência (Bloco Socioeconômico, p = 7)
m_mqo <- lm(mortalidade_60_69 ~ escolaridade + escolaridade2 + distorcao_em +
              distorcao_x_esc + pib_per_capita + riqueza + ano, data = dados)
add(""); add("================ PARTE A: BLOCO SOCIOECONÔMICO (p = 7) ================")
add("MQO R² = ", round(summary(m_mqo)$r.squared, 4),
    " | R² aj = ", round(summary(m_mqo)$adj.r.squared, 4))
add("Correlação entre escolaridade e escolaridade² (colinearidade polinomial): ",
    round(cor(dados$escolaridade, dados$escolaridade2), 4))

set.seed(1)
cv_ridge <- cv.glmnet(X, y, alpha = 0)
cv_lasso <- cv.glmnet(X, y, alpha = 1)
cv_enet  <- cv.glmnet(X, y, alpha = 0.5)

add(""); add("================ CROSS-VALIDATION glmnet (p = 7) ================")
add_print(data.frame(
  Modelo     = c("Ridge (alpha=0)", "ElasticNet (alpha=0.5)", "Lasso (alpha=1)"),
  Lambda_min = round(c(cv_ridge$lambda.min, cv_enet$lambda.min, cv_lasso$lambda.min), 4),
  MSE_min    = round(c(min(cv_ridge$cvm), min(cv_enet$cvm), min(cv_lasso$cvm)), 4),
  Lambda_1se = round(c(cv_ridge$lambda.1se, cv_enet$lambda.1se, cv_lasso$lambda.1se), 4)
))

# Conta explícita da regra de 1 erro-padrão (Aula 08, slide 17/24)
i1_l <- which(cv_lasso$lambda == cv_lasso$lambda.min)
i2_l <- which(cv_lasso$lambda == cv_lasso$lambda.1se)
add(""); add("--- Regra de 1 erro-padrão no Lasso (p = 7) ---")
add_print(round(c(
  CV_min = cv_lasso$cvm[i1_l],
  EP_min = cv_lasso$cvsd[i1_l],
  Limiar_1SE = cv_lasso$cvm[i1_l] + cv_lasso$cvsd[i1_l],
  CV_1se = cv_lasso$cvm[i2_l]
), 4))

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
add(""); add("================ COEFICIENTES (lambda.1se, p = 7) ================")
add("--- Ridge ---"); add_print(round(as.matrix(coef_r), 4))
add(""); add("--- Lasso ---"); add_print(round(as.matrix(coef_l), 4))

sobrev_r <- rownames(coef_r)[as.vector(coef_r) != 0]
sobrev_l <- rownames(coef_l)[as.vector(coef_l) != 0]
add(""); add("Sobreviventes Ridge (p=7): ", paste(sobrev_r, collapse = ", "))
add("Sobreviventes Lasso (p=7): ", paste(sobrev_l, collapse = ", "))

# Teste 70/30 (p = 7)
set.seed(1); idx <- sample(seq_len(n), floor(0.7*n))
Xtr <- X[idx,]; Xte <- X[-idx,]; ytr <- y[idx]; yte <- y[-idx]

pred_mqo <- predict(m_mqo, newdata = dados[-idx,])
cv_l_tr <- cv.glmnet(Xtr, ytr, alpha = 1)
cv_r_tr <- cv.glmnet(Xtr, ytr, alpha = 0)
pred_l <- as.vector(predict(cv_l_tr, Xte, s = "lambda.1se"))
pred_r <- as.vector(predict(cv_r_tr, Xte, s = "lambda.1se"))

rmse <- function(y, yh) sqrt(mean((y - yh)^2))
add(""); add("================ TESTE 70/30 (RMSE, p = 7) ================")
add_print(data.frame(
  Modelo = c("Baseline (média treino)", "MQO", "Ridge (1se)", "Lasso (1se)"),
  RMSE = round(c(rmse(yte, rep(mean(ytr), length(yte))),
                 rmse(yte, pred_mqo), rmse(yte, pred_r), rmse(yte, pred_l)), 4)
))

# =============================================================
# PARTE B: EXPANSÃO COMPLETA COM model.matrix (p = 19)
# Inclui dummies de municipio e factor(ano) + 6 preditores socioeconômicos
# =============================================================
add(""); add("================ PARTE B: EXPANSÃO COMPLETA (model.matrix, p = 19) ================")
X_full <- model.matrix(mortalidade_60_69 ~ municipio + ano_f + riqueza +
                         escolaridade + escolaridade2 + distorcao_em +
                         distorcao_x_esc + pib_per_capita, data = dados)[, -1]
set.seed(1)
cv_l_full <- cv.glmnet(X_full, y, alpha = 1, nfolds = 5)
cv_r_full <- cv.glmnet(X_full, y, alpha = 0, nfolds = 5)
cv_e_full <- cv.glmnet(X_full, y, alpha = 0.5, nfolds = 5)

i1_lf <- which(cv_l_full$lambda == cv_l_full$lambda.min)
i2_lf <- which(cv_l_full$lambda == cv_l_full$lambda.1se)

add_print(data.frame(
  Metodo     = c("Ridge (p=19)", "ElasticNet (p=19)", "Lasso (p=19)"),
  Lambda_min = round(c(cv_r_full$lambda.min, cv_e_full$lambda.min, cv_l_full$lambda.min), 4),
  MSE_CV_min = round(c(min(cv_r_full$cvm), min(cv_e_full$cvm), min(cv_l_full$cvm)), 4),
  RMSE_CV_min= round(sqrt(c(min(cv_r_full$cvm), min(cv_e_full$cvm), min(cv_l_full$cvm))), 4),
  Lambda_1se = round(c(cv_r_full$lambda.1se, cv_e_full$lambda.1se, cv_l_full$lambda.1se), 4),
  MSE_CV_1se = round(c(cv_r_full$cvm[which(cv_r_full$lambda == cv_r_full$lambda.1se)],
                       cv_e_full$cvm[which(cv_e_full$lambda == cv_e_full$lambda.1se)],
                       cv_l_full$cvm[i2_lf]), 4)
))

cl_min <- coef(cv_l_full, s = "lambda.min")
cl_1se <- coef(cv_l_full, s = "lambda.1se")
sobrev_l_min <- round(cl_min[as.vector(cl_min) != 0, , drop = FALSE], 4)
sobrev_l_1se <- round(cl_1se[as.vector(cl_1se) != 0, , drop = FALSE], 4)

add(""); add("--- Sobreviventes do Lasso na Expansão Completa (lambda.min) ---")
add_print(sobrev_l_min)
add(""); add("--- Sobreviventes do Lasso na Expansão Completa (lambda.1se) ---")
add_print(sobrev_l_1se)

add(""); add("[OK] Figuras em: ", pasta_fig)

pastas_out_md <- c(file.path("estrutura", "scriptsR"), ".")
pasta_out_md <- pastas_out_md[dir.exists(pastas_out_md)][1]
arquivo_md <- file.path(pasta_out_md, "08-regularizacao.md")
cabecalho <- c(
  "# Relatório Técnico da Atividade 08 — Regularização",
  "",
  paste0("**Gerado por:** `08-regularizacao.R`  "),
  paste0("**Data:** ", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "  "),
  paste0("**Origem:** `", origem_dados, "`  "),
  "",
  "> **Alvo:** `mortalidade_60_69`. Preditores válidos (excluídos ipdm e longevidade).",
  "",
  "## Sumário executivo",
  "",
  paste0("- Parte A (Socioeconômica): n = ", n, " | p = ", p, " | MQO R² = ", round(summary(m_mqo)$r.squared, 4), " (R² aj = ", round(summary(m_mqo)$adj.r.squared, 4), ")"),
  paste0("- Parte B (Expansão Completa com model.matrix): n = ", n, " | p = ", ncol(X_full), " | Lasso MSE_CV (min) = ", round(min(cv_l_full$cvm), 4), " (RMSE = ", round(sqrt(min(cv_l_full$cvm)), 4), ")"),
  "",
  "## Figuras",
  "",
  paste0("- `", arq1, "` — Curva em U (Lasso)"),
  paste0("- `", arq2, "` — Curva em U (Ridge)"),
  paste0("- `", arq3, "` — Trilhas de coeficientes"),
  "",
  "## Output bruto",
  "", "```", paste(buffer, collapse = "\n"), "```",
  ""
)
writeLines(cabecalho, arquivo_md)
cat("\n[OK] Relatório em:", arquivo_md, "\n")
