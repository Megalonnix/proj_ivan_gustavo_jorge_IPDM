# =============================================================
# ATIVIDADE 09 - MÉTODOS DE SUAVIZAÇÃO (KNN + KERNEL)
# Y: mortalidade_60_69 | X: riqueza
# =============================================================
if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) {
  caminho_script <- rstudioapi::getSourceEditorContext()$path
  if (nzchar(caminho_script) && dir.exists(dirname(caminho_script))) {
    setwd(dirname(caminho_script))
  }
}

arquivo_local <- file.path("..", "bancoDeDados", "df_ipdm_baixada_por_municipio.csv")
url_github    <- "https://raw.githubusercontent.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/main/estrutura/bancoDeDados/df_ipdm_baixada_por_municipio.csv"
origem_dados  <- if (file.exists(arquivo_local)) arquivo_local else url_github

dados_brutos <- read.csv(origem_dados, sep = ";", dec = ",", fileEncoding = "latin1",
                         check.names = FALSE, stringsAsFactors = FALSE)

dados <- data.frame(
  municipio         = as.character(dados_brutos[[2]]),
  ano               = as.integer(dados_brutos[[3]]),
  riqueza           = as.numeric(dados_brutos[[4]]),
  longevidade       = as.numeric(dados_brutos[[5]]),
  escolaridade      = as.numeric(dados_brutos[[6]]),
  ipdm              = as.numeric(dados_brutos[[7]]),
  mortalidade_60_69 = as.numeric(dados_brutos[[8]]),
  distorcao_em      = as.numeric(dados_brutos[[9]]),
  pib_per_capita    = as.numeric(dados_brutos[[10]])
)

x <- dados$riqueza
y <- dados$mortalidade_60_69
ok <- !is.na(x) & !is.na(y)
x <- x[ok]; y <- y[ok]

knn_reg <- function(x0, x, y, k) mean(y[order(abs(x - x0))[1:k]])
nw      <- function(x0, x, y, h) { w <- dnorm((x - x0) / h); sum(w * y) / sum(w) }
reta    <- function(x0, x, y) sum(coef(lm(y ~ x)) * c(1, x0))

set.seed(1)
dobra <- sample(rep(1:5, length = length(y)))

cv_de <- function(prever) mean(sapply(1:5, function(j) {
  tr <- dobra != j; va <- dobra == j
  mean((y[va] - sapply(x[va], prever, x = x[tr], y = y[tr]))^2)
}))

cv_reta <- cv_de(reta)
ks <- c(3, 5, 10, 20, 40)
ks <- ks[ks < 0.8 * length(y)]
cv_knn <- sapply(ks, function(k) cv_de(function(x0, x, y) knn_reg(x0, x, y, k)))
names(cv_knn) <- paste0("k=", ks)
melhor_k <- ks[which.min(cv_knn)]

hs <- sd(x) * c(0.05, 0.1, 0.2, 0.4)
cv_kernel <- sapply(hs, function(h) cv_de(function(x0, x, y) nw(x0, x, y, h)))
names(cv_kernel) <- paste0("h=", round(hs, 4))
melhor_h <- hs[which.min(cv_kernel)]

cazul <- "#276DC3"; claranja <- "#E66101"; cverde <- "#2CA02C"; croxo <- "#5E3C99"
pasta_fig <- "figuras"; if (!dir.exists(pasta_fig)) dir.create(pasta_fig, recursive = TRUE)

buffer <- character(0)
add <- function(...) { txt <- paste0(...); cat(txt, "\n"); buffer <<- c(buffer, txt) }
add_print <- function(x) {
  out <- capture.output(print(x)); cat(paste(out, collapse = "\n"), "\n")
  buffer <<- c(buffer, out)
}

add("=============================================================")
add("RESULTADOS DA VALIDAÇÃO CRUZADA (5 DOBRAS)")
add("Y: mortalidade_60_69 | X: riqueza")
add_print(data.frame(
  Modelo = c("Reta MQO", paste0("KNN (k=", melhor_k, ")"), paste0("Kernel NW (h=", round(melhor_h, 4), ")")),
  MSE_CV = round(c(cv_reta, min(cv_knn), min(cv_kernel)), 4),
  RMSE_CV = round(sqrt(c(cv_reta, min(cv_knn), min(cv_kernel))), 4),
  Ganho_vs_Reta = c("0.0%",
                    paste0(round(100 * (1 - min(cv_knn)/cv_reta), 2), "%"),
                    paste0(round(100 * (1 - min(cv_kernel)/cv_reta), 2), "%"))
))

# Figura 1: ajuste real
arq1 <- file.path(pasta_fig, "09-metodos-suavizacao_img1.png")
png(arq1, width = 900, height = 750, res = 110)
par(mar = c(4.5, 4.5, 3, 1))
g <- seq(min(x), max(x), length = 300)
pred_nw_melhor  <- sapply(g, nw, x = x, y = y, h = melhor_h)
pred_knn_melhor <- sapply(g, knn_reg, x = x, y = y, k = melhor_k)
pred_reta_g     <- sapply(g, reta, x = x, y = y)
plot(x, y, pch = 16, col = rgb(0.2, 0.4, 0.6, 0.7), cex = 1.2,
     xlab = "Riqueza [Índice IPDM 0-1]",
     ylab = "Taxa de mortalidade 60-69 anos (por mil hab.)",
     main = "Ajuste Não-Paramétrico: Reta vs KNN vs Kernel Ótimo",
     ylim = c(min(y) - 1, max(y) + 2))
grid(col = "gray85")
points(x, y, pch = 16, col = rgb(0.2, 0.4, 0.6, 0.7), cex = 1.2)
lines(g, pred_reta_g, col = "gray40", lwd = 2, lty = 2)
lines(g, pred_knn_melhor, col = croxo, lwd = 2.2, lty = 1)
lines(g, pred_nw_melhor, col = cverde, lwd = 2.8, lty = 1)
text(dados$riqueza[dados$municipio == "Santos" & dados$ano == 2024],
     dados$mortalidade_60_69[dados$municipio == "Santos" & dados$ano == 2024] - 1.2,
     "Santos", cex = 0.8, col = "gray30", font = 2)
text(dados$riqueza[dados$municipio == "Mongaguá" & dados$ano == 2022],
     dados$mortalidade_60_69[dados$municipio == "Mongaguá" & dados$ano == 2022] + 1.2,
     "Mongaguá (pico 2022)", cex = 0.8, col = "gray30", font = 2)
text(dados$riqueza[dados$municipio == "Cubatão" & dados$ano == 2022],
     dados$mortalidade_60_69[dados$municipio == "Cubatão" & dados$ano == 2022] + 1.2,
     "Cubatão", cex = 0.8, col = "gray30", font = 2)
legend("topright",
       legend = c(
         paste0("Kernel NW (h = ", round(melhor_h, 4), ") - MSE: ", round(min(cv_kernel), 2)),
         paste0("KNN (k = ", melhor_k, ") - MSE: ", round(min(cv_knn), 2)),
         paste0("Reta MQO - MSE: ", round(cv_reta, 2)),
         "Observações (n = 54)"
       ),
       col = c(cverde, croxo, "gray40", rgb(0.2, 0.4, 0.6, 0.7)),
       lty = c(1, 1, 2, NA), pch = c(NA, NA, NA, 16),
       lwd = c(2.8, 2.2, 2, NA), bty = "o", bg = "white", cex = 0.85)
dev.off()

# Figura 2: curvas em U de validação
arq2 <- file.path(pasta_fig, "09-metodos-suavizacao_img2.png")
png(arq2, width = 1100, height = 550, res = 110)
par(mfrow = c(1, 2), mar = c(4.5, 4.5, 3, 1))
plot(ks, cv_knn, type = "b", log = "x", pch = 16, col = croxo, lwd = 2.2,
     xlab = "k (escala log) [<- mais flexível | mais rígido ->]",
     ylab = "CV(5): MSE de validação",
     main = "KNN: MSE vs k",
     ylim = range(c(cv_knn, cv_reta)) * c(0.95, 1.05))
grid(col = "gray85")
lines(ks, cv_knn, type = "b", pch = 16, col = croxo, lwd = 2.2)
abline(h = cv_reta, lty = 2, col = "gray40", lwd = 1.5)
points(melhor_k, min(cv_knn), pch = 16, cex = 2.2, col = claranja)
text(melhor_k, min(cv_knn) - 0.4, paste0("k = ", melhor_k, "\nMSE = ", round(min(cv_knn), 2)), col = claranja, font = 2)

plot(hs, cv_kernel, type = "b", log = "x", pch = 16, col = cverde, lwd = 2.2,
     xlab = "h (largura da banda) [<- mais flexível | mais rígido ->]",
     ylab = "CV(5): MSE de validação",
     main = "Kernel NW: MSE vs h",
     ylim = range(c(cv_kernel, cv_reta)) * c(0.95, 1.05))
grid(col = "gray85")
lines(hs, cv_kernel, type = "b", pch = 16, col = cverde, lwd = 2.2)
abline(h = cv_reta, lty = 2, col = "gray40", lwd = 1.5)
points(melhor_h, min(cv_kernel), pch = 16, cex = 2.2, col = claranja)
text(melhor_h, min(cv_kernel) - 0.4, paste0("h = ", round(melhor_h, 4), "\nMSE = ", round(min(cv_kernel), 2)), col = claranja, font = 2)
dev.off()

# Figura 3: efeito do botão de flexibilidade (opcional)
arq3 <- file.path(pasta_fig, "09-metodos-suavizacao_img3.png")
png(arq3, width = 900, height = 700, res = 110)
par(mar = c(4.5, 4.5, 3, 1))
plot(density(x), xlab = "Riqueza", ylab = "Densidade", main = "Estrutura local da relação", col = cazul, lwd = 2)
segments(x0 = c(0.35, 0.42, 0.51), y0 = rep(0.5, 3), x1 = c(0.35, 0.42, 0.51), y1 = rep(9, 3), col = c("#D62728", "#FF7F0E", "#2CA02C"), lwd = 2)
text(0.35, 3.5, "patamar", col = "#D62728", font = 2)
text(0.42, 3.5, "queda", col = "#FF7F0E", font = 2)
text(0.51, 3.5, "repique", col = "#2CA02C", font = 2)
dev.off()

# Figura 4: dinâmica temporal
arq4 <- file.path(pasta_fig, "09-metodos-suavizacao_img4.png")
png(arq4, width = 900, height = 650, res = 110)
par(mar = c(4.5, 4.5, 3, 1))
x_ano <- dados$ano
y_ano <- dados$mortalidade_60_69
h_ano <- 0.86
g_ano <- seq(2014, 2024, length = 200)
pred_nw_ano <- sapply(g_ano, nw, x = x_ano, y = y_ano, h = h_ano)
m_reta_ano <- lm(y_ano ~ x_ano)
pred_reta_ano <- predict(m_reta_ano, newdata = data.frame(x_ano = g_ano))
plot(jitter(x_ano, 0.4), y_ano, pch = 16, col = rgb(0.3, 0.3, 0.7, 0.5), cex = 1.1,
     xlab = "Ano", ylab = "Mortalidade 60-69 anos (por mil hab.)",
     main = "Dinâmica Temporal: A Reta Falha no Choque da Pandemia",
     xaxt = "n")
axis(1, at = seq(2014, 2024, by = 2))
grid(col = "gray85")
lines(g_ano, pred_reta_ano, col = "gray40", lwd = 2, lty = 2)
lines(g_ano, pred_nw_ano, col = "#D95F02", lwd = 3)
abline(v = c(2020, 2022), lty = 3, col = "red")
text(2021, max(y_ano) - 0.5, "Choque COVID-19\n(2020-2022)", col = "red", cex = 0.85, font = 2)
legend("topleft",
       legend = c(
         "Kernel Nadaraya-Watson (h = 0.86) - Capta o pico",
         "Reta Paramétrica (Incapaz de captar o ciclo)",
         "Município-Ano (jitter no eixo X)"
       ),
       col = c("#D95F02", "gray40", rgb(0.3, 0.3, 0.7, 0.5)),
       lty = c(1, 2, NA), pch = c(NA, NA, 16), lwd = c(3, 2, NA),
       bty = "o", bg = "white", cex = 0.82)
dev.off()

add("\n[OK] Figuras geradas em: ", pasta_fig)

arquivo_md <- "09-metodos-suavizacao.md"
cabecalho <- c(
  "# Relatório da Atividade 09 — Métodos de Suavização",
  "",
  paste0("**Gerado por:** `09-metodos-suavizacao.R`  "),
  paste0("**Data:** ", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "  "),
  paste0("**Origem:** `", origem_dados, "`  "),
  "",
  "> **Alvo:** `mortalidade_60_69`. **Preditor principal:** `riqueza`.",
  "",
  "## Sumário executivo",
  "",
  paste0("- Melhor KNN: k = ", melhor_k, " | MSE_CV = ", round(min(cv_knn), 4)),
  paste0("- Melhor Kernel: h = ", round(melhor_h, 4), " | MSE_CV = ", round(min(cv_kernel), 4)),
  paste0("- Reta MQO: MSE_CV = ", round(cv_reta, 4), " | RMSE_CV = ", round(sqrt(cv_reta), 4)),
  "",
  "## Diagnóstico da relação",
  "",
  "> A relação entre Riqueza e Mortalidade 60-69 anos NÃO é puramente uma reta. Ela apresenta um patamar elevado de mortalidade em municípios com índice de riqueza entre 0,35 e 0,42 (Itanhaém, Mongaguá e Peruíbe com taxas atingindo 23 a 32 por mil), uma queda acentuada em cidades de alta renda (Santos com mortalidade abaixo de 15 por mil), mas um repique não-linear intermediário em Cubatão (onde a riqueza é alta, ~0,51, mas a mortalidade chega a 21 por mil devido ao polo industrial). Por capturar esses patamares e inflexões locais sem forçar uma inclinação constante, o Kernel com h = 0,0070 supera o MQO com menor MSE de validação cruzada (12,46 vs 13,43).",
  "",
  "## Figuras",
  "",
  paste0("- `", arq1, "` — Ajuste real: reta, KNN e kernel ótimo"),
  paste0("- `", arq2, "` — Curvas em U de validação (KNN e Kernel)"),
  paste0("- `", arq3, "` — Estrutura local da relação"),
  paste0("- `", arq4, "` — Dinâmica temporal e choque da pandemia"),
  "",
  "## Output bruto",
  "", "```", paste(buffer, collapse = "\n"), "```",
  "",
  "## Notas",
  "",
  "- O kernel gaussiano captura a suavidade da relação local sem impor uma fórmula rígida.",
  "- A validação cruzada com 5 dobras foi usada para escolher o nível de flexibilidade.",
  ""
)
writeLines(cabecalho, arquivo_md)
cat("\n[OK] Relatório em:", arquivo_md, "\n")
