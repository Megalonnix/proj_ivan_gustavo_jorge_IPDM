# =============================================================
# ATIVIDADE 05 - AVALIAÇÃO DE REGRESSÃO: TREINO/TESTE E CV(5)
# Y: mortalidade_60_69
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

cazul <- "#276DC3"; claranja <- "#E66101"; croxo <- "#5E3C99"; cfill <- "#E0E7FF"
pasta_fig <- "figuras"; if (!dir.exists(pasta_fig)) dir.create(pasta_fig, recursive = TRUE)

buffer <- character(0)
add <- function(...) { txt <- paste0(...); cat(txt, "\n"); buffer <<- c(buffer, txt) }
add_print <- function(x) {
  out <- capture.output(print(x)); cat(paste(out, collapse = "\n"), "\n")
  buffer <<- c(buffer, out)
}
rmse_fun <- function(y, yh) sqrt(mean((y - yh)^2))
mae_fun  <- function(y, yh) mean(abs(y - yh))
r2_fun   <- function(y, yh) 1 - sum((y - yh)^2) / sum((y - mean(y))^2)

set.seed(1); n <- nrow(dados)
idx <- sample(seq_len(n), floor(0.7 * n))
treino <- dados[idx, ]; teste <- dados[-idx, ]

m_s <- lm(mortalidade_60_69 ~ escolaridade,             data = treino)
m_m <- lm(mortalidade_60_69 ~ escolaridade + distorcao_em, data = treino)

add(""); add("================ MODELOS (TREINO) ================")
add("--- A: simples ---"); add_print(round(coef(summary(m_s)), 4))
add("--- B: múltiplo ---"); add_print(round(coef(summary(m_m)), 4))

ps <- predict(m_s, newdata = teste)
pm <- predict(m_m, newdata = teste)
pb <- rep(mean(treino$mortalidade_60_69), nrow(teste))

add(""); add("================ TESTE (n = ", nrow(teste), ") ================")
add_print(data.frame(
  Candidato = c("Baseline","A: simples","B: múltiplo"),
  RMSE = round(c(rmse_fun(teste$mortalidade_60_69, pb),
                 rmse_fun(teste$mortalidade_60_69, ps),
                 rmse_fun(teste$mortalidade_60_69, pm)), 4),
  MAE  = round(c(mae_fun(teste$mortalidade_60_69, pb),
                 mae_fun(teste$mortalidade_60_69, ps),
                 mae_fun(teste$mortalidade_60_69, pm)), 4),
  R2   = c(NA, round(r2_fun(teste$mortalidade_60_69, ps), 4),
           round(r2_fun(teste$mortalidade_60_69, pm), 4))
))

arq1 <- file.path(pasta_fig, "05-regressao-linear-treino-teste_img1.png")
png(arq1, width = 800, height = 700); par(mar = c(4,4,1,1), pty = "s")
plot(treino$escolaridade, treino$mortalidade_60_69, col = "gray60", pch = 16,
     xlab = "Escolaridade", ylab = "Mortalidade",
     main = "Treino (simples) vs Teste")
points(teste$escolaridade, teste$mortalidade_60_69, col = claranja, pch = 19)
abline(m_s, col = cazul, lwd = 3)
legend("topright", c("Treino","Teste","Reta"),
       col = c("gray60",claranja,cazul), pch = c(16,19,NA),
       lwd = c(NA,NA,3), lty = c(NA,NA,1), bty = "n")
dev.off()

arq2 <- file.path(pasta_fig, "05-regressao-linear-treino-teste_img2.png")
png(arq2, width = 800, height = 700); par(mar = c(4,4,1,1), pty = "s")
rng <- range(c(teste$mortalidade_60_69, ps, pm))
plot(teste$mortalidade_60_69, ps, col = cazul, pch = 19, xlim = rng, ylim = rng,
     xlab = "Real", ylab = "Previsto", main = "Previsto vs Real (A vs B)")
points(teste$mortalidade_60_69, pm, col = croxo, pch = 17)
abline(0, 1, lty = 2, col = claranja, lwd = 2)
legend("topleft", c("A: simples","B: múltiplo","y = x"),
       col = c(cazul,croxo,claranja), pch = c(19,17,NA),
       lwd = c(NA,NA,2), lty = c(NA,NA,2), bty = "n")
dev.off()

k <- 5; set.seed(1); dobra <- sample(rep(1:k, length = n))
e_s <- numeric(k); e_m <- numeric(k); e_b <- numeric(k)
for (j in 1:k) {
  tr <- dados[dobra != j, ]; te <- dados[dobra == j, ]
  m1 <- lm(mortalidade_60_69 ~ escolaridade, data = tr)
  m2 <- lm(mortalidade_60_69 ~ escolaridade + distorcao_em, data = tr)
  e_s[j] <- mean((te$mortalidade_60_69 - predict(m1, newdata = te))^2)
  e_m[j] <- mean((te$mortalidade_60_69 - predict(m2, newdata = te))^2)
  e_b[j] <- mean((te$mortalidade_60_69 - mean(tr$mortalidade_60_69))^2)
}
cv_s <- sqrt(mean(e_s)); cv_m <- sqrt(mean(e_m)); cv_b <- sqrt(mean(e_b))

add(""); add("================ CV(5) ================")
add_print(data.frame(Candidato = c("Baseline","A: simples","B: múltiplo"),
                     RMSE_CV = round(c(cv_b, cv_s, cv_m), 4)))
add("sd(Y) = ", round(sd(dados$mortalidade_60_69), 4))
add("Dobras A venceu: ", sum(e_s < e_m), " | B venceu: ", sum(e_m < e_s))

set.seed(1)
av_s <- replicate(200, {
  i <- sample(n, floor(0.7*n)); ma <- lm(mortalidade_60_69 ~ escolaridade, data = dados[i,])
  mean((dados$mortalidade_60_69[-i] - predict(ma, newdata = dados[-i,]))^2)
})
av_m <- replicate(200, {
  i <- sample(n, floor(0.7*n)); ma <- lm(mortalidade_60_69 ~ escolaridade + distorcao_em, data = dados[i,])
  mean((dados$mortalidade_60_69[-i] - predict(ma, newdata = dados[-i,]))^2)
})

arq3 <- file.path(pasta_fig, "05-regressao-linear-treino-teste_img3.png")
png(arq3, width = 800, height = 700); par(mar = c(4,4,1,1), pty = "s")
hist(av_s, breaks = 20, prob = TRUE, col = cfill, border = "white",
     xlab = "MSE de teste", ylab = "Densidade", main = "Volatilidade (200 splits)")
abline(v = mean(av_s), col = cazul,    lwd = 3)
abline(v = mean(av_m), col = croxo,    lwd = 3, lty = 2)
abline(v = cv_s^2,     col = claranja, lwd = 3, lty = 3)
legend("topright", c("Média A","Média B","CV(5) A"),
       col = c(cazul,croxo,claranja), lwd = 3, lty = c(1,2,3), bty = "n")
dev.off()

add(""); add("[OK] Figuras em: ", pasta_fig)

arquivo_md <- "05-regressao-linear-treino-teste.md"
venc <- if (cv_s < cv_m) "A: simples" else "B: múltiplo"
cabecalho <- c(
  "# Relatório da Atividade 05 — Treino/Teste e CV(5)",
  "",
  paste0("**Gerado por:** `05-regressao-linear-treino-teste.R`  "),
  paste0("**Data:** ", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "  "),
  paste0("**Origem:** `", origem_dados, "`  "),
  "",
  "> **Alvo:** `mortalidade_60_69`. Unidade: mortes por mil hab.",
  "",
  "## Sumário executivo",
  "",
  paste0("- n_treino = ", nrow(treino), " | n_teste = ", nrow(teste)),
  paste0("- A (simples)  RMSE_teste = ", round(rmse_fun(teste$mortalidade_60_69, ps), 4)),
  paste0("- B (múltiplo) RMSE_teste = ", round(rmse_fun(teste$mortalidade_60_69, pm), 4)),
  paste0("- A CV(5) = ", round(cv_s, 4), " | B CV(5) = ", round(cv_m, 4)),
  paste0("- **Vencedor: ", venc, "**"),
  paste0("- sd(Y) = ", round(sd(dados$mortalidade_60_69), 4)),
  "",
  "## Figuras",
  "",
  paste0("- `", arq1, "` — Treino + teste"),
  paste0("- `", arq2, "` — Previsto vs Real (A vs B)"),
  paste0("- `", arq3, "` — Volatilidade do MSE"),
  "",
  "## Output bruto",
  "", "```", paste(buffer, collapse = "\n"), "```",
  "",
  "## Notas",
  "",
  "RMSE em mortes por mil hab. A média de referência do baseline é a do TREINO.",
  ""
)
writeLines(cabecalho, arquivo_md)
cat("\n[OK] Relatório em:", arquivo_md, "\n")