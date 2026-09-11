# ==============================================================================
# REGRESSÃO LOGÍSTICA — Treino/Teste (70/30, mesmo split do script 3)
# ==============================================================================
if (!require('pacman')) install.packages('pacman')
pacman::p_load(readr, dplyr, ggplot2, pROC)

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

# --- alvo binário com a MESMA mediana da amostra completa (script 2)
mediana <- median(df$mortalidade_60_69, na.rm = TRUE)
df$mortalidade_alta <- as.integer(df$mortalidade_60_69 > mediana)
cat("Mediana (amostra completa):", round(mediana, 4), "\n")

# ------------------------------------------------- split 70/30 idêntico
set.seed(42)
n <- nrow(df)
idx_treino <- sample(seq_len(n), size = floor(0.7 * n))
treino <- df[idx_treino, ]
teste  <- df[-idx_treino, ]
cat("Treino:", nrow(treino), "| Teste:", nrow(teste), "\n")
cat("Positivos treino:", sum(treino$mortalidade_alta),
    "| Positivos teste:", sum(teste$mortalidade_alta), "\n")

# ------------------------------------------------- ajuste logístico no treino
modelo_treino <- glm(mortalidade_alta ~ pib_per_capita,
                     data = treino, family = binomial(link = "logit"))
summary(modelo_treino)
cat("\n--- Odds ratios (treino) ---\n")
print(exp(coef(modelo_treino)))

# -------------------------------------------- previsões no conjunto de teste
prob_teste   <- predict(modelo_treino, newdata = teste, type = "response")
classe_teste <- as.integer(prob_teste > 0.5)

# ------------------------------------------------- matriz de confusão
# Força 2x2 mesmo que o modelo preveja só uma classe
tab <- table(
  Predito = factor(classe_teste,            levels = c(0, 1)),
  Real    = factor(teste$mortalidade_alta,  levels = c(0, 1))
)
print(tab)

acuracia <- sum(diag(tab)) / sum(tab)
sensibilidade  <- if (sum(tab[, "1"]) > 0) tab["1","1"] / sum(tab[, "1"]) else NA_real_
especificidade <- if (sum(tab[, "0"]) > 0) tab["0","0"] / sum(tab[, "0"]) else NA_real_

cat("\n--- Métricas no teste ---\n")
cat("Acurácia      :", round(acuracia, 4), "\n")
cat("Sensibilidade :", round(sensibilidade, 4), "\n")
cat("Especificidade:", round(especificidade, 4), "\n")

# ------------------------------------------------------ curva ROC
roc_obj <- pROC::roc(teste$mortalidade_alta, prob_teste,
                     levels = c(0, 1), direction = "<", quiet = TRUE)
cat("\n--- AUC ---\n"); print(pROC::auc(roc_obj))

# -------------------------------------- gráfico 1: sigmoide + pontos de teste
grade <- seq(min(df$pib_per_capita), max(df$pib_per_capita), length.out = 300)
pred  <- predict(modelo_treino,
                 newdata = data.frame(pib_per_capita = grade),
                 type = "response")
curva <- data.frame(pib_per_capita = grade, prob = pred)

g1 <- ggplot() +
  geom_point(data = teste,
             aes(x = pib_per_capita, y = mortalidade_alta),
             color = "darkorange", alpha = 0.85, size = 2.4) +
  geom_line(data = curva,
            aes(x = pib_per_capita, y = prob),
            color = "firebrick", linewidth = 1.1) +
  geom_hline(yintercept = 0.5, linetype = "dashed", color = "gray50") +
  labs(
    title = "Curva logística ajustada no treino — pontos de teste sobrepostos",
    subtitle = "Pontos laranja = observações do conjunto de teste",
    x = "PIB per capita (R$ de 2024)",
    y = "P(mortalidade_alta = 1)"
  ) +
  theme_minimal(base_size = 12)
ggsave(file.path(caminho_fig, "fig4_logistica_sigmoide_teste.png"),
       g1, width = 9, height = 5.5, dpi = 150)

# -------------------------------------- gráfico 2: matriz de confusão visual
df_conf <- as.data.frame(tab)
df_conf$Predito <- factor(df_conf$Predito, levels = c("0", "1"))
df_conf$Real    <- factor(df_conf$Real,    levels = c("0", "1"))

g2 <- ggplot(df_conf, aes(x = Real, y = Predito, fill = Freq)) +
  geom_tile(color = "white", linewidth = 1) +
  geom_text(aes(label = Freq), color = "white", size = 6, fontface = "bold") +
  scale_fill_gradient(low = "steelblue", high = "firebrick") +
  labs(
    title = "Matriz de confusão — conjunto de teste",
    subtitle = "0 = mortalidade abaixo da mediana | 1 = acima",
    x = "Real", y = "Predito"
  ) +
  theme_minimal(base_size = 12) +
  theme(legend.position = "none")
ggsave(file.path(caminho_fig, "fig4_logistica_matriz_confusao.png"),
       g2, width = 6, height = 5, dpi = 150)

# -------------------------------------- gráfico 3: curva ROC
png(file.path(caminho_fig, "fig4_logistica_roc.png"),
    width = 900, height = 800, res = 130)
plot(roc_obj,
     col = "firebrick", lwd = 2.2,
     main = "Curva ROC — conjunto de teste",
     xlab = "Especificidade (1 - FPR)",
     ylab = "Sensibilidade (TPR)",
     print.auc = TRUE, print.auc.cex = 1.1,
     legacy.axes = TRUE)
abline(a = 1, b = -1, lty = 2, col = "gray50")
dev.off()