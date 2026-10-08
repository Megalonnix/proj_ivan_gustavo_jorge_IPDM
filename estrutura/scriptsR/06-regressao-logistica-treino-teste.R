# =============================================================
# ATIVIDADE 06 - CLASSIFICAÇÃO: TREINO/TESTE E CV(5)
# Y: mortalidade_alta (binarizada pela mediana DO TREINO)
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
  mortalidade_60_69 = as.numeric(dados_brutos[[8]]),
  distorcao_em      = as.numeric(dados_brutos[[9]])
)

cazul <- "#276DC3"; claranja <- "#E66101"; croxo <- "#5E3C99"
pasta_fig <- "figuras"; if (!dir.exists(pasta_fig)) dir.create(pasta_fig, recursive = TRUE)

buffer <- character(0)
add <- function(...) { txt <- paste0(...); cat(txt, "\n"); buffer <<- c(buffer, txt) }
add_print <- function(x) {
  out <- capture.output(print(x)); cat(paste(out, collapse = "\n"), "\n")
  buffer <<- c(buffer, out)
}

metricas <- function(y, yh) {
  tab <- table(real = factor(y, c(0,1)), prev = factor(yh, c(0,1)))
  acc <- sum(diag(tab))/sum(tab)
  sens <- if(sum(tab["1",])>0) tab["1","1"]/sum(tab["1",]) else NA
  esp  <- if(sum(tab["0",])>0) tab["0","0"]/sum(tab["0",]) else NA
  list(tab=tab, acc=acc, sens=sens, esp=esp)
}
auc_fun <- function(p, y) if (length(unique(y)) < 2) 0.5 else mean(outer(p[y==1], p[y==0], ">"))

set.seed(1); n <- nrow(dados)
idx <- sample(seq_len(n), floor(0.7*n))
treino <- dados[idx, ]; teste <- dados[-idx, ]

mediana_treino <- median(treino$mortalidade_60_69)
treino$y <- as.integer(treino$mortalidade_60_69 > mediana_treino)
teste$y  <- as.integer(teste$mortalidade_60_69  > mediana_treino)

add(""); add("================ BINARIZAÇÃO ================")
add("Mediana (treino): ", round(mediana_treino, 4))
add("Prop. classe 1 treino: ", round(mean(treino$y), 3))
add("Prop. classe 1 teste:  ", round(mean(teste$y), 3))

m_s <- glm(y ~ escolaridade,             data = treino, family = binomial)
m_m <- glm(y ~ escolaridade + distorcao_em, data = treino, family = binomial)

add(""); add("--- A: simples ---"); add_print(round(coef(summary(m_s)), 4))
add("--- B: múltiplo ---"); add_print(round(coef(summary(m_m)), 4))

ps <- predict(m_s, newdata = teste, type = "response")
pm <- predict(m_m, newdata = teste, type = "response")
ys <- as.integer(ps > 0.5); ym <- as.integer(pm > 0.5)

ms <- metricas(teste$y, ys); mm <- metricas(teste$y, ym)
auc_s <- auc_fun(ps, teste$y); auc_m <- auc_fun(pm, teste$y)

add(""); add("================ TESTE (limiar 0.5) ================")
add("--- A ---"); add_print(ms$tab)
add("Acc: ", round(ms$acc, 4), " | Sens: ", round(ms$sens, 4),
    " | Esp: ", round(ms$esp, 4), " | AUC: ", round(auc_s, 4))
add("--- B ---"); add_print(mm$tab)
add("Acc: ", round(mm$acc, 4), " | Sens: ", round(mm$sens, 4),
    " | Esp: ", round(mm$esp, 4), " | AUC: ", round(auc_m, 4))

add(""); add("Matrizes nos limiares 0.3/0.5/0.7:")
for (L in c(0.3, 0.5, 0.7)) {
  add(""); add("--- limiar ", L, " ---")
  add("A:"); add_print(table(real = teste$y, previsto = as.integer(ps > L)))
  add("B:"); add_print(table(real = teste$y, previsto = as.integer(pm > L)))
}

arq1 <- file.path(pasta_fig, "06-regressao-logistica-treino-teste_img1.png")
png(arq1, width = 800, height = 700); par(mar = c(4,4,1,1), pty = "s")
grade <- seq(min(dados$escolaridade), max(dados$escolaridade), length.out = 300)
pred_g <- predict(m_s, newdata = data.frame(escolaridade = grade), type = "response")
plot(teste$escolaridade, teste$y, pch = 19, col = claranja,
     xlab = "Escolaridade", ylab = "P(mortalidade alta)",
     main = "Curva logística (treino) vs teste")
lines(grade, pred_g, col = cazul, lwd = 3); abline(h = 0.5, lty = 2, col = "gray40")
legend("topright", c("Teste","Curva","c = 0.5"),
       col = c(claranja,cazul,"gray40"), pch = c(19,NA,NA),
       lwd = c(NA,3,2), lty = c(NA,1,2), bty = "n")
dev.off()

roc_xy <- function(p, y) {
  o <- order(p, decreasing = TRUE)
  list(fpr = c(0, cumsum(1 - y[o])/sum(1-y)), tpr = c(0, cumsum(y[o])/sum(y)))
}
rs <- roc_xy(ps, teste$y); rm_ <- roc_xy(pm, teste$y)

arq2 <- file.path(pasta_fig, "06-regressao-logistica-treino-teste_img2.png")
png(arq2, width = 800, height = 700); par(mar = c(4,4,1,1), pty = "s")
plot(rs$fpr, rs$tpr, type = "l", lwd = 3, col = cazul, xlim = c(0,1), ylim = c(0,1),
     xlab = "FPR", ylab = "TPR",
     main = sprintf("ROC teste — A vs B (AUC_A=%.3f | AUC_B=%.3f)", auc_s, auc_m))
lines(rm_$fpr, rm_$tpr, lwd = 3, col = croxo)
abline(0, 1, lty = 2, col = "gray50")
legend("bottomright",
       c(sprintf("A (AUC=%.3f)", auc_s), sprintf("B (AUC=%.3f)", auc_m), "Aleatório"),
       col = c(cazul,croxo,"gray50"), lwd = c(3,3,1), lty = c(1,1,2), bty = "n")
dev.off()

# CV
k <- 5; set.seed(1); dobra <- sample(rep(1:k, length = n))
acc_s <- numeric(k); acc_m <- numeric(k); acc_b <- numeric(k)
auc_s_cv <- numeric(k); auc_m_cv <- numeric(k)
for (j in 1:k) {
  tr <- dados[dobra != j, ]; te <- dados[dobra == j, ]
  med_j <- median(tr$mortalidade_60_69)
  tr$y <- as.integer(tr$mortalidade_60_69 > med_j)
  te$y <- as.integer(te$mortalidade_60_69 > med_j)
  m1 <- glm(y ~ escolaridade,               data = tr, family = binomial)
  m2 <- glm(y ~ escolaridade + distorcao_em, data = tr, family = binomial)
  p1 <- predict(m1, newdata = te, type = "response")
  p2 <- predict(m2, newdata = te, type = "response")
  acc_s[j] <- mean((p1 > 0.5) == te$y); acc_m[j] <- mean((p2 > 0.5) == te$y)
  maj <- as.integer(mean(tr$y) >= 0.5); acc_b[j] <- mean(maj == te$y)
  auc_s_cv[j] <- auc_fun(p1, te$y); auc_m_cv[j] <- auc_fun(p2, te$y)
}

add(""); add("================ CV(5) ================")
add_print(data.frame(
  Candidato = c("Baseline","A: simples","B: múltiplo"),
  Acc_pct = round(100*c(mean(acc_b), mean(acc_s), mean(acc_m)), 2),
  AUC = round(c(NA, mean(auc_s_cv), mean(auc_m_cv)), 4)
))
add("Dobras A venceu (AUC): ", sum(auc_s_cv > auc_m_cv), " | B venceu: ", sum(auc_m_cv > auc_s_cv))

add(""); add("[OK] Figuras em: ", pasta_fig)

arquivo_md <- "06-regressao-logistica-treino-teste.md"
venc <- if (mean(auc_s_cv) >= mean(auc_m_cv)) "A: simples" else "B: múltiplo"
cabecalho <- c(
  "# Relatório da Atividade 06 — Classificação",
  "",
  paste0("**Gerado por:** `06-regressao-logistica-treino-teste.R`  "),
  paste0("**Data:** ", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "  "),
  paste0("**Origem:** `", origem_dados, "`  "),
  "",
  "> **Alvo:** `mortalidade_alta` = 1 se mortalidade > mediana do TREINO.",
  "",
  "## Sumário",
  "",
  paste0("- n_treino = ", nrow(treino), " | n_teste = ", nrow(teste)),
  paste0("- Mediana (treino) = ", round(mediana_treino, 4)),
  paste0("- A: Acc = ", round(ms$acc, 4), " | AUC = ", round(auc_s, 4)),
  paste0("- B: Acc = ", round(mm$acc, 4), " | AUC = ", round(auc_m, 4)),
  paste0("- CV(5): Acc_A = ", round(100*mean(acc_s), 2), "% (AUC ",
         round(mean(auc_s_cv), 4), ") | Acc_B = ", round(100*mean(acc_m), 2),
         "% (AUC ", round(mean(auc_m_cv), 4), ")"),
  paste0("- **Vencedor: ", venc, "**"),
  "",
  "## Figuras",
  "",
  paste0("- `", arq1, "` — Curva logística + teste"),
  paste0("- `", arq2, "` — ROC (A vs B)"),
  "",
  "## Output bruto",
  "", "```", paste(buffer, collapse = "\n"), "```",
  "",
  "## Notas",
  "",
  "Mediana recalculada por dobra. Classes ~50/50 por construção.",
  "AUC independente de limiar; melhor critério para escolher entre A e B.",
  ""
)
writeLines(cabecalho, arquivo_md)
cat("\n[OK] Relatório em:", arquivo_md, "\n")