# ==============================================================================
# 4. REGRESSÃO LOGÍSTICA — Treino/Teste (70/30, mesmo split do script 3)
# ==============================================================================
# Cobre as tarefas da Aula 5 no contexto out-of-sample:
#   - Split idêntico ao script 3 (mesmo seed, mesma chamada sample)
#   - Alvo binário pela MESMA mediana da amostra completa (script 2)
#   - Ajuste APENAS no treino
#   - Previsões no teste: probabilidade + classe em três limiares (0.3/0.5/0.7)
#   - Matriz de confusão, acurácia, sensibilidade, especificidade, precisão
#   - Curva ROC + AUC
#   - Sensibilidade sem Cubatão
#
# CONVENÇÃO: todo bloco que gera figura vem precedido de um bloco
# "DIAGNÓSTICO VISUAL" que imprime os números necessários para descrever a
# figura sem vê-la.
# ==============================================================================

if (!require('pacman')) install.packages('pacman')
pacman::p_load(readr, dplyr, ggplot2, pROC)

# ------------------------------------------------------------------- caminhos
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

# --- alvo binário com a MESMA mediana da amostra completa (script 2)
mediana <- median(df$mortalidade_60_69, na.rm = TRUE)
df$mortalidade_alta <- as.integer(df$mortalidade_60_69 > mediana)
cat("Mediana (amostra completa):", round(mediana, 4), "\n")
cat("Distribuição do alvo (amostra completa):\n")
print(table(df$mortalidade_alta))

# ------------------------------------------------- split 70/30 idêntico
set.seed(42)
n <- nrow(df)
idx_treino <- sample(seq_len(n), size = floor(0.7 * n))
treino <- df[idx_treino, ]
teste  <- df[-idx_treino, ]
cat("\nTreino:", nrow(treino), "| Teste:", nrow(teste), "\n")
cat("Positivos treino:", sum(treino$mortalidade_alta),
    "| Positivos teste:", sum(teste$mortalidade_alta), "\n")

# ------------------------------------------------- ajuste logístico no treino
modelo_treino <- glm(mortalidade_alta ~ pib_per_capita,
                     data = treino, family = binomial(link = "logit"))
summary(modelo_treino)

cat("\n--- Coeficientes (treino, escala do logit) ---\n")
print(coef(modelo_treino))

cat("\n--- Odds ratios (treino, por R$ 1.000) ---\n")
print(exp(coef(modelo_treino) * 1000))

# -------------------------------------------- previsões no conjunto de teste
prob_teste   <- predict(modelo_treino, newdata = teste, type = "response")
classe_teste <- as.integer(prob_teste > 0.5)

# ==============================================================================
# DIAGNÓSTICO VISUAL — Faixa de probabilidades previstas no treino e no teste
# ==============================================================================
# Necessário para descrever a sigmoide (fig4_logistica_sigmoide_teste.png).

cat("\n========== DIAGNÓSTICO VISUAL — PREVISÕES NO TESTE ==========\n")

cat("\n--- Faixa das probabilidades previstas no TESTE ---\n")
print(summary(prob_teste))
cat("range:", range(prob_teste), "\n")

cat("\n--- Faixa das probabilidades previstas no TREINO ---\n")
prob_treino <- predict(modelo_treino, type = "response")
print(summary(prob_treino))
cat("range:", range(prob_treino), "\n")

cat("\n--- Amplitude de z (logit) no treino ---\n")
z_treino <- predict(modelo_treino)
cat("z mínimo:", round(min(z_treino), 4), "\n")
cat("z máximo:", round(max(z_treino), 4), "\n")
cat("Amplitude de z:", round(diff(range(z_treino)), 4), "\n")

cat("\n--- Previsões corretas vs. erradas no teste (limiar 0.5) ---\n")
cat("Previu 0:", sum(classe_teste == 0), "| Previu 1:", sum(classe_teste == 1), "\n")
cat("Observado 0:", sum(teste$mortalidade_alta == 0),
    "| Observado 1:", sum(teste$mortalidade_alta == 1), "\n")

# ==============================================================================
# MATRIZ DE CONFUSÃO E MÉTRICAS EM TRÊS LIMIARES
# ==============================================================================
avaliar_limiar <- function(prob, y, c) {
  yhat <- as.integer(prob > c)
  tab <- table(
    Predito = factor(yhat, levels = c(0, 1)),
    Real    = factor(y,    levels = c(0, 1))
  )
  VP <- tab["1","1"]; VN <- tab["0","0"]
  FP <- tab["1","0"]; FN <- tab["0","1"]
  acuracia      <- (VP + VN) / sum(tab)
  sensibilidade <- if ((VP + FN) > 0) VP / (VP + FN) else NA_real_
  especificidade<- if ((VN + FP) > 0) VN / (VN + FP) else NA_real_
  precisao      <- if ((VP + FP) > 0) VP / (VP + FP) else NA_real_
  list(limiar = c, tab = tab,
       acuracia = acuracia, sens = sensibilidade,
       espec = especificidade, prec = precisao)
}

resultados <- lapply(c(0.3, 0.5, 0.7),
                     function(c) avaliar_limiar(prob_teste, teste$mortalidade_alta, c))
names(resultados) <- c("c=0.3", "c=0.5", "c=0.7")

for (nome in names(resultados)) {
  r <- resultados[[nome]]
  cat("\n========== Limiar", r$limiar, "==========\n")
  print(r$tab)
  cat("Acurácia      :", round(r$acuracia, 4), "\n")
  cat("Sensibilidade :", round(r$sens, 4), "\n")
  cat("Especificidade:", round(r$espec, 4), "\n")
  cat("Precisão      :", round(r$prec, 4), "\n")
}

# ------------------------------------------------------ curva ROC e AUC
roc_obj <- pROC::roc(teste$mortalidade_alta, prob_teste,
                     levels = c(0, 1), direction = "<", quiet = TRUE)
cat("\n--- AUC (teste) ---\n")
print(pROC::auc(roc_obj))

# ==============================================================================
# DIAGNÓSTICO VISUAL — SIGMOIDE NO TREINO + PONTOS DE TESTE
# ==============================================================================
# Necessário para descrever fig4_logistica_sigmoide_teste.png.

cat("\n========== DIAGNÓSTICO VISUAL — SIGMOIDE ==========\n")

cat("\n--- Amplitude da sigmoide no treino ---\n")
cat("Amplitude de z (treino):", round(diff(range(z_treino)), 4), "\n")
cat("Se < 2 -> sigmoide quase reta.\n")

cat("\n--- Cubatão no teste: onde cai? ---\n")
print(teste %>% filter(Municipio == "Cubatão") %>%
        select(Ano, pib_per_capita, mortalidade_60_69, mortalidade_alta))

# ==============================================================================
# GRÁFICO 1 — Sigmoide ajustada no treino sobre pontos de teste
# ==============================================================================
grade <- seq(min(df$pib_per_capita), max(df$pib_per_capita), length.out = 300)
pred_curva <- predict(modelo_treino,
                      newdata = data.frame(pib_per_capita = grade),
                      type = "response")
curva <- data.frame(pib_per_capita = grade, prob = pred_curva)

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
  theme_minimal(base_size = 12) +
  theme(aspect.ratio = 1)
ggsave(file.path(caminho_fig, "fig4_logistica_sigmoide_teste.png"),
       g1, width = 7, height = 7, dpi = 150)

# ==============================================================================
# GRÁFICO 2 — Matriz de confusão visual (limiar 0.5)
# ==============================================================================
tab_05 <- resultados[["c=0.5"]]$tab

# DIAGNÓSTICO VISUAL — matriz
cat("\n========== DIAGNÓSTICO VISUAL — MATRIZ DE CONFUSÃO (c=0.5) ==========\n")
print(tab_05)

df_conf <- as.data.frame(tab_05)
df_conf$Predito <- factor(df_conf$Predito, levels = c("0", "1"))
df_conf$Real    <- factor(df_conf$Real,    levels = c("0", "1"))

g2 <- ggplot(df_conf, aes(x = Real, y = Predito, fill = Freq)) +
  geom_tile(color = "white", linewidth = 1) +
  geom_text(aes(label = Freq), color = "white", size = 6, fontface = "bold") +
  scale_fill_gradient(low = "steelblue", high = "firebrick") +
  labs(
    title = "Matriz de confusão — conjunto de teste (c = 0,5)",
    subtitle = "0 = mortalidade abaixo da mediana | 1 = acima",
    x = "Real", y = "Predito"
  ) +
  theme_minimal(base_size = 12) +
  theme(legend.position = "none", aspect.ratio = 1)
ggsave(file.path(caminho_fig, "fig4_logistica_matriz_confusao.png"),
       g2, width = 7, height = 7, dpi = 150)

# ==============================================================================
# GRÁFICO 3 — Curva ROC
# ==============================================================================
png(file.path(caminho_fig, "fig4_logistica_roc.png"),
    width = 800, height = 800, res = 110)
plot(roc_obj,
     col = "firebrick", lwd = 2.2,
     main = "Curva ROC — conjunto de teste",
     xlab = "Especificidade (1 - FPR)",
     ylab = "Sensibilidade (TPR)",
     print.auc = TRUE, print.auc.cex = 1.1,
     legacy.axes = TRUE)
abline(a = 1, b = -1, lty = 2, col = "gray50")
dev.off()

# ==============================================================================
# SENSIBILIDADE — logística sem Cubatão
# ==============================================================================
df_sem_cub <- df %>% filter(Municipio != "Cubatão")

set.seed(42)
n_sc <- nrow(df_sem_cub)
idx_treino_sc <- sample(seq_len(n_sc), size = floor(0.7 * n_sc))
treino_sc <- df_sem_cub[idx_treino_sc, ]
teste_sc  <- df_sem_cub[-idx_treino_sc, ]

modelo_treino_sc <- glm(mortalidade_alta ~ pib_per_capita,
                        data = treino_sc, family = binomial(link = "logit"))

prob_teste_sc <- predict(modelo_treino_sc, newdata = teste_sc, type = "response")
roc_sc <- pROC::roc(teste_sc$mortalidade_alta, prob_teste_sc,
                    levels = c(0, 1), direction = "<", quiet = TRUE)

cat("\n--- Comparação com/sem Cubatão (mesmo split seed) ---\n")
cat("Com Cubatão: β1 =", coef(modelo_treino)["pib_per_capita"],
    "| AUC teste =", round(as.numeric(pROC::auc(roc_obj)), 4), "\n")
cat("Sem Cubatão: β1 =", coef(modelo_treino_sc)["pib_per_capita"],
    "| AUC teste =", round(as.numeric(pROC::auc(roc_sc)), 4), "\n")

cat("\nScript 4 concluído.\n")


# ==============================================================================
# MICRO-RELATÓRIO — SCRIPT 4 (Regressão Logística Treino/Teste)
# ==============================================================================
# Documenta decisões metodológicas e leitura esperada dos resultados.
# NÃO é executado. Serve para redação do trabalho e releitura futura.
#
# ------------------------------------------------------------------------------
# 1. POR QUE O MESMO SPLIT DO SCRIPT 3?
# ------------------------------------------------------------------------------
# set.seed(42) e sample() idênticos aos do script 3. Isso garante que os
# dois modelos (linear e logístico) são avaliados EXATAMENTE nas mesmas
# 17 observações de teste. Comparação legítima: qualquer diferença de
# desempenho é atribuível ao modelo, não à amostra.
#
# ------------------------------------------------------------------------------
# 2. POR QUE A MEDIANA DA AMOSTRA COMPLETA (E NÃO DO TREINO)?
# ------------------------------------------------------------------------------
# A mediana usada para definir mortalidade_alta é a da amostra completa
# (script 2): 19,40 por mil hab. Se usássemos a mediana do treino:
#   - O limiar de corte mudaria.
#   - As proporções de positivos no treino e teste ficariam artificiais.
#   - A comparação com o script 2 (amostra completa) seria confundida.
#
# Mantendo a mediana da amostra completa, o alvo y é definido de forma
# IDÊNTICA nos scripts 2 e 4. A diferença entre eles é só a amostra usada no
# ajuste.
#
# ------------------------------------------------------------------------------
# 3. LEITURA DA SIGMOIDE
# ------------------------------------------------------------------------------
# Como no script 2, a sigmoide pode parecer quase reta. A explicação é a
# mesma: β1 pequeno -> amplitude de z pequena -> ficamos presos na região
# central da curva. O bloco "DIAGNÓSTICO VISUAL — SIGMOIDE" imprime a
# amplitude de z no treino.
#
# Diferença em relação ao script 2: aqui, β1 pode ser ainda mais fraco
# (menos dados no treino), então a sigmoide tende a ficar ainda mais plana.
#
# ------------------------------------------------------------------------------
# 4. TRÊS LIMIARES (0.3 / 0.5 / 0.7)
# ------------------------------------------------------------------------------
# Mesmo racional do script 2: o limiar é decisão de negócio, não estatística.
# Em amostra pequena (17 obs no teste), as matrizes são MUITO instáveis —
# cada observação vale ~6% da acurácia.
#
# Leitura esperada:
#   c = 0,3: mais positivos -> alta sensibilidade, baixa especificidade.
#   c = 0,5: equilíbrio.
#   c = 0,7: se as probabilidades previstas não atingem 0,7, colapso em
#            classe 0 (sensibilidade zero).
#
# ------------------------------------------------------------------------------
# 5. AUC NO TESTE
# ------------------------------------------------------------------------------
# Diferente do script 2 (AUC na amostra completa), aqui medimos a AUC
# out-of-sample: quão bem o modelo treinado discrimina no teste.
#
# Em amostra pequena, a AUC é MUITO instável — 17 observações com 27/27
# balanceado significam que um único ponto trocado muda a AUC em ~0,06.
#
# ------------------------------------------------------------------------------
# 6. DIAGNÓSTICO VISUAL — O QUE AS FIGURAS MOSTRAM
# ------------------------------------------------------------------------------
# Figura 4a (sigmoide + pontos de teste):
#   - Curva ajustada no treino (vermelha), pontos de teste (laranja).
#   - Se a curva é quase reta, e as probabilidades previstas ficam
#     concentradas num intervalo estreito, os pontos de teste parecem
#     "flutuar" longe da curva.
#
# Figura 4b (matriz de confusão, c=0.5):
#   - Heatmap 2x2 com contagens.
#   - Diagonal principal (canto sup. esq. + canto inf. dir.) = acertos.
#   - Diagonal secundária = erros (FP + FN).
#
# Figura 4c (curva ROC):
#   - Curva do TPR vs. FPR para todos os limiares.
#   - AUC anotada no gráfico.
#   - Diagonal tracejada = classificador aleatório.
#
# ------------------------------------------------------------------------------
# 7. SENSIBILIDADE — SEM CUBATÃO
# ------------------------------------------------------------------------------
# Mesmo achado dos scripts 1-3: Cubatão mascara a relação. Sem ele, β1
# fica mais forte e a AUC tende a subir. Mas o split muda quando removemos
# Cubatão (o set.seed(42) é aplicado a uma amostra com 6 obs a menos),
# então a comparação é COMPLEMENTAR, não controlada.
#
# ------------------------------------------------------------------------------
# 8. LIMITAÇÕES ESTRUTURAIS
# ------------------------------------------------------------------------------
# (a) Amostra pequena: 37/17. Métricas muito voláteis.
# (b) Split por LINHA, não por município. Vazamento de identidade do
#     município entre treino e teste.
# (c) Autocorrelação temporal (anos consecutivos do mesmo município).
# (d) Instabilidade do AUC e das matrizes: cada obs vale ~6% da acurácia.
# (e) Discretização pela mediana: descarta informação de magnitude.
#
# Direções de aprofundamento:
#   - Split por município (leave-one-municipality-out).
#   - Validação cruzada agrupada por município.
#   - Modelos com efeitos fixos por município.
#   - Curva de calibração (não só ROC).
#
# ------------------------------------------------------------------------------
# 9. AMARRAÇÃO COM OS DEMAIS SCRIPTS
# ------------------------------------------------------------------------------
# - Split idêntico ao script 3.
# - Mediana idêntica ao script 2.
# - O achado transversal (Cubatão mascara a relação) reaparece aqui.
# - A comparação script 3 vs. script 4 (linear vs. logístico, mesmas
#   observações de teste) sustenta a conclusão consolidada.
# ==============================================================================