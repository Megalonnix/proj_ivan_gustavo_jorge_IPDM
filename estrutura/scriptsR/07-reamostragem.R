# =============================================================
# ATIVIDADE 07 - REAMOSTRAGEM (CV + BOOTSTRAP)
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
  mortalidade_60_69 = as.numeric(dados_brutos[[8]])
)

cazul <- "#276DC3"; claranja <- "#E66101"; croxo <- "#5E3C99"; cfill <- "#E0E7FF"
pasta_fig <- "figuras"; if (!dir.exists(pasta_fig)) dir.create(pasta_fig, recursive = TRUE)

buffer <- character(0)
add <- function(...) { txt <- paste0(...); cat(txt, "\n"); buffer <<- c(buffer, txt) }
add_print <- function(x) {
  out <- capture.output(print(x)); cat(paste(out, collapse = "\n"), "\n")
  buffer <<- c(buffer, out)
}

n <- nrow(dados); k <- 5
mse_fun <- function(y, yh) mean((y - yh)^2)

cv_grau <- function(g, k = 5, seed = 1) {
  set.seed(seed)
  d <- sample(rep(1:k, length = n))
  errs <- sapply(1:k, function(j) {
    tr <- dados[d != j, ]; te <- dados[d == j, ]
    m  <- lm(mortalidade_60_69 ~ poly(escolaridade, g), data = tr)
    mse_fun(te$mortalidade_60_69, predict(m, newdata = te))
  })
  list(mean = mean(errs), dobras = errs)
}

graus <- c(1, 3, 12)
cvs <- lapply(graus, cv_grau); names(cvs) <- paste0("grau_", graus)

add(""); add("================ CV(5) — GRAUS 1, 3, 12 ================")
add_print(data.frame(
  Candidato = names(cvs),
  RMSE_CV = round(sqrt(sapply(cvs, `[[`, "mean")), 4)
))
add("sd(Y) = ", round(sd(dados$mortalidade_60_69), 4))

add(""); add("--- Erro por dobra ---")
tab_dobras <- data.frame(Dobra = 1:k)
for (i in seq_along(graus)) tab_dobras[[names(cvs)[i]]] <- round(sqrt(cvs[[i]]$dobras), 4)
add_print(tab_dobras)

set.seed(1)
curvas_av <- lapply(1:6, function(r) {
  d <- sample(rep(1:k, length = n))
  sapply(graus, function(g) {
    errs <- sapply(1:k, function(j) {
      tr <- dados[d != j, ]; te <- dados[d == j, ]
      m  <- lm(mortalidade_60_69 ~ poly(escolaridade, g), data = tr)
      mse_fun(te$mortalidade_60_69, predict(m, newdata = te))
    })
    mean(errs)
  })
})

arq1 <- file.path(pasta_fig, "07-reamostragem_img1.png")
png(arq1, width = 800, height = 700); par(mar = c(4,4,1,1), pty = "s")
ymax <- max(sqrt(unlist(curvas_av))) * 1.05
plot(seq_along(graus), sqrt(sapply(cvs, `[[`, "mean")), type = "l", lwd = 3, col = croxo,
     ylim = c(0, ymax), xaxt = "n", xlab = "Grau do polinômio", ylab = "MSE",
     main = "6 splits avulsos vs CV(5)")
axis(1, at = seq_along(graus), labels = paste0("grau ", graus))
for (r in seq_along(curvas_av))
  lines(seq_along(graus), sqrt(curvas_av[[r]]), col = "gray70", lwd = 1.5)
lines(seq_along(graus), sqrt(sapply(cvs, `[[`, "mean")), col = croxo, lwd = 3)
legend("topright", c("6 splits avulsos","CV(5)"),
       col = c("gray70", croxo), lwd = c(1.5, 3), bty = "n")
dev.off()

# Bootstrap de β1
B <- 2000; set.seed(1)
b1_boot <- replicate(B, {
  i <- sample(n, n, replace = TRUE)
  coef(lm(mortalidade_60_69 ~ escolaridade, data = dados[i, ]))["escolaridade"]
})
m_orig <- lm(mortalidade_60_69 ~ escolaridade, data = dados)
b1_hat <- coef(m_orig)["escolaridade"]
se_class <- summary(m_orig)$coef["escolaridade", "Std. Error"]
se_boot <- sd(b1_boot)
ci_boot <- quantile(b1_boot, c(0.025, 0.975))
ci_class <- confint(m_orig)["escolaridade", ]

add(""); add("================ BOOTSTRAP β1 ================")
add("β1 MQO:       ", round(b1_hat, 4))
add("EP analítico: ", round(se_class, 4))
add("EP bootstrap: ", round(se_boot, 4))
add("IC 95% analítico: [", round(ci_class[1], 4), "; ", round(ci_class[2], 4), "]")
add("IC 95% bootstrap: [", round(ci_boot[1], 4), "; ", round(ci_boot[2], 4), "]")
add("0 dentro do IC bootstrap? ",
    ifelse(ci_boot[1] <= 0 && 0 <= ci_boot[2], "SIM", "NÃO"))

arq2 <- file.path(pasta_fig, "07-reamostragem_img2.png")
png(arq2, width = 700, height = 700); par(mar = c(4,4,1,1), pty = "s")
hist(b1_boot, breaks = 30, prob = TRUE, col = cfill, border = "white",
     xlab = "β1 reamostrado", ylab = "Densidade", main = "Bootstrap β1")
abline(v = ci_boot, col = claranja, lwd = 2, lty = 2)
abline(v = b1_hat, col = croxo, lwd = 3)
legend("topright", c("β1 MQO","IC 95%"),
       col = c(croxo,claranja), lwd = c(3,2), lty = c(1,2), bty = "n")
dev.off()

add(""); add("[OK] Figuras em: ", pasta_fig)

arquivo_md <- "07-reamostragem.md"
cabecalho <- c(
  "# Relatório da Atividade 07 — Reamostragem",
  "",
  paste0("**Gerado por:** `07-reamostragem.R`  "),
  paste0("**Data:** ", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "  "),
  paste0("**Origem:** `", origem_dados, "`  "),
  "",
  "> **Alvo:** `mortalidade_60_69`. Predictor: `escolaridade`.",
  "",
  "## Sumário executivo",
  "",
  "### CV(5) — candidatos polinomiais",
  paste0("- Grau 1:  RMSE_CV = ", round(sqrt(cvs$grau_1$mean), 4)),
  paste0("- Grau 3:  RMSE_CV = ", round(sqrt(cvs$grau_3$mean), 4)),
  paste0("- Grau 12: RMSE_CV = ", round(sqrt(cvs$grau_12$mean), 4)),
  paste0("- Baseline (sd Y) = ", round(sd(dados$mortalidade_60_69), 4)),
  "",
  "### Bootstrap β1",
  paste0("- β1 MQO = ", round(b1_hat, 4)),
  paste0("- EP analítico = ", round(se_class, 4), " | EP bootstrap = ", round(se_boot, 4)),
  paste0("- IC 95% analítico = [", round(ci_class[1], 4), "; ", round(ci_class[2], 4), "]"),
  paste0("- IC 95% bootstrap = [", round(ci_boot[1], 4), "; ", round(ci_boot[2], 4), "]"),
  paste0("- 0 dentro do IC bootstrap? ",
         ifelse(ci_boot[1] <= 0 && 0 <= ci_boot[2], "SIM", "NÃO")),
  "",
  "## Figuras",
  "",
  paste0("- `", arq1, "` — Volatilidade: splits avulsos vs CV(5)"),
  paste0("- `", arq2, "` — Distribuição bootstrap de β1"),
  "",
  "## Output bruto",
  "", "```", paste(buffer, collapse = "\n"), "```",
  "",
  "## Notas",
  "",
  "CV(5) reaproveita cada observação (treinada 4×, testada 1×).",
  "Bootstrap não-paramétrico, B = 2000, sem hipótese de normalidade.",
  ""
)
writeLines(cabecalho, arquivo_md)
cat("\n[OK] Relatório em:", arquivo_md, "\n")