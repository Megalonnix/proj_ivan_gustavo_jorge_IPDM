# =============================================================
# ATIVIDADE 06 - AVALIAÇÃO DE CLASSIFICAÇÃO: TREINO/TESTE E CV(5)
# =============================================================
# Pergunta: Escolaridade -> IPDM Alto (coluna_binaria)
# Padrão: Prof. Dr. João Paulo Ferreira de Mello (Base R First)
# Carregamento direto via GitHub
# =============================================================

# =============================================================
# PARTE 1 - LER E PREPARAR OS DADOS (DIRETO DO GITHUB)
# =============================================================
url_github <- "https://raw.githubusercontent.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/main/estrutura/bancoDeDados/df_ipdm_baixada_por_municipio.csv"
arquivo_local <- file.path("estrutura", "dataset", "df_ipdm_baixada_por_municipio.csv")

dados_brutos <- tryCatch({
  read.csv(url_github, sep = ";", dec = ",", fileEncoding = "latin1", check.names = FALSE, stringsAsFactors = FALSE)
}, error = function(e) {
  read.csv(arquivo_local, sep = ";", dec = ",", fileEncoding = "latin1", check.names = FALSE, stringsAsFactors = FALSE)
})

dados <- data.frame(
  cod_ibge          = factor(dados_brutos[[1]]),
  municipio         = factor(dados_brutos[[2]]),
  ano               = as.integer(dados_brutos[[3]]),
  escolaridade      = as.numeric(dados_brutos[[6]]),
  ipdm              = as.numeric(dados_brutos[[7]])
)

# Resposta binária: IPDM Alto (acima da mediana regional)
mediana_ipdm <- median(dados$ipdm)
dados$coluna_binaria <- as.integer(dados$ipdm > mediana_ipdm)

# Cores oficiais do professor
cazul    <- "#276DC3"
claranja <- "#E66101"
croxo    <- "#5E3C99"

# =============================================================
# PARTE 2 - DIVISÃO TREINO/TESTE (70/30) E AJUSTE LOGÍSTICO
# =============================================================
set.seed(1)
n <- nrow(dados)
idx_treino <- sample(seq_len(n), size = floor(0.7 * n))
treino <- dados[idx_treino, ]
teste  <- dados[-idx_treino, ]

m_treino <- glm(coluna_binaria ~ escolaridade, family = binomial, data = treino)

cat("\n================ RESUMO DO MODELO NO TREINO (70%) ================\n")
printCoefmat(coef(summary(m_treino)), signif.legend = FALSE)

# =============================================================
# PARTE 3 - AVALIAÇÃO FORA DA AMOSTRA (CONJUNTO DE TESTE)
# =============================================================
# Previsão rigorosa de probabilidade com type = "response"
prob_teste <- predict(m_treino, newdata = teste, type = "response")
yhat_teste <- as.integer(prob_teste > 0.5)

tab_teste <- table(
  real     = factor(teste$coluna_binaria, levels = c(0, 1)),
  previsto = factor(yhat_teste, levels = c(0, 1))
)

cat("\n================ MATRIZ DE CONFUSÃO NO TESTE (limiar = 0.5) ================\n")
print(tab_teste)

acc_teste <- sum(diag(tab_teste)) / sum(tab_teste)
sensibilidade <- if (sum(tab_teste["1", ]) > 0) tab_teste["1", "1"] / sum(tab_teste["1", ]) else NA_real_
especificidade <- if (sum(tab_teste["0", ]) > 0) tab_teste["0", "0"] / sum(tab_teste["0", ]) else NA_real_

cat("\nAcurácia no Teste:     ", round(acc_teste, 4), "\n")
cat("Sensibilidade no Teste:", round(sensibilidade, 4), "\n")
cat("Especificidade no Teste:", round(especificidade, 4), "\n")

# AUC no Teste via outer em Base R
auc_teste <- if (length(unique(teste$coluna_binaria)) > 1) {
  mean(outer(prob_teste[teste$coluna_binaria == 1], prob_teste[teste$coluna_binaria == 0], ">"))
} else {
  0.5
}
cat("AUC no Teste:          ", round(auc_teste, 4), "\n")

cat("\n================ MATRIZES DE TESTE NOS LIMIARES 0.3 / 0.5 / 0.7 ================\n")
for (L in c(0.3, 0.5, 0.7)) {
  yh <- as.integer(prob_teste > L)
  cat("\n--- limiar =", L, "---\n")
  print(table(real = teste$coluna_binaria, previsto = yh))
}

# =============================================================
# PARTE 4 - GRÁFICOS: CURVA LOGÍSTICA E ROC NO TESTE
# =============================================================

# Gráfico 1: Curva Logística (Treino) vs Pontos de Teste
par(mar = c(4, 4, 1, 1), pty = "s")
grade <- seq(min(dados$escolaridade), max(dados$escolaridade), length.out = 300)
pred_grade <- predict(m_treino, newdata = data.frame(escolaridade = grade), type = "response")

plot(teste$escolaridade, teste$coluna_binaria, pch = 19, col = claranja,
     xlab = "Escolaridade [índice 0-1]", ylab = "P(IPDM Alto = 1)",
     main = "Curva Logística (Treino) vs Teste")
lines(grade, pred_grade, col = cazul, lwd = 3)
abline(h = 0.5, lty = 2, col = "gray40", lwd = 2)
legend("topleft", legend = c("Pontos de Teste (30%)", "Curva Estimada (Treino)", "Limiar c = 0.5"),
       col = c(claranja, cazul, "gray40"), pch = c(19, NA, NA),
       lwd = c(NA, 3, 2), lty = c(NA, 1, 2), bty = "n")

# Gráfico 2: Curva ROC no conjunto de teste em Base R
ord_t <- order(prob_teste, decreasing = TRUE)
tpr_t <- cumsum(teste$coluna_binaria[ord_t]) / sum(teste$coluna_binaria)
fpr_t <- cumsum(1 - teste$coluna_binaria[ord_t]) / sum(1 - teste$coluna_binaria)

par(mar = c(4, 4, 1, 1), pty = "s")
plot(c(0, fpr_t), c(0, tpr_t), type = "l", lwd = 3, col = claranja,
     xlab = "Taxa de Falsos Positivos (FPR)", ylab = "Taxa de Verdadeiros Positivos (TPR)",
     main = sprintf("ROC Teste (AUC = %.4f)", auc_teste))
abline(0, 1, lty = 2, col = "gray50", lwd = 2)
for (L in c(0.7, 0.5, 0.3)) {
  points(mean(prob_teste[teste$coluna_binaria == 0] > L),
         mean(prob_teste[teste$coluna_binaria == 1] > L),
         pch = 19, cex = 1.2, col = croxo)
}

# =============================================================
# PARTE 5 - VALIDAÇÃO CRUZADA k-FOLD (k = 5) MANUAL EM BASE R
# =============================================================
k <- 5
set.seed(1)
dobra <- sample(rep(1:k, length = nrow(dados)))
acc_cv <- numeric(k)
acc_cv_base <- numeric(k)
auc_cv <- numeric(k)

for (j in 1:k) {
  tr <- dados[dobra != j, ]
  te <- dados[dobra == j, ]
  
  m_cv <- glm(coluna_binaria ~ escolaridade, data = tr, family = binomial)
  p_cv <- predict(m_cv, newdata = te, type = "response")
  yhat <- as.integer(p_cv > 0.5)
  
  acc_cv[j] <- mean(yhat == te$coluna_binaria)
  maj <- as.integer(mean(tr$coluna_binaria) >= 0.5)
  acc_cv_base[j] <- mean(maj == te$coluna_binaria)
  
  if (length(unique(te$coluna_binaria)) > 1) {
    auc_cv[j] <- mean(outer(p_cv[te$coluna_binaria == 1], p_cv[te$coluna_binaria == 0], ">"))
  } else {
    auc_cv[j] <- 0.5
  }
}

mean_acc_cv <- mean(acc_cv)
mean_acc_cv_base <- mean(acc_cv_base)
mean_auc_cv <- mean(auc_cv)

cat("\n================ VALIDAÇÃO CRUZADA k-FOLD (k = 5) ================\n")
cat("Acurácia Média CV(5):          ", round(mean_acc_cv * 100, 2), "%\n")
cat("Acurácia Linha de Base CV(5):  ", round(mean_acc_cv_base * 100, 2), "%\n")
cat("AUC Médio CV(5):               ", round(mean_auc_cv, 4), "\n")

# =============================================================
# Fim do script
# =============================================================
