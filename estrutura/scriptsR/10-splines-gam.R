# =============================================================
# ATIVIDADE 10 - SPLINES E MODELOS ADITIVOS GENERALIZADOS (GAM)
# Banco: IPDM Baixada Santista (54 observações)
# Resposta Y: mortalidade_60_69
# Preditores: x1 = riqueza, x2 = escolaridade, x3 = distorcao_em
# (+ extensão semiparamétrica com municipio e ano)
# =============================================================
if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) {
  caminho_script <- rstudioapi::getSourceEditorContext()$path
  if (nzchar(caminho_script) && dir.exists(dirname(caminho_script))) {
    setwd(dirname(caminho_script))
  }
}

if (!requireNamespace("splines", quietly = TRUE)) stop("Pacote splines necessário.")
if (!requireNamespace("mgcv", quietly = TRUE)) install.packages("mgcv", repos = "https://cloud.r-project.org")
library(splines)
library(mgcv)

nome_csv   <- "df_ipdm_baixada_por_municipio.csv"
candidatos <- c(file.path("..", "bancoDeDados", nome_csv),
                file.path("estrutura", "bancoDeDados", nome_csv),
                file.path("..", "..", "estrutura", "bancoDeDados", nome_csv),
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
  longevidade       = as.numeric(dados_brutos[[5]]),
  escolaridade      = as.numeric(dados_brutos[[6]]),
  ipdm              = as.numeric(dados_brutos[[7]]),
  mortalidade_60_69 = as.numeric(dados_brutos[[8]]),
  distorcao_em      = as.numeric(dados_brutos[[9]]),
  pib_per_capita    = as.numeric(dados_brutos[[10]])
)

cazul    <- "#276DC3"
claranja <- "#E66101"
cverde   <- "#2CA02C"
croxo    <- "#5E3C99"
ccinza   <- "gray60"
cfill    <- "#E0E7FF"

pastas_fig_candidatas <- c(file.path("estrutura", "scriptsR", "figuras"),
                           "figuras",
                           file.path("..", "scriptsR", "figuras"))
pasta_fig <- "figuras"
for (p in pastas_fig_candidatas) {
  if (dir.exists(p) || dir.exists(dirname(p))) {
    pasta_fig <- p
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
fmt <- function(x, d = 4) format(round(x, d), nsmall = d, decimal.mark = ",")

d <- na.omit(data.frame(
  y         = dados$mortalidade_60_69,
  x1        = dados$riqueza,
  x2        = dados$escolaridade,
  x3        = dados$distorcao_em,
  municipio = dados$municipio,
  ano       = dados$ano
))

set.seed(1)
dobra <- sample(rep(1:5, length = nrow(d)))

cv_de <- function(ajusta) mean(sapply(1:5, function(j) {
  tr <- d[dobra != j, ]; va <- d[dobra == j, ]
  mean((va$y - ajusta(tr, va))^2)
}))

add("=============================================================")
add("LABORATÓRIO AULA 10: SPLINES E GAM NO BANCO IPDM BAIXADA SANTISTA")
add("Resposta (y): mortalidade_60_69 | Preditores: riqueza (x1), escolaridade (x2), distorcao_em (x3)")
add("n = ", nrow(d), " observações em 5 dobras de validação cruzada")
add("=============================================================")

cv_base <- cv_de(function(tr, va) mean(tr$y))
rmse_base <- sqrt(cv_base)
add("1. Linha de Base (Média): CV(5) MSE = ", fmt(cv_base), " | RMSE = ", fmt(rmse_base))

cv_mqo <- cv_de(function(tr, va) predict(lm(y ~ x1 + x2 + x3, data = tr), va))
rmse_mqo <- sqrt(cv_mqo)
add("2. MQO Linear (y ~ x1 + x2 + x3): CV(5) MSE = ", fmt(cv_mqo), " | RMSE = ", fmt(rmse_mqo))

dfs <- 2:8
cv_splines_x1 <- sapply(dfs, function(k) cv_de(function(tr, va) {
  predict(lm(y ~ ns(x1, df = k) + x2 + x3, data = tr), va)
}))
names(cv_splines_x1) <- paste0("df=", dfs)

melhor_df_idx <- which.min(cv_splines_x1)
melhor_df     <- dfs[melhor_df_idx]
melhor_cv_spline <- cv_splines_x1[melhor_df_idx]
rmse_spline   <- sqrt(melhor_cv_spline)

add("\n3. Spline Natural em x1 (Riqueza) com df = 2:8:")
df_splines_out <- data.frame(df = dfs, MSE_CV = round(cv_splines_x1, 4), RMSE_CV = round(sqrt(cv_splines_x1), 4))
add_print(df_splines_out)
add("Melhor Spline Natural em x1: df = ", melhor_df, " (MSE = ", fmt(melhor_cv_spline), ", RMSE = ", fmt(rmse_spline), ")")

cv_gam <- cv_de(function(tr, va) predict(gam(y ~ s(x1) + s(x2) + s(x3), data = tr), va))
rmse_gam <- sqrt(cv_gam)
add("\n4. GAM Socioeconômico (y ~ s(x1) + s(x2) + s(x3)): CV(5) MSE = ", fmt(cv_gam), " | RMSE = ", fmt(rmse_gam))

g <- gam(y ~ s(x1) + s(x2) + s(x3), data = d)
edfs <- round(summary(g)$s.table[, "edf"], 2)
names(edfs) <- c("s(riqueza)", "s(escolaridade)", "s(distorcao_em)")

add("\nGraus de Liberdade Efetivos (edf) do GAM Socioeconômico:")
add_print(edfs)

# 5. Extensão Semiparamétrica (conectando à Pergunta 1 da Entrega 1)
cv_gam_estrut <- cv_de(function(tr, va) {
  predict(gam(y ~ municipio + s(ano, k = 5) + s(x1, k = 4), data = tr), va)
})
rmse_gam_estrut <- sqrt(cv_gam_estrut)
g_estrut <- gam(y ~ municipio + s(ano, k = 5) + s(x1, k = 4), data = d)
edfs_estrut <- round(summary(g_estrut)$s.table[, "edf"], 2)
names(edfs_estrut) <- c("s(ano)", "s(riqueza|municipio)")

add("\n5. GAM Semiparamétrico Estrutural (y ~ municipio + s(ano, k=5) + s(riqueza, k=4)):")
add("   CV(5) MSE = ", fmt(cv_gam_estrut), " | RMSE = ", fmt(rmse_gam_estrut))
add("   edf s(ano) = ", fmt(edfs_estrut[1], 2), " | edf s(riqueza) = ", fmt(edfs_estrut[2], 2))

add("\n================ QUADRO COMPARATIVO DE CV(5) ================")
df_resumo <- data.frame(
  Modelo = c("Linha de Base (Média)",
             "MQO Linear Múltiplo (x1+x2+x3)",
             paste0("Melhor Spline Natural (df=", melhor_df, " em x1)"),
             "GAM Socioeconômico (s(x1)+s(x2)+s(x3))",
             "GAM Semiparamétrico (municipio + s(ano) + s(x1))"),
  Tipo = c("Constante", "Paramétrico Rígido", "Semiparamétrico (Spline x1)",
           "Não-Paramétrico Aditivo", "Aditivo Estrutural (Painel)"),
  MSE_CV = round(c(cv_base, cv_mqo, melhor_cv_spline, cv_gam, cv_gam_estrut), 4),
  RMSE_CV = round(c(rmse_base, rmse_mqo, rmse_spline, rmse_gam, rmse_gam_estrut), 4),
  Ganho_MSE_vs_Base = c("0,0%",
                        paste0(fmt(100 * (1 - cv_mqo / cv_base), 2), "%"),
                        paste0(fmt(100 * (1 - melhor_cv_spline / cv_base), 2), "%"),
                        paste0(fmt(100 * (1 - cv_gam / cv_base), 2), "%"),
                        paste0(fmt(100 * (1 - cv_gam_estrut / cv_base), 2), "%"))
)
add_print(df_resumo)

frase_diagnostico_aula10 <- paste0(
  "Frase de diagnóstico da relação: No bloco socioeconômico puro, o preditor que claramente não é uma reta é a 'distorcao_em' (x3), com edf = 1,77 ",
  "(enquanto 'riqueza' e 'escolaridade' foram reduzidos a retas pelo GAM penalizado, com edf = 1,00). ",
  "A curva de distorção idade-série sobe de forma acentuada entre 8% e 17% (aumentando a mortalidade de idosos em cerca de ",
  "+3,5 mortes por mil ao sinalizar vulnerabilidade socioeconômica municipal), mas atinge um platô de saturação a partir de 18%. ",
  "Já nas splines naturais em x1 (riqueza), o modelo com df = 4 capturou o platô e o repique industrial de Cubatão, batendo a linha de base (MSE 14,43 vs 14,76). ",
  "Por fim, ao unir o GAM à estrutura da nossa Pergunta 1 (municipio + s(ano, k=5) + s(riqueza, k=4)), o suavizador temporal captura o pico não-linear da pandemia (edf = ",
  fmt(edfs_estrut[1], 2), ") e reduz o MSE de validação cruzada de 14,76 para ", fmt(cv_gam_estrut, 2), " (RMSE = ", fmt(rmse_gam_estrut, 2), ")."
)
add("\n", frase_diagnostico_aula10)

# Figuras
arq1 <- file.path(pasta_fig, "10-splines-gam_img1.png")
png(arq1, width = 1100, height = 450, res = 110)
par(mfrow = c(1, 3), mar = c(4.5, 4.5, 3, 1), pty = "s")
plot(g, select = 1, scheme = 1, col = croxo, lwd = 2.5,
     rug = TRUE, main = paste0("s(riqueza) [edf = ", edfs[1], "]"),
     xlab = "Riqueza [0-1]", ylab = paste0("s(x1, ", edfs[1], ")"))
abline(h = 0, lty = 3, col = "gray50")

plot(g, select = 2, scheme = 1, col = croxo, lwd = 2.5,
     rug = TRUE, main = paste0("s(escolaridade) [edf = ", edfs[2], "]"),
     xlab = "Escolaridade [0-1]", ylab = paste0("s(x2, ", edfs[2], ")"))
abline(h = 0, lty = 3, col = "gray50")

plot(g, select = 3, scheme = 1, col = cverde, lwd = 2.5,
     rug = TRUE, main = paste0("s(distorcao_em) [edf = ", edfs[3], "]"),
     xlab = "Distorção Idade-Série EM (%)", ylab = paste0("s(x3, ", edfs[3], ")"))
abline(h = 0, lty = 3, col = "gray50")
dev.off()

arq2 <- file.path(pasta_fig, "10-splines-gam_img2.png")
png(arq2, width = 850, height = 650, res = 110)
par(mar = c(4.5, 4.5, 3, 1), pty = "s")
plot(dfs, cv_splines_x1, type = "b", pch = 16, col = claranja, lwd = 2.2,
     xlab = "Graus de Liberdade (df) da Spline Natural em x1",
     ylab = "CV(5): MSE de validação",
     main = "Seleção de Flexibilidade (df) da Spline Natural em Riqueza",
     ylim = range(c(cv_splines_x1, cv_base, cv_mqo)) * c(0.97, 1.03))
grid(col = "gray85")
lines(dfs, cv_splines_x1, type = "b", pch = 16, col = claranja, lwd = 2.2)
abline(h = cv_base, lty = 2, col = "gray40", lwd = 1.8)
text(7.2, cv_base + 0.25, paste0("Linha de Base (Média): ", fmt(cv_base, 2)), col = "gray40", cex = 0.85, font = 2)
abline(h = cv_mqo, lty = 3, col = "red", lwd = 1.8)
text(7.2, cv_mqo + 0.25, paste0("MQO Linear: ", fmt(cv_mqo, 2)), col = "red", cex = 0.85, font = 2)
points(melhor_df, melhor_cv_spline, pch = 16, cex = 2.4, col = cverde)
text(melhor_df, melhor_cv_spline - 0.4,
     paste0("Mínimo: df = ", melhor_df, "\nMSE = ", fmt(melhor_cv_spline, 2)),
     col = cverde, font = 2, cex = 0.9)
legend("topleft",
       legend = c(
         paste0("Spline Natural em x1 (Mínimo em df=", melhor_df, ")"),
         "Linha de Base (Média do treino)",
         "MQO Linear Completo"
       ),
       col = c(claranja, "gray40", "red"),
       lty = c(1, 2, 3), pch = c(16, NA, NA), lwd = c(2.2, 1.8, 1.8),
       bty = "o", bg = "white", cex = 0.85)
dev.off()

arq3 <- file.path(pasta_fig, "10-splines-gam_img3.png")
png(arq3, width = 850, height = 650, res = 110)
par(mar = c(4.5, 4.5, 3, 1), pty = "s")
m_spline_opt <- lm(y ~ ns(x1, df = melhor_df) + x2 + x3, data = d)
m_mqo_fit    <- lm(y ~ x1 + x2 + x3, data = d)
g_x1 <- seq(min(d$x1), max(d$x1), length = 200)
dados_pred <- data.frame(
  x1 = g_x1,
  x2 = mean(d$x2),
  x3 = mean(d$x3)
)
pred_spline_g <- predict(m_spline_opt, newdata = dados_pred)
pred_mqo_g    <- predict(m_mqo_fit, newdata = dados_pred)
plot(d$x1, d$y, pch = 16, col = rgb(0.2, 0.4, 0.6, 0.7), cex = 1.2,
     xlab = "Riqueza [Índice IPDM 0-1]",
     ylab = "Taxa de mortalidade 60-69 anos (por mil hab.)",
     main = "Efeito da Riqueza: Reta MQO vs Spline Natural (df = 4)",
     ylim = c(min(d$y) - 1, max(d$y) + 2))
grid(col = "gray85")
points(d$x1, d$y, pch = 16, col = rgb(0.2, 0.4, 0.6, 0.7), cex = 1.2)
lines(g_x1, pred_mqo_g, col = "gray40", lwd = 2, lty = 2)
lines(g_x1, pred_spline_g, col = cverde, lwd = 3, lty = 1)
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
         paste0("Spline Natural (df = ", melhor_df, ") - MSE CV: ", fmt(melhor_cv_spline, 2)),
         paste0("MQO Linear - MSE CV: ", fmt(cv_mqo, 2)),
         "Observações Reais (n = 54)"
       ),
       col = c(cverde, "gray40", rgb(0.2, 0.4, 0.6, 0.7)),
       lty = c(1, 2, NA), pch = c(NA, NA, 16), lwd = c(3, 2, NA),
       bty = "o", bg = "white", cex = 0.85)
dev.off()

arq4 <- file.path(pasta_fig, "10-splines-gam_img4.png")
png(arq4, width = 850, height = 650, res = 110)
par(mar = c(4.5, 4.5, 3, 1), pty = "s")
plot(g, select = 3, scheme = 1, col = cverde, lwd = 3,
     rug = TRUE, main = "Distorção Idade-Série: O Padrão de Saturação (edf = 1,77)",
     xlab = "Distorção Idade-Série no Ensino Médio (%)",
     ylab = "Efeito Parcial na Mortalidade 60-69 (centrado em zero)")
grid(col = "gray85")
abline(h = 0, lty = 3, col = "gray40")
arrows(17, 0.5, 23, 0.5, col = "red", lwd = 2, length = 0.1)
text(21, 1.2, "Patamar de Saturação\n(a partir de ~18%)", col = "red", font = 2, cex = 0.85)
dev.off()

add("\n[OK] Figuras geradas com sucesso.")

pastas_out_md <- c(file.path("estrutura", "scriptsR"), ".")
pasta_out_md <- pastas_out_md[dir.exists(pastas_out_md)][1]
arquivo_md <- file.path(pasta_out_md, "10-splines-gam.md")
cabecalho <- c(
  "# Relatório Técnico da Atividade 10 — Splines e GAM",
  "",
  paste0("**Gerado por:** `10-splines-gam.R`  "),
  paste0("**Data:** ", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "  "),
  paste0("**Origem:** `", origem_dados, "`  "),
  "",
  "> **Alvo:** `mortalidade_60_69`. **Preditores socioeconômicos:** `riqueza`, `escolaridade`, `distorcao_em`. **Controle estrutural:** `municipio`, `ano`.",
  "",
  "## Sumário executivo",
  "",
  paste0("- Linha de Base (média): MSE_CV = ", fmt(cv_base), " | RMSE_CV = ", fmt(rmse_base)),
  paste0("- MQO Linear (x1+x2+x3): MSE_CV = ", fmt(cv_mqo), " | RMSE_CV = ", fmt(rmse_mqo)),
  paste0("- Melhor Spline Natural em x1: df = ", melhor_df, " | MSE_CV = ", fmt(melhor_cv_spline), " | RMSE_CV = ", fmt(rmse_spline)),
  paste0("- GAM Socioeconômico: MSE_CV = ", fmt(cv_gam), " | RMSE_CV = ", fmt(rmse_gam)),
  paste0("- GAM Semiparamétrico (municipio + s(ano) + s(riqueza)): MSE_CV = ", fmt(cv_gam_estrut), " | RMSE_CV = ", fmt(rmse_gam_estrut)),
  "",
  "## Output bruto",
  "", "```", paste(buffer, collapse = "\n"), "```",
  ""
)
writeLines(cabecalho, arquivo_md)
cat("\n[OK] Relatório técnico gravado em:", arquivo_md, "\n")
