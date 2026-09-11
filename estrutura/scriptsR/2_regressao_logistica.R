# ==============================================================================
# REGRESSÃO LOGÍSTICA — Mortalidade alta (acima da mediana) ~ PIB per capita
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

# ---------------------------------------------------- variável binária alvo
mediana <- median(df$mortalidade_60_69, na.rm = TRUE)
df$mortalidade_alta <- as.integer(df$mortalidade_60_69 > mediana)
cat("Mediana da mortalidade 60-69:", round(mediana, 4), "\n")
print(table(df$mortalidade_alta))

# ------------------------------------------------------- ajuste logístico
modelo_log <- glm(mortalidade_alta ~ pib_per_capita,
                  data = df, family = binomial(link = "logit"))
summary(modelo_log)

cat("\n--- Odds ratios ---\n")
print(exp(coef(modelo_log)))
cat("\n--- IC 95% para os coeficientes ---\n")
print(confint(modelo_log))
cat("\n--- IC 95% para os odds ratios ---\n")
print(exp(confint(modelo_log)))

ll_null <- logLik(update(modelo_log, . ~ 1))
ll_full <- logLik(modelo_log)
cat("\n--- Pseudo-R² de McFadden ---\n")
print(as.numeric(1 - (ll_full / ll_null)))

# --------------------------------------------------- curva sigmoide
grade <- seq(min(df$pib_per_capita), max(df$pib_per_capita), length.out = 300)
pred  <- predict(modelo_log, newdata = data.frame(pib_per_capita = grade),
                 type = "response")
curva <- data.frame(pib_per_capita = grade, prob = pred)

g <- ggplot() +
  geom_point(data = df,
             aes(x = pib_per_capita, y = mortalidade_alta),
             color = "steelblue", alpha = 0.5, size = 2) +
  geom_line(data = curva,
            aes(x = pib_per_capita, y = prob),
            color = "firebrick", linewidth = 1.1) +
  geom_hline(yintercept = 0.5, linetype = "dashed", color = "gray50") +
  labs(
    title = "Probabilidade estimada de mortalidade 60–69 acima da mediana",
    subtitle = "Curva logística ajustada sobre pontos observados (0/1)",
    x = "PIB per capita (R$ de 2024)",
    y = "P(mortalidade_alta = 1)"
  ) +
  theme_minimal(base_size = 12)
ggsave(file.path(caminho_fig, "fig2_logistica_sigmoide.png"),
       g, width = 9, height = 5.5, dpi = 150)