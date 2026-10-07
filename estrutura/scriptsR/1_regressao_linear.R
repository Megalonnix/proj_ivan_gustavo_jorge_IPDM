# ==============================================================================
# 1. REGRESSÃO LINEAR — Mortalidade 60-69 ~ PIB per capita
# ==============================================================================
# Cobre as tarefas da Aula 4:
#   - Regressão simples + interpretação do coeficiente
#   - Gráfico quadrado com reta ajustada
#   - Regressão MÚLTIPLA e comparação de R²
#   - Diagnóstico: resíduos vs. ajustados
#   - Sensibilidade ao outlier (Cubatão) — ver micro-relatório no fim
# ==============================================================================

if (!require('pacman')) install.packages('pacman')
pacman::p_load(readr, dplyr, ggplot2, moments)

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

# Renomeia localmente apenas as colunas que vamos usar (nomes longos -> curtos)
names(df)[grepl("^Taxas de mortalidade", names(df))] <- "mortalidade_60_69"
names(df)[grepl("^Produto Interno Bruto", names(df))] <- "pib_per_capita"
names(df)[grepl("^Taxas de distor", names(df))]      <- "distorcao_em"
names(df)[grepl("^Escolaridade", names(df))]         <- "escolaridade"

# ==============================================================================
# 1. REGRESSÃO LINEAR SIMPLES — modelo principal
# ==============================================================================
modelo <- lm(mortalidade_60_69 ~ pib_per_capita, data = df)
summary(modelo)
confint(modelo, level = 0.95)

cat("\n--- Coeficientes ---\n");         print(coef(modelo))
cat("\n--- R² ---\n");                   print(summary(modelo)$r.squared)
cat("\n--- R² ajustado ---\n");          print(summary(modelo)$adj.r.squared)
cat("\n--- Erro-padrão residual ---\n"); print(summary(modelo)$sigma)
cat("\n--- Estatística F ---\n");        print(summary(modelo)$fstatistic)

df$resid     <- residuals(modelo)
df$fitted    <- fitted(modelo)
df$resid_pad <- rstandard(modelo)

# ---------------------------------------------------------------- gráfico 1
# Dispersão com reta OLS (quadrado, conforme Aula 4)
g1 <- ggplot(df, aes(x = pib_per_capita, y = mortalidade_60_69)) +
  geom_point(color = "steelblue", size = 2, alpha = 0.8) +
  geom_smooth(method = "lm", se = TRUE, color = "firebrick",
              fill = "firebrick", alpha = 0.15) +
  labs(
    title = "Mortalidade 60-69 × PIB per capita",
    subtitle = "Reta OLS com banda de confiança de 95%",
    x = "PIB per capita (R$ de 2024)",
    y = "Taxa de mortalidade 60-69 (por mil hab.)"
  ) +
  theme_minimal(base_size = 12) +
  theme(aspect.ratio = 1)
ggsave(file.path(caminho_fig, "fig1_linear_dispersao.png"),
       g1, width = 7, height = 7, dpi = 150)

# ---------------------------------------------------------------- gráfico 2
# Resíduos vs. ajustados (quadrado)
g2 <- ggplot(df, aes(x = fitted, y = resid)) +
  geom_point(color = "steelblue", size = 2, alpha = 0.8) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray40") +
  geom_smooth(method = "loess", se = FALSE, color = "firebrick", span = 1) +
  labs(title = "Resíduos vs. valores ajustados",
       x = "Valores ajustados", y = "Resíduos") +
  theme_minimal(base_size = 12) +
  theme(aspect.ratio = 1)
ggsave(file.path(caminho_fig, "fig1_linear_residuos.png"),
       g2, width = 7, height = 7, dpi = 150)

# ---------------------------------------------------------------- gráfico 3
# QQ-plot (quadrado)
g3 <- ggplot(df, aes(sample = resid)) +
  stat_qq(color = "steelblue", size = 1.8) +
  stat_qq_line(color = "firebrick") +
  labs(title = "QQ-plot dos resíduos",
       x = "Quantis teóricos", y = "Resíduos") +
  theme_minimal(base_size = 12) +
  theme(aspect.ratio = 1)
ggsave(file.path(caminho_fig, "fig1_linear_qq.png"),
       g3, width = 7, height = 7, dpi = 150)

# ------------------------------------------------------ diagnósticos formais
cat("\n--- Shapiro-Wilk nos resíduos ---\n")
print(shapiro.test(residuals(modelo)))
cat("\n--- Skewness / Curtose dos resíduos ---\n")
print(skewness(residuals(modelo)))
print(kurtosis(residuals(modelo)))

# ==============================================================================
# 2. REGRESSÃO LINEAR MÚLTIPLA — some preditores e compare R²
# ==============================================================================
# Preditores escolhidos:
#   - pib_per_capita  : componente da dimensão RIQUEZA
#   - distorcao_em    : componente da dimensão ESCOLARIDADE
#   - escolaridade    : índice sintético da dimensão ESCOLARIDADE
#
# Não incluímos Longevidade, Riqueza ou IPDM como preditores: a primeira
# contém a própria mortalidade 60-69 (circularidade direta), a segunda contém
# o PIB (redundância), a terceira é média das três dimensões (contém o alvo
# de forma indireta). Ver micro-relatório no fim do arquivo.

modelo_mult <- lm(mortalidade_60_69 ~ pib_per_capita + distorcao_em,
                  data = df)
summary(modelo_mult)

cat("\n--- R² (simples)  ---\n"); print(summary(modelo)$r.squared)
cat("\n--- R² (múltiplo) ---\n"); print(summary(modelo_mult)$r.squared)
cat("\n--- R² ajustado (múltiplo) ---\n"); print(summary(modelo_mult)$adj.r.squared)

# ---------------------------------------------------------------- gráfico 4
# Resíduos do modelo múltiplo (quadrado)
g4 <- ggplot(data.frame(fitted = fitted(modelo_mult),
                        resid  = residuals(modelo_mult)),
             aes(x = fitted, y = resid)) +
  geom_point(color = "steelblue", size = 2, alpha = 0.8) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray40") +
  geom_smooth(method = "loess", se = FALSE, color = "firebrick", span = 1) +
  labs(title = "Resíduos vs. ajustados — modelo múltiplo",
       x = "Valores ajustados", y = "Resíduos") +
  theme_minimal(base_size = 12) +
  theme(aspect.ratio = 1)
ggsave(file.path(caminho_fig, "fig1_mult_residuos.png"),
       g4, width = 7, height = 7, dpi = 150)

# ==============================================================================
# 3. SENSIBILIDADE — modelo sem Cubatão
# ==============================================================================
# Cubatão é o ponto de alta alavancagem (PIB per capita ~170-270 mil).
# NÃO o removemos do modelo principal; apenas reportamos o quanto o
# coeficiente do PIB é sensível à sua presença.

df_sem_cubatao <- df %>% filter(Municipio != "Cubatão")

modelo_sem_cub <- lm(mortalidade_60_69 ~ pib_per_capita,
                     data = df_sem_cubatao)
summary(modelo_sem_cub)

cat("\n--- Comparação do coeficiente do PIB ---\n")
cat("Com Cubatão:  β1 =", coef(modelo)["pib_per_capita"],
    "| R² =", summary(modelo)$r.squared, "\n")
cat("Sem Cubatão:  β1 =", coef(modelo_sem_cub)["pib_per_capita"],
    "| R² =", summary(modelo_sem_cub)$r.squared, "\n")

cat("\nScript 1 concluído.\n")


# ==============================================================================
# MICRO-RELATÓRIO — SCRIPT 1 (Regressão Linear)
# ==============================================================================
# Documenta decisões metodológicas e leitura esperada dos resultados.
# NÃO é executado. Serve para redação do trabalho e releitura futura.
#
# ------------------------------------------------------------------------------
# 1. POR QUE PIB PER CAPITA COMO PREDITOR?
# ------------------------------------------------------------------------------
# O par alvo/preditor foi escolhido por não apresentar sobreposição estrutural
# dentro da metodologia do IPDM:
#   - PIB per capita é componente da dimensão RIQUEZA.
#   - Mortalidade 60-69 é componente da dimensão LONGEVIDADE.
# Dimensões distintas -> sem circularidade, sem data leakage. Se tivéssemos
# usado, por exemplo, IPDM como preditor da mortalidade, haveria vazamento
# (IPDM contém Longevidade, que contém a mortalidade 60-69).
#
# ------------------------------------------------------------------------------
# 2. LEITURA DO COEFICIENTE
# ------------------------------------------------------------------------------
# β1 é o efeito de +R$ 1,00 de PIB per capita sobre a taxa de mortalidade
# (por mil hab.). Como a escala do PIB é grande (dezenas a centenas de milhares
# de reais), β1 é naturalmente minúsculo. A leitura útil é por R$ 1.000:
#   Δ mortalidade = 1000 * β1
# Sinal esperado: NEGATIVO (mais renda -> menos mortalidade), consistente com
# a literatura de economia da saúde.
#
# ------------------------------------------------------------------------------
# 3. LEITURA DO R²
# ------------------------------------------------------------------------------
# R² esperado: baixo (~0,05-0,10). Justificativa: a mortalidade nessa faixa
# depende de múltiplos fatores (acesso a saúde, morbidade prévia, escolaridade,
# saneamento, composição etária) e um preditor único nunca dá conta. Isso NÃO
# invalida o modelo — só informa que PIB per capita, isoladamente, explica
# pouco da variabilidade.
#
# ------------------------------------------------------------------------------
# 4. POR QUE ESSES PREDITORES NA MÚLTIPLA (e não outros)?
# ------------------------------------------------------------------------------
# Disponíveis no banco: Riqueza, Longevidade, Escolaridade, IPDM, PIB, taxa de
# distorção idade-série no EM, e a própria mortalidade (alvo).
#
# Excluídos por circularidade/redundância:
#   - Longevidade: contém a mortalidade 60-69 (vazamento direto).
#   - Riqueza: contém o PIB (redundância).
#   - IPDM: média das três dimensões (vazamento indireto).
#
# Incluídos:
#   - pib_per_capita : dimensão RIQUEZA.
#   - distorcao_em   : componente da dimensão ESCOLARIDADE (não sintético).
#
# O ganho de R² ao adicionar distorcao_em indica se a dimensão educacional
# contribui para explicar mortalidade mesmo controlando por renda.
# ATENÇÃO: pib_per_capita e distorcao_em podem ser correlacionados (municípios
# mais ricos tendem a ter menos distorção). Se a correlação for alta, os
# coeficientes ficam instáveis e um p-valor pode "perder" significância ao
# lado do outro. Conferir via cor(df$pib_per_capita, df$distorcao_em).
#
# ------------------------------------------------------------------------------
# 5. DIAGNÓSTICO — O QUE OLHAR NOS GRÁFICOS
# ------------------------------------------------------------------------------
# Resíduos vs. ajustados:
#   - Nuvem sem padrão em torno de zero -> linearidade OK.
#   - Curvatura (U, arco) -> relação não-linear; considerar termos quadráticos.
#   - Funil (variância cresce com o ajustado) -> heterocedasticidade; erros-
#     padrão clássicos subestimam a incerteza. Correção natural: HC3.
#
# QQ-plot:
#   - Pontos próximos à reta -> normalidade dos resíduos plausível.
#   - Caudas pesadas -> Shapiro-Wilk deve rejeitar; considerar testes robustos.
#
# Shapiro-Wilk: teste formal de normalidade. p < 0,05 -> rejeita normalidade.
# Em amostras pequenas como esta, é sensível, e a OLS ainda é consistente
# mesmo sem normalidade (só os testes t/F perdem garantia exata).
#
# ------------------------------------------------------------------------------
# 6. OUTLIER / ALAVANCAGEM — CUBATÃO
# ------------------------------------------------------------------------------
# Cubatão tem PIB per capita de ~R$ 170 mil a ~R$ 270 mil, muito acima dos
# demais municípios (na faixa de R$ 20 mil a ~R$ 90 mil). É um ponto de ALTA
# ALAVANCAGEM: sua presença pode puxar a inclinação estimada.
#
# Decisão (registrada no script 0): NÃO remover do modelo principal. Apenas
# comparar, lado a lado, com/sem Cubatão, e reportar a sensibilidade do β1.
#
# Como ler o resultado da comparação:
#   - Se β1 muda pouco e R² cai pouco ao remover Cubatão -> resultado robusto.
#   - Se β1 muda muito (em módulo ou sinal) -> o achado depende do ponto;
#     reportar como limitação explícita, não como falha a esconder.
#
# ------------------------------------------------------------------------------
# 7. LIMITAÇÃO ESTRUTURAL — PAINEL
# ------------------------------------------------------------------------------
# São 9 municípios × 6 anos = 54 linhas, mas apenas 9 unidades verdadeiramente
# independentes. As observações do mesmo município ao longo do tempo são
# correlacionadas (autocorrelação). Isso viola a premissa de i.i.d. dos testes
# formais. Os p-valores são, portanto, INDICATIVOS, não provas rigorosas.
#
# Direção de aprofundamento (fora do escopo atual):
#   - Efeitos fixos por município: lm(y ~ x + factor(Municipio)).
#   - Erros-padrão agrupados por município (cluster-robust).
#
# ------------------------------------------------------------------------------
# 8. AMARRAÇÃO COM OS DEMAIS SCRIPTS
# ------------------------------------------------------------------------------
# - O mesmo par (y, X) é usado no script 3 (treino/teste), com o MESMO split
#   para permitir comparação legítima com a logística.
# - A escolha pib_per_capita -> mortalidade_60_69 é preservada em todos os
#   scripts, para que o fio condutor do trabalho seja consistente.
# ==============================================================================