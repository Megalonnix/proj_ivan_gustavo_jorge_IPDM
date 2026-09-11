# ==============================================================================
# REGRESSÃO LINEAR — Mortalidade 60-69 ~ PIB per capita (amostra completa)
# ==============================================================================
if (!require('pacman')) install.packages('pacman')
pacman::p_load(readr, dplyr, ggplot2, moments)

# ------------------------------------------------------------------ caminhos
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

# ------------------------------------------------------------------- leitura
df <- read_csv2(
  file.path(caminho_banco, "df_ipdm_baixada_por_municipio.csv"),
  locale = locale(encoding = "Latin1"),
  show_col_types = FALSE
)
names(df)[grepl("^Taxas de mortalidade", names(df))] <- "mortalidade_60_69"
names(df)[grepl("^Produto Interno Bruto", names(df))] <- "pib_per_capita"

# ------------------------------------------------------------------ ajuste OLS
modelo <- lm(mortalidade_60_69 ~ pib_per_capita, data = df)
summary(modelo)
confint(modelo, level = 0.95)

cat("\n--- Coeficientes ---\n"); print(coef(modelo))
cat("\n--- R² ---\n");           print(summary(modelo)$r.squared)
cat("\n--- R² ajustado ---\n");  print(summary(modelo)$adj.r.squared)
cat("\n--- Erro-padrão residual ---\n"); print(summary(modelo)$sigma)
cat("\n--- Estatística F ---\n"); print(summary(modelo)$fstatistic)

df$resid     <- residuals(modelo)
df$fitted    <- fitted(modelo)
df$resid_pad <- rstandard(modelo)

# ---------------------------------------------------------------- gráfico 1
g1 <- ggplot(df, aes(x = pib_per_capita, y = mortalidade_60_69)) +
  geom_point(color = "steelblue", size = 2, alpha = 0.8) +
  geom_smooth(method = "lm", se = TRUE, color = "firebrick", fill = "firebrick",
              alpha = 0.15) +
  labs(
    title = "Mortalidade 60–69 anos × PIB per capita (Baixada Santista, 2014–2024)",
    subtitle = "Reta OLS com banda de confiança de 95%",
    x = "PIB per capita (R$ de 2024)",
    y = "Taxa de mortalidade 60–69 (por mil hab.)"
  ) +
  theme_minimal(base_size = 12)
ggsave(file.path(caminho_fig, "fig1_linear_dispersao.png"),
       g1, width = 9, height = 5.5, dpi = 150)

# ---------------------------------------------------------------- gráfico 2
g2 <- ggplot(df, aes(x = fitted, y = resid)) +
  geom_point(color = "steelblue", size = 2, alpha = 0.8) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray40") +
  geom_smooth(method = "loess", se = FALSE, color = "firebrick", span = 1) +
  labs(title = "Resíduos vs. valores ajustados",
       x = "Valores ajustados", y = "Resíduos") +
  theme_minimal(base_size = 12)
ggsave(file.path(caminho_fig, "fig1_linear_residuos.png"),
       g2, width = 9, height = 5.5, dpi = 150)

# ---------------------------------------------------------------- gráfico 3
g3 <- ggplot(df, aes(sample = resid)) +
  stat_qq(color = "steelblue", size = 1.8) +
  stat_qq_line(color = "firebrick") +
  labs(title = "QQ-plot dos resíduos",
       x = "Quantis teóricos", y = "Resíduos") +
  theme_minimal(base_size = 12)
ggsave(file.path(caminho_fig, "fig1_linear_qq.png"),
       g3, width = 7, height = 5.5, dpi = 150)

# ------------------------------------------------------ diagnósticos formais
cat("\n--- Shapiro-Wilk nos resíduos ---\n")
print(shapiro.test(residuals(modelo)))
cat("\n--- Skewness / Curtose dos resíduos ---\n")
print(skewness(residuals(modelo)))
print(kurtosis(residuals(modelo)))
