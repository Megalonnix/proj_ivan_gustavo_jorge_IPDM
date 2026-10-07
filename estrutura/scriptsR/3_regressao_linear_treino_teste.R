# ==============================================================================
# 3. REGRESSÃO LINEAR — Treino/Teste (70/30)
# ==============================================================================
# Cobre as tarefas da Aula 4 no contexto out-of-sample:
#   - Split reprodutível (set.seed), ajuste APENAS no treino
#   - Métricas de erro no teste: RMSE, MAE, R²
#   - Comparação R² treino vs. R² teste (checagem de sobreajuste)
#   - Gráfico quadrado: reta treino sobre pontos de teste
#   - Gráfico quadrado: previsto vs. real
#   - Sensibilidade: mesmo exercício sem Cubatão
#
# CONVENÇÃO (a partir deste script): todo bloco que gera figura vem seguido
# de um bloco "DIAGNÓSTICO VISUAL" que imprime no console os números
# necessários para descrever a figura sem vê-la. Objetivo: permitir
# interpretação e redação do consolidado com base só no output textual.
# ==============================================================================

if (!require('pacman')) install.packages('pacman')
pacman::p_load(readr, dplyr, ggplot2)

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

# ----------------------------------------------------------- split 70/30
# ATENÇÃO: mesmo set.seed(42) e mesma chamada sample() do script 4.
# Isso garante que os dois modelos são avaliados EXATAMENTE nas mesmas
# observações de teste, permitindo comparação direta entre linear e logística.
set.seed(42)
n <- nrow(df)
idx_treino <- sample(seq_len(n), size = floor(0.7 * n))
treino <- df[idx_treino, ]
teste  <- df[-idx_treino, ]
cat("Treino:", nrow(treino), "| Teste:", nrow(teste), "\n")

# ------------------------------------------- onde Cubatão caiu no split?
cat("\n--- Composição do teste (municípios) ---\n")
print(table(teste$Municipio))
cat("\n--- Cubatão está no treino ou no teste? ---\n")
print(df[idx_treino, ] %>% filter(Municipio == "Cubatão") %>%
        select(Municipio, Ano, pib_per_capita))
cat("(se vazio acima -> Cubatão está no TESTE)\n")
print(df[-idx_treino, ] %>% filter(Municipio == "Cubatão") %>%
        select(Municipio, Ano, pib_per_capita))
cat("(se vazio acima -> Cubatão está no TREINO)\n")

# -------------------------------------------------------- ajuste no treino
modelo_treino <- lm(mortalidade_60_69 ~ pib_per_capita, data = treino)
summary(modelo_treino)

cat("\n--- Coeficientes (treino) ---\n")
print(coef(modelo_treino))
cat("\n--- R² (treino) ---\n")
print(summary(modelo_treino)$r.squared)
cat("\n--- R² ajustado (treino) ---\n")
print(summary(modelo_treino)$adj.r.squared)

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

cat("\n--- Comparação R² treino vs. teste ---\n")
cat("R² treino:", round(summary(modelo_treino)$r.squared, 4), "\n")
cat("R² teste :", round(r2_teste, 4), "\n")
cat("(diferença grande -> possível sobreajuste; diferença pequena -> modelo estável)\n")

# ==============================================================================
# DIAGNÓSTICO VISUAL — FIGURA 3a (reta treino sobre teste)
# ==============================================================================
# Imprime os números necessários para descrever a figura fig3_linear_teste_reta.png
# sem precisar vê-la.

cat("\n========== DIAGNÓSTICO VISUAL — FIG 3a (reta treino x teste) ==========\n")

cat("\n--- Reta ajustada no treino ---\n")
cat("Intercepto:  ", round(coef(modelo_treino)[1], 4), "\n")
cat("Inclinação:  ", coef(modelo_treino)[2], "\n")
cat("Faixa de X (treino):", min(treino$pib_per_capita),
    "a", max(treino$pib_per_capita), "\n")
cat("Faixa de X (teste): ", min(teste$pib_per_capita),
    "a", max(teste$pib_per_capita), "\n")

# Valores previstos pela reta nos extremos da faixa de X (do banco completo)
reta_min <- coef(modelo_treino)[1] + coef(modelo_treino)[2] * min(df$pib_per_capita)
reta_max <- coef(modelo_treino)[1] + coef(modelo_treino)[2] * max(df$pib_per_capita)
cat("\n--- Altura da reta nos extremos do PIB ---\n")
cat("Em PIB mínimo:", round(reta_min, 4), "\n")
cat("Em PIB máximo:", round(reta_max, 4), "\n")
cat("Δy da reta sobre a faixa inteira:", round(reta_max - reta_min, 4),
    "(se pequeno -> reta quase horizontal)\n")

cat("\n--- Distribuição de Y (mortalidade) no treino ---\n")
print(summary(treino$mortalidade_60_69))
cat("\n--- Distribuição de Y (mortalidade) no teste ---\n")
print(summary(teste$mortalidade_60_69))

cat("\n--- Onde Cubatão cai em X e Y no split? ---\n")
cat("Treino (Cubatão):\n")
print(treino %>% filter(Municipio == "Cubatão") %>%
        select(Ano, pib_per_capita, mortalidade_60_69))
cat("Teste (Cubatão):\n")
print(teste %>% filter(Municipio == "Cubatão") %>%
        select(Ano, pib_per_capita, mortalidade_60_69))

# ==============================================================================
# GRÁFICO 1 — Reta treino sobre pontos de teste
# ==============================================================================
g1 <- ggplot() +
  geom_point(data = treino,
             aes(x = pib_per_capita, y = mortalidade_60_69, color = "Treino"),
             size = 1.8, alpha = 0.35) +
  geom_point(data = teste,
             aes(x = pib_per_capita, y = mortalidade_60_69, color = "Teste"),
             size = 2.6, alpha = 0.9) +
  geom_smooth(data = treino,
              aes(x = pib_per_capita, y = mortalidade_60_69),
              method = "lm", se = TRUE, color = "firebrick",
              fill = "firebrick", alpha = 0.15) +
  scale_color_manual(values = c("Treino" = "gray50", "Teste" = "darkorange")) +
  labs(
    title = "Reta ajustada no treino sobre os pontos de teste",
    x = "PIB per capita (R$ de 2024)",
    y = "Mortalidade 60-69 (por mil hab.)",
    color = NULL
  ) +
  theme_minimal(base_size = 12) +
  theme(legend.position = "top", aspect.ratio = 1)
ggsave(file.path(caminho_fig, "fig3_linear_teste_reta.png"),
       g1, width = 7, height = 7, dpi = 150)

# ==============================================================================
# DIAGNÓSTICO VISUAL — FIGURA 3b (previsto vs. real)
# ==============================================================================

cat("\n========== DIAGNÓSTICO VISUAL — FIG 3b (previsto x real) ==========\n")

cat("\n--- Faixa das PREVISÕES no teste ---\n")
print(summary(pred_teste))
cat("range:", range(pred_teste), "\n")

cat("\n--- Faixa do REAL no teste ---\n")
print(summary(teste$mortalidade_60_69))
cat("range:", range(teste$mortalidade_60_69), "\n")

cat("\n--- Amplitude comparada ---\n")
cat("Amplitude das previsões:", diff(range(pred_teste)), "\n")
cat("Amplitude do real:      ", diff(range(teste$mortalidade_60_69)), "\n")
cat("Razão (real/previsto):  ",
    diff(range(teste$mortalidade_60_69)) / diff(range(pred_teste)), "\n")
cat("(razão >> 1 -> previsões achatadas, real disperso -> faixa horizontal)\n")

cat("\n--- Correlação previsto x real no teste ---\n")
cat("cor =", round(cor(pred_teste, teste$mortalidade_60_69), 4), "\n")
cat("(cor próxima de 0 -> nenhuma associação linear detectada)\n")

cat("\n--- Os 5 maiores erros absolutos no teste ---\n")
df_erros <- data.frame(
  Municipio = teste$Municipio,
  Ano       = teste$Ano,
  PIB       = round(teste$pib_per_capita),
  Real      = round(teste$mortalidade_60_69, 2),
  Previsto  = round(pred_teste, 2),
  Erro      = round(erro, 2)
) %>% arrange(desc(abs(Erro)))
print(head(df_erros, 5))

# ==============================================================================
# GRÁFICO 2 — Previsto vs. real
# ==============================================================================
df_pp <- data.frame(real = teste$mortalidade_60_69, previsto = pred_teste)
g2 <- ggplot(df_pp, aes(x = real, y = previsto)) +
  geom_point(color = "steelblue", size = 2.6) +
  geom_abline(slope = 1, intercept = 0,
              linetype = "dashed", color = "firebrick") +
  labs(
    title = "Previsto vs. real — conjunto de teste",
    subtitle = "Linha tracejada = identidade (y = x)",
    x = "Mortalidade observada",
    y = "Mortalidade prevista"
  ) +
  theme_minimal(base_size = 12) +
  theme(aspect.ratio = 1)
ggsave(file.path(caminho_fig, "fig3_linear_previsto_real.png"),
       g2, width = 7, height = 7, dpi = 150)

# ==============================================================================
# SENSIBILIDADE — mesmo split, mas SEM Cubatão
# ==============================================================================
df_sem_cub <- df %>% filter(Municipio != "Cubatão")

set.seed(42)
n_sc <- nrow(df_sem_cub)
idx_treino_sc <- sample(seq_len(n_sc), size = floor(0.7 * n_sc))
treino_sc <- df_sem_cub[idx_treino_sc, ]
teste_sc  <- df_sem_cub[-idx_treino_sc, ]

modelo_treino_sc <- lm(mortalidade_60_69 ~ pib_per_capita, data = treino_sc)
pred_teste_sc    <- predict(modelo_treino_sc, newdata = teste_sc)

erro_sc <- teste_sc$mortalidade_60_69 - pred_teste_sc
rmse_sc <- sqrt(mean(erro_sc^2))
mae_sc  <- mean(abs(erro_sc))
r2_sc   <- 1 - sum(erro_sc^2) /
  sum((teste_sc$mortalidade_60_69 - mean(teste_sc$mortalidade_60_69))^2)

cat("\n--- Comparação com/sem Cubatão (mesmo split seed) ---\n")
cat("Com Cubatão: R² treino =", round(summary(modelo_treino)$r.squared, 4),
    "| R² teste =", round(r2_teste, 4),
    "| RMSE teste =", round(rmse, 4), "\n")
cat("Sem Cubatão: R² treino =", round(summary(modelo_treino_sc)$r.squared, 4),
    "| R² teste =", round(r2_sc, 4),
    "| RMSE teste =", round(rmse_sc, 4), "\n")

cat("\nScript 3 concluído.\n")


# ==============================================================================
# MICRO-RELATÓRIO — SCRIPT 3 (Regressão Linear Treino/Teste)
# ==============================================================================
# Documenta decisões metodológicas e leitura esperada dos resultados.
# NÃO é executado. Serve para redação do trabalho e releitura futura.
#
# ------------------------------------------------------------------------------
# 1. POR QUE TREINO/TESTE?
# ------------------------------------------------------------------------------
# O ajuste sobre a amostra completa (script 1) mede o quanto o modelo descreve
# os dados que ele mesmo viu — o R² intramostral. Aqui a pergunta é outra:
#   O modelo GENERALIZA para observações que ele nunca viu?
#
# Para isso: separa-se a amostra em treino (70%) e teste (30%), ajusta-se
# apenas no treino e mede-se o erro de previsão no teste.
#
# ------------------------------------------------------------------------------
# 2. POR QUE set.seed(42) E A MESMA CHAMADA sample()?
# ------------------------------------------------------------------------------
# O script 4 (logística treino/teste) usa EXATAMENTE o mesmo set.seed(42) e a
# mesma chamada sample(seq_len(n), size = floor(0.7 * n)). Isso garante que:
#   - Os mesmos 37 municípios-ano vão para o treino.
#   - Os mesmos 17 vão para o teste.
#   - As métricas dos dois modelos (linear e logística) são comparáveis
#     diretamente, sem confundir mudança de modelo com mudança de amostra.
#
# ------------------------------------------------------------------------------
# 3. ONDE CUBATÃO CAI? (RELEVANTE PARA LEITURA)
# ------------------------------------------------------------------------------
# Saber se Cubatão cai no treino ou no teste é crucial para interpretar as
# métricas. Neste split específico (set.seed(42)):
#   - 4 obs no treino: 2014, 2016, 2020, 2022
#   - 2 obs no teste:  2018, 2024
# As duas obs do TESTE são justamente as de maior PIB (171k e 270k). Isso
# significa que o modelo treinado é testado exatamente nos pontos mais
# difíceis — e isso explica boa parte dos erros grandes do teste.
#
# ------------------------------------------------------------------------------
# 4. LEITURA DAS MÉTRICAS DE TESTE
# ------------------------------------------------------------------------------
# RMSE: na mesma unidade do alvo (por mil hab.). Penaliza erros grandes.
# MAE : mais robusto a outliers.
# R²  : PODE SER NEGATIVO. Se as previsões forem piores que simplesmente
#       prever a média do teste, o R² fica abaixo de zero. Isso é
#       informativo, não bug.
#
# ------------------------------------------------------------------------------
# 5. SOBREAJUSTE vs. SUBAJUSTE
# ------------------------------------------------------------------------------
# R² treino ≈ R² teste -> modelo estável, generaliza.
# R² treino >> R² teste -> sobreajuste.
# R² treino BAIXO em ambos -> SUBAJUSTE (o caso aqui).
#
# ------------------------------------------------------------------------------
# 6. DIAGNÓSTICO VISUAL — O QUE AS FIGURAS MOSTRAM (via console)
# ------------------------------------------------------------------------------
# A partir deste script, adotamos a convenção: toda figura vem precedida de
# um bloco "DIAGNÓSTICO VISUAL" que imprime os números necessários para
# descrevê-la. Isso permite que o consolidado seja redigido sem ver as
# imagens, e permite auditoria futura do que foi observado.
#
# Figura 3a (reta treino sobre teste):
#   - Intercepto e inclinação da reta.
#   - Δy da reta sobre a faixa inteira do PIB. Se for pequeno, reta quase
#     horizontal.
#   - Distribuição de Y no treino e no teste.
#   - Posição exata de Cubatão em ambos os conjuntos.
#
# Figura 3b (previsto vs. real):
#   - Faixa (min/max) das previsões e do real.
#   - Razão entre as amplitudes. Se >> 1, previsões achatadas -> faixa
#     horizontal no gráfico.
#   - Correlação previsto x real. Próxima de 0 confirma ausência de sinal.
#   - Os 5 maiores erros, com município e ano, para identificar outliers.
#
# ------------------------------------------------------------------------------
# 7. SENSIBILIDADE — SEM CUBATÃO
# ------------------------------------------------------------------------------
# Refaz o exercício excluindo Cubatão. Como o split é refeito do zero, a
# amostra muda E o split muda — leitura COMPLEMENTAR, não variação controlada.
#
# Resultado observado:
#   Com Cubatão: R² treino = 0,035 | R² teste =  0,019 | RMSE = 4,82
#   Sem Cubatão: R² treino = 0,277 | R² teste = -0,022 | RMSE = 5,11
#
# LEITURA CRUCIAL:
#   O R² de treino SOBE muito sem Cubatão, mas o R² de teste fica NEGATIVO.
#   Por quê? Porque as 2 obs de Cubatão estão no TESTE (2018 e 2024). O
#   modelo sem Cubatão aprende que "PIB alto -> mortalidade baixa" e, ao
#   prever Cubatão (PIB altíssimo, mortalidade na média), erra feio. Isso
#   mostra que Cubatão é fenômeno substantivo, não ponto a deletar.
#
# ------------------------------------------------------------------------------
# 8. LIMITAÇÕES ESTRUTURAIS
# ------------------------------------------------------------------------------
# (a) Amostra pequena: 37/17. Métricas têm variância enorme.
# (b) Split por LINHA, não por município. Autocorrelação dentro do mesmo
#     município infla artificialmente o desempenho.
# (c) Instabilidade do R² negativo: consequência de 2 pontos. Não é prova
#     universal de que o modelo é pior que a média.
#
# Direções de aprofundamento:
#   - Split por município (leave-one-municipality-out).
#   - Validação cruzada k-fold agrupada por município.
#   - Modelos com efeitos fixos por município.
#
# ------------------------------------------------------------------------------
# 9. AMARRAÇÃO COM OS DEMAIS SCRIPTS
# ------------------------------------------------------------------------------
# - Split idêntico ao script 4 (mesmo seed, mesma chamada).
# - Mesma especificação do script 1 (mortalidade ~ PIB).
# - O achado central (Cubatão mascara a relação) é transversal aos scripts
#   1, 2, 3 e 4.
# ==============================================================================