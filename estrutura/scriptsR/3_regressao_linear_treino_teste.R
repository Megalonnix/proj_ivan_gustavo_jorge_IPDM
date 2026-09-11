# ==============================================================================
# REGRESSÃO LINEAR — Treino/Teste (70/30)
# ==============================================================================
if (!require('pacman')) install.packages('pacman')
pacman::p_load(readr, dplyr, ggplot2)

caminho_base <- paste0(
  "C:/Users/Ivan/Documents/Pasta-Documentos-PC-antigo/",
  "GITHUB-Meus-Repositorios/PesquisaTeoAprendiEstati_2026_v2/",
  "proj_ivan_gustavo_jorge_(IPDM)"
)
caminho_banco <- file.path(caminho_base, "estrutura", "bancoDeDados")
caminho_fig   <- file.path(caminho_base, "estrutura", "scriptsR", "figuras")
if (!dir.exists(caminho_fig)) {
  dir.create(caminho_fig, recursive = TRUE, showWarnings = FALSE)
}
stopifnot(dir.exists(caminho_fig))

df <- read_csv2(
  file.path(caminho_banco, "df_ipdm_baixada_por_municipio.csv"),
  locale = locale(encoding = "Latin1"),
  show_col_types = FALSE
)
names(df)[grepl("^Taxas de mortalidade", names(df))] <- "mortalidade_60_69"
names(df)[grepl("^Produto Interno Bruto", names(df))] <- "pib_per_capita"

# ----------------------------------------------------------- split 70/30
set.seed(42)
n <- nrow(df)
idx_treino <- sample(seq_len(n), size = floor(0.7 * n))
treino <- df[idx_treino, ]
teste  <- df[-idx_treino, ]
cat("Treino:", nrow(treino), "| Teste:", nrow(teste), "\n")

# -------------------------------------------------------- ajuste no treino
modelo_treino <- lm(mortalidade_60_69 ~ pib_per_capita, data = treino)
summary(modelo_treino)

# ----------------------------------------------------- predição no teste
pred_teste <- predict(modelo_treino, newdata = teste)

erro     <- teste$mortalidade_60_69 - pred_teste
rmse     <- sqrt(mean(erro^2))
mae      <- mean(abs(erro))
r2_teste <- 1 - sum(erro^2) /
  sum((teste$mortalidade_60_69 - mean(teste$mortalidade_60_69))^2)
cat("\n--- Métricas no conjunto de teste ---\n")
cat("RMSE:", round(rmse, 4), "\n")
cat("MAE :", round(mae, 4), "\n")
cat("R²  :", round(r2_teste, 4), "\n")

# --------------------------------------- gráfico: reta (treino) vs. teste
g1 <- ggplot() +
  geom_point(data = teste,
             aes(x = pib_per_capita, y = mortalidade_60_69, color = "Teste"),
             size = 2.4, alpha = 0.9) +
  geom_point(data = treino,
             aes(x = pib_per_capita, y = mortalidade_60_69, color = "Treino"),
             size = 1.8, alpha = 0.35) +
  geom_smooth(data = treino,
              aes(x = pib_per_capita, y = mortalidade_60_69),
              method = "lm", se = TRUE, color = "firebrick",
              fill = "firebrick", alpha = 0.15) +
  scale_color_manual(values = c("Treino" = "gray50", "Teste" = "darkorange")) +
  labs(
    title = "Reta ajustada no treino sobre os pontos de teste",
    x = "PIB per capita (R$ de 2024)",
    y = "Mortalidade 60–69 (por mil hab.)",
    color = NULL
  ) +
  theme_minimal(base_size = 12) +
  theme(legend.position = "top")
ggsave(file.path(caminho_fig, "fig3_linear_teste_reta.png"),
       g1, width = 9, height = 5.5, dpi = 150)

# --------------------------------------- gráfico: previsto vs. real
df_pp <- data.frame(real = teste$mortalidade_60_69, previsto = pred_teste)
g2 <- ggplot(df_pp, aes(x = real, y = previsto)) +
  geom_point(color = "steelblue", size = 2.4) +
  geom_abline(slope = 1, intercept = 0,
              linetype = "dashed", color = "firebrick") +
  labs(
    title = "Previsto vs. real — conjunto de teste",
    subtitle = "Linha tracejada = identidade (y = x)",
    x = "Mortalidade observada",
    y = "Mortalidade prevista"
  ) +
  theme_minimal(base_size = 12)
ggsave(file.path(caminho_fig, "fig3_linear_previsto_real.png"),
       g2, width = 7, height = 6, dpi = 150)