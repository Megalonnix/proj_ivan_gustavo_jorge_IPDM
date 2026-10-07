# ==============================================================================
# 2. REGRESSÃO LOGÍSTICA — Mortalidade alta ~ PIB per capita
# ==============================================================================
# Cobre as tarefas da Aula 5:
#   - Ajustar logística e ler razões de chance
#   - Prever probabilidade, classe (limiar 0,5) e matriz de confusão
#   - REPETIR com limiares 0,3 e 0,7 e comparar as matrizes
#   - AUC
#   - Discutir custo de FP vs. FN e escolha de limiar
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

# ---------------------------------------------------- variável binária alvo
mediana <- median(df$mortalidade_60_69, na.rm = TRUE)
df$mortalidade_alta <- as.integer(df$mortalidade_60_69 > mediana)
cat("Mediana da mortalidade 60-69:", round(mediana, 4), "\n")
print(table(df$mortalidade_alta))

# ------------------------------------------------------- ajuste logístico
modelo_log <- glm(mortalidade_alta ~ pib_per_capita,
                  data = df, family = binomial(link = "logit"))
summary(modelo_log)

cat("\n--- Coeficientes (escala do logit) ---\n")
print(coef(modelo_log))

cat("\n--- Odds ratios (por R$ 1,00) ---\n")
print(exp(coef(modelo_log)))

cat("\n--- Odds ratio por R$ 1.000 (leitura substantiva) ---\n")
print(exp(coef(modelo_log) * 1000))

cat("\n--- IC 95% para os coeficientes (logit) ---\n")
print(confint(modelo_log))

cat("\n--- IC 95% para os odds ratios (por R$ 1,00) ---\n")
print(exp(confint(modelo_log)))

# Pseudo-R² de McFadden
ll_null <- logLik(update(modelo_log, . ~ 1))
ll_full <- logLik(modelo_log)
cat("\n--- Pseudo-R² de McFadden ---\n")
print(as.numeric(1 - (ll_full / ll_null)))

# ==============================================================================
# DIAGNÓSTICO DA FORMA DA SIGMOIDE  <-- NOVO BLOCO
# ==============================================================================
# Por que a curva logística pode parecer "quase reta" em vez de um S bem
# desenhado? Porque a inclinação depende de β1 e da amplitude de X.
# Abaixo, quantificamos isso de forma explícita.

cat("\n========== DIAGNÓSTICO: FORMA DA SIGMOIDE ==========\n")

cat("\n--- Amplitude de X (PIB per capita) ---\n")
cat("Mínimo:", min(df$pib_per_capita), "\n")
cat("Máximo:", max(df$pib_per_capita), "\n")
cat("Amplitude:", diff(range(df$pib_per_capita)), "\n")

cat("\n--- Amplitude do preditor linear z = β0 + β1·X ---\n")
z <- predict(modelo_log)  # escala do logit
cat("z mínimo:", round(min(z), 4), "\n")
cat("z máximo:", round(max(z), 4), "\n")
cat("Amplitude de z:", round(diff(range(z)), 4), "\n")

cat("\n--- Amplitude das probabilidades previstas ---\n")
p <- predict(modelo_log, type = "response")
cat("p mínimo:", round(min(p), 4), "\n")
cat("p máximo:", round(max(p), 4), "\n")
cat("Amplitude de p:", round(diff(range(p)), 4), "\n")

cat("\n--- Interpretação automática ---\n")
amp_z <- diff(range(z))
if (amp_z < 2) {
  cat("Amplitude de z < 2 -> a sigmoide fica QUASE RETA (região linear da curva).\n")
  cat("Isso acontece porque β1 é pequeno: o logit varia pouco ao longo da faixa de X.\n")
} else if (amp_z < 6) {
  cat("Amplitude de z entre 2 e 6 -> sigmoide moderadamente curva.\n")
} else {
  cat("Amplitude de z > 6 -> sigmoide com S bem visível.\n")
}

cat("\n--- Tabela: mortalidade_alta por faixa de PIB ---\n")
faixas <- cut(df$pib_per_capita, breaks = 5, dig.lab = 6)
print(table(Faixa_PIB = faixas, Mortalidade_Alta = df$mortalidade_alta))

cat("\n--- Cubatão: onde ele cai? ---\n")
print(df %>% filter(Municipio == "Cubatão") %>%
        select(Municipio, Ano, pib_per_capita, mortalidade_60_69, mortalidade_alta))
# ==============================================================================

# ==============================================================================
# AVALIAÇÃO EM TRÊS LIMIARES (Aula 5, slides 20-21, 25 e 29)
# ==============================================================================
prob <- predict(modelo_log, type = "response")

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

resultados <- lapply(c(0.3, 0.5, 0.7), function(c) avaliar_limiar(prob, df$mortalidade_alta, c))
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

# ------------------------------------------------------ AUC (todos os limiares)
roc_obj <- pROC::roc(df$mortalidade_alta, prob,
                     levels = c(0, 1), direction = "<", quiet = TRUE)
cat("\n--- AUC (amostra completa) ---\n")
print(pROC::auc(roc_obj))

# ==============================================================================
# GRÁFICOS
# ==============================================================================
grade <- seq(min(df$pib_per_capita), max(df$pib_per_capita), length.out = 300)
pred  <- predict(modelo_log, newdata = data.frame(pib_per_capita = grade),
                 type = "response")
curva <- data.frame(pib_per_capita = grade, prob = pred)

g1 <- ggplot() +
  geom_point(data = df,
             aes(x = pib_per_capita, y = mortalidade_alta),
             color = "steelblue", alpha = 0.5, size = 2) +
  geom_line(data = curva,
            aes(x = pib_per_capita, y = prob),
            color = "firebrick", linewidth = 1.1) +
  geom_hline(yintercept = 0.5, linetype = "dashed", color = "gray50") +
  labs(
    title = "Probabilidade estimada de mortalidade 60-69 acima da mediana",
    subtitle = "Curva logística ajustada sobre pontos observados (0/1)",
    x = "PIB per capita (R$ de 2024)",
    y = "P(mortalidade_alta = 1)"
  ) +
  theme_minimal(base_size = 12) +
  theme(aspect.ratio = 1)
ggsave(file.path(caminho_fig, "fig2_logistica_sigmoide.png"),
       g1, width = 7, height = 7, dpi = 150)

png(file.path(caminho_fig, "fig2_logistica_roc.png"),
    width = 800, height = 800, res = 110)
plot(roc_obj, col = "firebrick", lwd = 2.2,
     main = "Curva ROC — amostra completa",
     xlab = "Especificidade (1 - FPR)",
     ylab = "Sensibilidade (TPR)",
     print.auc = TRUE, print.auc.cex = 1.1,
     legacy.axes = TRUE)
abline(a = 1, b = -1, lty = 2, col = "gray50")
dev.off()

# ==============================================================================
# SENSIBILIDADE — modelo logístico sem Cubatão
# ==============================================================================
df_sem_cub <- df %>% filter(Municipio != "Cubatão")

modelo_sem_cub <- glm(mortalidade_alta ~ pib_per_capita,
                      data = df_sem_cub, family = binomial(link = "logit"))

cat("\n--- Comparação dos coeficientes (escala do logit) ---\n")
cat("Com Cubatão: β1 =", coef(modelo_log)["pib_per_capita"],
    "| OR por R$ 1.000 =", exp(coef(modelo_log)["pib_per_capita"] * 1000), "\n")
cat("Sem Cubatão: β1 =", coef(modelo_sem_cub)["pib_per_capita"],
    "| OR por R$ 1.000 =", exp(coef(modelo_sem_cub)["pib_per_capita"] * 1000), "\n")

prob_sem_cub <- predict(modelo_sem_cub, type = "response")
roc_sem_cub <- pROC::roc(df_sem_cub$mortalidade_alta, prob_sem_cub,
                         levels = c(0, 1), direction = "<", quiet = TRUE)
cat("\n--- AUC (sem Cubatão) ---\n")
print(pROC::auc(roc_sem_cub))

cat("\nScript 2 concluído.\n")


# ==============================================================================
# MICRO-RELATÓRIO — SCRIPT 2 (Regressão Logística)
# ==============================================================================
# Documenta decisões metodológicas e leitura esperada dos resultados.
# NÃO é executado. Serve para redação do trabalho e releitura futura.
#
# ------------------------------------------------------------------------------
# 1. POR QUE DISCRETIZAR A MORTALIDADE EM ALTA/BAIXA?
# ------------------------------------------------------------------------------
# A regressão logística exige uma resposta binária. As duas opções típicas são:
#   (a) corte por mediana da amostra;  (b) corte por limiar clínico externo.
#
# Adotamos a mediana por dois motivos:
#   - Não existe consenso clínico para "mortalidade alta" nessa faixa etária.
#   - A mediana garante divisão 27/27 entre as classes, didaticamente limpa.
#
# Trade-off: discretizar descarta informação (a magnitude da mortalidade).
# Ganha-se em interpretação probabilística e comparabilidade com
# classificadores; perde-se em resolução.
#
# ------------------------------------------------------------------------------
# 2. LEITURA DO COEFICIENTE E DA RAZÃO DE CHANCES
# ------------------------------------------------------------------------------
# Os coeficientes do glm estão na escala do LOGIT (slide 17 da Aula 5).
# Para falar em "chances", usar exp(coef).
#
# Como o PIB tem escala em milhares de reais, a OR por R$ 1,00 é minúscula
# (≈ 1,000). A leitura substantiva é a OR por R$ 1.000 (elevando a 1000):
#   OR_1000 = exp(β1 * 1000)
# Leitura: cada R$ 1.000 adicionais de PIB multiplicam as CHANCES de
# mortalidade alta por OR_1000. Sinal esperado: β1 < 0 -> OR_1000 < 1 ->
# renda maior REDUZ as chances de mortalidade alta.
#
# ------------------------------------------------------------------------------
# 3. POR QUE A SIGMOIDE PODE PARECER QUASE RETA (não um S desenhado)?
# ------------------------------------------------------------------------------
# Este é o ponto mais contraintuitivo ao olhar o gráfico fig2_logistica_sigmoide.
# A explicação NÃO é que a logística "falhou" — é geométrica.
#
# A curva logística p = 1 / (1 + e^(-z)) tem a forma de S bem definida apenas
# quando z percorre uma faixa AMPLA (digamos, de -6 a +6). Se z varia pouco,
# ficamos presos na região CENTRAL da curva, que é praticamente LINEAR.
#
# O preditor linear é z = β0 + β1·X. Sua amplitude sobre a amostra é
#   Δz = β1 · (max(X) - min(X)).
# Se β1 é pequeno (associação fraca) e/ou a amplitude de X não é enorme,
# Δz fica pequeno, e a sigmoide aparece como um segmento quase reto.
#
# Neste banco, três fatores combinam para achatá-la:
#   (a) A associação PIB x mortalidade é fraca na amostra completa
#       (R² ~ 0,06 no linear -> β1 logístico também pequeno).
#   (b) A amplitude útil de X é dominada por Cubatão, mas Cubatão tem
#       mortalidade MÉDIA -> ele não ajuda a separar as classes, então o
#       logit não se inclina.
#   (c) Os 54 pontos são ruidosos: muitos pares (PIB alto, mortalidade alta)
#       e (PIB baixo, mortalidade baixa) convivem, então a fronteira de
#       decisão não se define com nitidez.
#
# O bloco "DIAGNÓSTICO: FORMA DA SIGMOIDE" acima imprime no console:
#   - amplitude de X;
#   - amplitude de z;
#   - amplitude de p;
#   - tabela de contingência (faixa de PIB x mortalidade_alta);
#   - posição de Cubatão.
#
# Como ler o diagnóstico:
#   - Amplitude de z < 2   -> sigmoide quase reta (é o caso se β1 for fraco).
#   - Amplitude de z 2 a 6 -> sigmoide moderadamente curvada.
#   - Amplitude de z > 6   -> sigmoide com S bem visível.
#
# Se a amplitude de p (probabilidades previstas) também for pequena
# (ex.: p variando entre 0,35 e 0,65), significa que o modelo NUNCA se
# convence de nada: a probabilidade prevista fica sempre perto de 0,5, e
# os pontos observados (0/1) ficam "longe" da curva — visualmente, a curva
# parece um risco horizontal no meio do gráfico.
#
# Isso NÃO é bug: é o retrato honesto de um preditor fraco em amostra
# pequena. A curva "achatada" é o espelho visual do Pseudo-R² de McFadden
# baixo. Comparar com o script 4 (treino/teste), onde a curva fica ainda
# mais plana por causa da redução amostral, reforça a leitura.
#
# ------------------------------------------------------------------------------
# 4. POR QUE TRÊS LIMIARES (0,3 / 0,5 / 0,7)?
# ------------------------------------------------------------------------------
# O slide 25 da Aula 5 é explícito: "o limiar segue o custo do erro".
# O limiar 0,5 é apenas um default — não é estatisticamente especial.
#
# Comportamento esperado ao varrer os limiares:
#   c = 0,3 (permissivo):     MAIS positivos previstos -> alta sensibilidade,
#                             baixa especificidade. Muitos FP, poucos FN.
#   c = 0,5 (equilibrado):    trade-off no meio da curva ROC.
#   c = 0,7 (conservador):    MENOS positivos previstos -> baixa sensibilidade,
#                             alta especificidade. Poucos FP, muitos FN.
#
# Observação importante para ESTE banco: se a curva sigmoide for quase reta
# e as probabilidades previstas ficarem concentradas perto de 0,5 (por
# exemplo, entre 0,35 e 0,65), os três limiares podem produzir matrizes
# MUITO PARECIDAS ou até IDÊNTICAS. Isso acontece porque poucos pontos têm
# probabilidade prevista fora da faixa [0,3; 0,7] — então mudar o limiar
# dentro dessa faixa quase não altera a classificação.
#
# Se isso ocorrer, é um achado substantivo, não uma falha: significa que
# o modelo tem tão pouca confiança em suas previsões que a decisão de
# negócio (mudar o limiar) não consegue extrair trade-offs diferentes.
# Registrar isso no relatório consolidado.
#
# ------------------------------------------------------------------------------
# 5. QUAL ERRO CUSTA MAIS CARO NESTE PROBLEMA?
# ------------------------------------------------------------------------------
# Pergunta do slide 29: qual erro (FP ou FN) custa mais caro?
#
# Definições no contexto:
#   - FP: classificar como "mortalidade alta" uma observação que é "baixa".
#   - FN: classificar como "mortalidade baixa" uma que é "alta".
#
# Interpretação substantiva (política pública):
#   - FP = alarme falso -> mobilizar recursos para um município/ano que NÃO
#     está em situação crítica. Custo: desperdício de orçamento e esforço.
#   - FN = alarme perdido -> NÃO mobilizar recursos para um município/ano
#     que ESTÁ em situação crítica. Custo: mortalidade evitável, perda humana.
#
# Neste contexto, o FN custa MUITO mais caro que o FP. Um município que
# precisa de intervenção e não é sinalizado perde vidas; um município
# sinalizado sem necessidade apenas recebe atenção redundante.
#
# Decisão recomendada: limiar MENOR que 0,5 (ex.: 0,3). Ser permissivo
# para sinalizar risco, aceitando mais FP em troca de menos FN.
#
# ------------------------------------------------------------------------------
# 6. AUC — O QUE ESPERAR
# ------------------------------------------------------------------------------
# Leitura rápida:
#   AUC = 0,5 -> chute aleatório.
#   AUC ~ 0,7 -> discriminação aceitável.
#   AUC >= 0,8 -> discriminação boa.
#
# Dada a fraqueza da associação na amostra completa (achado do script 1),
# espera-se AUC moderada (~0,6-0,7). Se for muito próxima de 0,5, o
# classificador não discrimina — o que é coerente com a sigmoide achatada.
#
# ------------------------------------------------------------------------------
# 7. SENSIBILIDADE — CUBATÃO
# ------------------------------------------------------------------------------
# Mesmo achado do script 1: Cubatão é caso atípico. Sem ele, a associação
# renda-mortalidade fica mais forte, e espera-se que a AUC suba. Comparar
# os dois AUC (com e sem) quantifica o quanto o ponto extremo atrapalha a
# discriminação nesta amostra.
#
# ------------------------------------------------------------------------------
# 8. AMARRAÇÃO COM OS DEMAIS SCRIPTS
# ------------------------------------------------------------------------------
# - O limiar 0,5 é o mesmo adotado no script 4 (treino/teste), para
#   comparabilidade das métricas.
# - A mediana usada aqui é a da AMOSTRA COMPLETA (27/27). No script 4,
#   mantemos essa mesma mediana (não a do treino), para que o alvo y seja
#   definido da mesma forma nos dois módulos.
# ==============================================================================
