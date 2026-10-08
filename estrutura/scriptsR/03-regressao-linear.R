# =============================================================
# ATIVIDADE 03 - REGRESSÃO LINEAR, RESÍDUOS, MÚLTIPLA E BOOTSTRAP
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
  ano               = as.integer(dados_brutos[[3]]),
  riqueza           = as.numeric(dados_brutos[[4]]),
  escolaridade      = as.numeric(dados_brutos[[6]]),
  mortalidade_60_69 = as.numeric(dados_brutos[[8]]),
  distorcao_em      = as.numeric(dados_brutos[[9]]),
  pib_per_capita    = as.numeric(dados_brutos[[10]])
)

y <- dados$mortalidade_60_69
x <- dados$escolaridade

cazul <- "#276DC3"; claranja <- "#E66101"; cverde <- "#2CA02C"
croxo <- "#5E3C99"; cfill <- "#E0E7FF"
pasta_fig <- "figuras"; if (!dir.exists(pasta_fig)) dir.create(pasta_fig, recursive = TRUE)

buffer <- character(0)
add <- function(...) { txt <- paste0(...); cat(txt, "\n"); buffer <<- c(buffer, txt) }
add_print <- function(x) {
  out <- capture.output(print(x)); cat(paste(out, collapse = "\n"), "\n")
  buffer <<- c(buffer, out)
}

# ----- Simples -----
m <- lm(mortalidade_60_69 ~ escolaridade, data = dados)
s <- summary(m); ci <- confint(m)
add(""); add("================ MODELO SIMPLES ================")
out <- capture.output(printCoefmat(coef(s), signif.legend = FALSE))
cat(paste(out, collapse = "\n"), "\n"); buffer <- c(buffer, out)
b0 <- coef(m)[1]; b1 <- coef(m)[2]
add(""); add("Equação: mortalidade = ", round(b0, 4), " + ", round(b1, 4), " × escolaridade")
add("IC 95%:"); add_print(ci)
add("R² = ", round(s$r.squared, 4), " | R² aj = ", round(s$adj.r.squared, 4),
    " | RSE = ", round(s$sigma, 4))
add("Interpretação: cada +1 em escolaridade muda a mortalidade em ", round(b1, 4),
    " mortes por mil hab. (sinal ",
    ifelse(b1 < 0, "negativo — mais educação, menos mortalidade",
           "positivo"), ").")

esc_ex <- c(0.35, 0.45, 0.55, 0.65)
pred_ex <- predict(m, newdata = data.frame(escolaridade = esc_ex))
add(""); add("Previsões:")
add_print(data.frame(escolaridade = esc_ex, mortalidade_prev = round(pred_ex, 3)))

# Gráficos simples
arq1 <- file.path(pasta_fig, "03-regressao-linear_img1.png")
png(arq1, width = 700, height = 700); par(mar = c(4,4,1,1), pty = "s")
plot(x, y, pch = 19, col = cazul,
     xlab = "Escolaridade", ylab = "Mortalidade 60–69", main = "MQO + Resíduos")
abline(m, col = claranja, lwd = 3); segments(x, y, x, fitted(m), col = cverde, lwd = 1.2)
legend("topright", c("Obs.","Reta","Resíduos"),
       col = c(cazul,claranja,cverde), pch = c(19,NA,NA),
       lwd = c(NA,3,1.2), lty = c(NA,1,1), bty = "n")
dev.off()

arq2 <- file.path(pasta_fig, "03-regressao-linear_img2.png")
png(arq2, width = 700, height = 700); par(mar = c(4,4,1,1), pty = "s")
plot(fitted(m), resid(m), pch = 19, col = cazul,
     xlab = "Ajustados", ylab = "Resíduos", main = "Resíduos vs Ajustados (simples)")
abline(h = 0, col = claranja, lwd = 3, lty = 2)
dev.off()

shap <- shapiro.test(resid(m))
add(""); add("Shapiro (simples): W = ", round(shap$statistic, 4),
             " | p = ", round(shap$p.value, 5))

# Viés-variância
arq3 <- file.path(pasta_fig, "03-regressao-linear_img3.png")
png(arq3, width = 700, height = 700); par(mar = c(4,4,1,1), pty = "s")
plot(x, y, pch = 19, col = "gray60",
     xlab = "Escolaridade", ylab = "Mortalidade", main = "Viés-Variância (graus 1, 2, 4)")
xx <- seq(min(x), max(x), length.out = 200)
cores <- c(cazul, claranja, croxo); graus <- c(1, 2, 4)
for (k in seq_along(graus)) {
  mp <- lm(y ~ poly(x, graus[k])); lines(xx, predict(mp, newdata = data.frame(x = xx)),
                                         col = cores[k], lwd = 2.5)
}
legend("topleft", c("Grau 1","Grau 2","Grau 4"), col = cores, lwd = 2.5, bty = "n")
dev.off()

# Bootstrap
set.seed(1); B <- 2000
b1_boot <- replicate(B, {
  i <- sample(length(y), length(y), replace = TRUE)
  coef(lm(y[i] ~ x[i]))[2]
})
se_boot <- sd(b1_boot); ci_boot <- quantile(b1_boot, c(0.025, 0.975))
add(""); add("================ BOOTSTRAP ================")
add("β1 MQO: ", sprintf("%.4f", b1))
add("EP bootstrap: ", sprintf("%.4f", se_boot))
add("IC 95%: [", sprintf("%.4f", ci_boot[1]), "; ", sprintf("%.4f", ci_boot[2]), "]")

arq4 <- file.path(pasta_fig, "03-regressao-linear_img4.png")
png(arq4, width = 700, height = 700); par(mar = c(4,4,1,1), pty = "s")
hist(b1_boot, breaks = 30, prob = TRUE, col = cfill, border = "white",
     xlab = "β1 reamostrado", ylab = "Densidade", main = "Bootstrap de β1")
abline(v = ci_boot, col = claranja, lwd = 2, lty = 2)
abline(v = b1, col = croxo, lwd = 3)
legend("topright", c("β1 MQO","IC 95%"),
       col = c(croxo,claranja), lwd = c(3,2), lty = c(1,2), bty = "n")
dev.off()

# Múltipla
m2 <- lm(mortalidade_60_69 ~ escolaridade + distorcao_em, data = dados)
s2 <- summary(m2)
add(""); add("================ MODELO MÚLTIPLO ================")
out <- capture.output(printCoefmat(coef(s2), signif.legend = FALSE))
cat(paste(out, collapse = "\n"), "\n"); buffer <- c(buffer, out)

add(""); add("================ SIMPLES vs MÚLTIPLA ================")
add_print(data.frame(
  Modelo = c("Simples (escolaridade)", "Múltipla (+ distorcao_em)"),
  R2 = round(c(s$r.squared, s2$r.squared), 4),
  R2_aj = round(c(s$adj.r.squared, s2$adj.r.squared), 4),
  RSE = round(c(s$sigma, s2$sigma), 4),
  p = c(1, 2)
))
cor_pred <- cor(dados$escolaridade, dados$distorcao_em)
add("Correlação escolaridade × distorcao_em: ", round(cor_pred, 4))

arq5 <- file.path(pasta_fig, "03-regressao-linear_img5.png")
png(arq5, width = 800, height = 700); par(mar = c(4,4,1,1), pty = "s")
plot(dados$escolaridade, dados$mortalidade_60_69, pch = 19, col = cazul,
     xlab = "Escolaridade", ylab = "Mortalidade",
     main = "Simples vs Múltipla (distorção na média)")
grid_x <- seq(min(x), max(x), length.out = 100)
pred_m2 <- predict(m2, newdata = data.frame(
  escolaridade = grid_x,
  distorcao_em = rep(mean(dados$distorcao_em), 100)))
abline(m, col = claranja, lwd = 2, lty = 2)
lines(grid_x, pred_m2, col = croxo, lwd = 3)
legend("topright", c("Simples","Múltipla (dist. média)"),
       col = c(claranja,croxo), lwd = c(2,3), lty = c(2,1), bty = "n")
dev.off()

arq6 <- file.path(pasta_fig, "03-regressao-linear_img6.png")
png(arq6, width = 700, height = 700); par(mar = c(4,4,1,1), pty = "s")
plot(fitted(m2), resid(m2), pch = 19, col = cazul,
     xlab = "Ajustados", ylab = "Resíduos", main = "Resíduos vs Ajustados (múltipla)")
abline(h = 0, col = claranja, lwd = 3, lty = 2)
dev.off()

shap2 <- shapiro.test(resid(m2))
add("Shapiro (múltipla): W = ", round(shap2$statistic, 4),
    " | p = ", round(shap2$p.value, 5))

add(""); add("[OK] Figuras gravadas em: ", pasta_fig)

arquivo_md <- "03-regressao-linear.md"
cabecalho <- c(
  "# Relatório da Atividade 03 — Regressão Linear",
  "",
  paste0("**Gerado por:** `03-regressao-linear.R`  "),
  paste0("**Data:** ", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "  "),
  paste0("**Origem:** `", origem_dados, "`  "),
  "",
  "> **Alvo:** `mortalidade_60_69` (mortes por mil hab., 60–69).",
  "",
  "## Sumário executivo",
  "",
  paste0("- Simples: `mortalidade = ", round(b0,4), " + ", round(b1,4), " × escolaridade`"),
  paste0("- R² = ", round(s$r.squared, 4), " | RSE = ", round(s$sigma, 4)),
  paste0("- IC 95% β1 (analítico) = [", round(ci["escolaridade",1],4),
         "; ", round(ci["escolaridade",2],4), "]"),
  paste0("- IC 95% β1 (bootstrap) = [", sprintf("%.4f", ci_boot[1]),
         "; ", sprintf("%.4f", ci_boot[2]), "]"),
  paste0("- Shapiro p = ", round(shap$p.value, 5)),
  paste0("- Múltipla (+ distorcao_em): R² = ", round(s2$r.squared, 4),
         " | R² aj = ", round(s2$adj.r.squared, 4)),
  paste0("- Correlação escolaridade × distorção = ", round(cor_pred, 4)),
  "",
  "## Figuras",
  "",
  paste0("- `", arq1, "` — Dispersão + reta + resíduos"),
  paste0("- `", arq2, "` — Resíduos vs ajustados (simples)"),
  paste0("- `", arq3, "` — Viés-variância"),
  paste0("- `", arq4, "` — Bootstrap β1"),
  paste0("- `", arq5, "` — Simples vs múltipla"),
  paste0("- `", arq6, "` — Resíduos vs ajustados (múltipla)"),
  "",
  "## Output bruto",
  "", "```", paste(buffer, collapse = "\n"), "```",
  "",
  "## Notas",
  "",
  "Y está em mortes por mil habitantes. β1 negativo indica associação inversa",
  "entre escolaridade e mortalidade adulta. A múltipla adiciona distorção",
  "idade-série — ambos preditores educacionais, sem circularidade com o alvo.",
  ""
)
writeLines(cabecalho, arquivo_md)
cat("\n[OK] Relatório gravado em:", arquivo_md, "\n")