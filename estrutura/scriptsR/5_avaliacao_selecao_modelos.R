# ==============================================================================
# 5. AVALIAÇÃO E SELEÇÃO DE MODELOS (Aula 6)
# ==============================================================================
# Cobre as tarefas da Aula 6:
#   - Erro de treino vs erro de teste
#   - Protocolo treino / validação / teste
#   - Viés-variância (o U do erro de teste)
#   - Métrica na unidade de Y (RMSE)
#   - Seleção entre candidatos
#   - Discussão de vazamento (data leakage)
#
# Tarefa explícita (slide 27):
#   1) Dividir 70/30 ANTES de qualquer ajuste
#   2) Ajustar DOIS candidatos SÓ no treino
#   3) Comparar no TESTE via RMSE
#   4) Reportar: split, candidatos, métrica, escolha, tradução do RMSE
#
# Candidatos:
#   M1 (rígido):    mortalidade ~ pib_per_capita
#   M2 (flexível):  mortalidade ~ pib_per_capita + distorcao_em
#
# Eixo de flexibilidade do U: grau polinomial em pib_per_capita.
#
# CONVENÇÃO: todo bloco que gera figura vem precedido de um bloco
# "DIAGNÓSTICO VISUAL" que imprime os números necessários para descrever a
# figura sem vê-la.
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
names(df)[grepl("^Taxas de distor", names(df))]      <- "distorcao_em"

# ==============================================================================
# PARTE A — TAREFA EXPLÍCITA DO SLIDE 27
# ==============================================================================
# Split 70/30 ANTES de qualquer ajuste. Dois candidatos. Comparação no teste.

cat("\n========== PARTE A — TAREFA EXPLÍCITA (slide 27) ==========\n")

# --- 1) split 70/30
set.seed(42)
n <- nrow(df)
idx_treino <- sample(seq_len(n), size = floor(0.7 * n))
tr <- df[idx_treino, ]
te <- df[-idx_treino, ]

cat("\n--- Divisão usada ---\n")
cat("Treino:", nrow(tr), "| Teste:", nrow(te), "\n")
cat("Proporção treino/teste:", round(nrow(tr)/n, 3), "/",
    round(nrow(te)/n, 3), "\n")

# --- 2) dois candidatos, ajustados SÓ no treino
m1 <- lm(mortalidade_60_69 ~ pib_per_capita, data = tr)
m2 <- lm(mortalidade_60_69 ~ pib_per_capita + distorcao_em, data = tr)

cat("\n--- M1 (rígido): mortalidade ~ pib_per_capita ---\n")
print(coef(m1))
cat("R² treino:", round(summary(m1)$r.squared, 4), "\n")

cat("\n--- M2 (flexível): mortalidade ~ pib_per_capita + distorcao_em ---\n")
print(coef(m2))
cat("R² treino:", round(summary(m2)$r.squared, 4), "\n")

# --- 3) RMSE no teste (na unidade de Y = por mil hab.)
rmse <- function(m, d) sqrt(mean((d$mortalidade_60_69 - predict(m, d))^2))

cat("\n--- RMSE no TESTE ---\n")
r1 <- rmse(m1, te); r2 <- rmse(m2, te)
cat("M1 (rígido)   RMSE teste:", round(r1, 4), "\n")
cat("M2 (flexível) RMSE teste:", round(r2, 4), "\n")
cat("Δ (M1 - M2) =", round(r1 - r2, 4), "\n")
cat("Modelo escolhido:", ifelse(r1 < r2, "M1 (rígido)", "M2 (flexível)"), "\n")

# --- 4) tradução do RMSE para o dono do problema
cat("\n--- Tradução do RMSE ---\n")
escolhido <- ifelse(r1 < r2, "M1 (rígido)", "M2 (flexível)")
rmse_escolhido <- min(r1, r2)
cat("O modelo escolhido (", escolhido, ") erra a mortalidade 60-69, em média,\n")
cat("em aproximadamente", round(rmse_escolhido, 2), "por mil habitantes.\n")
cat("A faixa observada de mortalidade é de ~14 a ~33 por mil hab.\n")

# ==============================================================================
# PARTE B — PROTOCOLO DE TRÊS CONJUNTOS (treino / validação / teste)
# ==============================================================================
# Para escolher entre candidatos SEM contaminar o teste, entra a validação.
# Divisão 60/20/20.

cat("\n========== PARTE B — TRÊS CONJUNTOS (60/20/20) ==========\n")

set.seed(42)
idx_60 <- sample(seq_len(n), size = floor(0.6 * n))
resto  <- setdiff(seq_len(n), idx_60)
idx_20 <- sample(resto, size = floor(0.2 * n))

tr3 <- df[idx_60, ]
va3 <- df[idx_20, ]
te3 <- df[setdiff(resto, idx_20), ]

cat("\n--- Divisão ---\n")
cat("Treino:", nrow(tr3), "| Validação:", nrow(va3), "| Teste:", nrow(te3), "\n")

# Candidatos: mesmos dois, ajustados só no treino
m1_3 <- lm(mortalidade_60_69 ~ pib_per_capita, data = tr3)
m2_3 <- lm(mortalidade_60_69 ~ pib_per_capita + distorcao_em, data = tr3)

# Comparação na VALIDAÇÃO
rmse1_va <- rmse(m1_3, va3)
rmse2_va <- rmse(m2_3, va3)

cat("\n--- Comparação na VALIDAÇÃO ---\n")
cat("M1 (rígido)   RMSE validação:", round(rmse1_va, 4), "\n")
cat("M2 (flexível) RMSE validação:", round(rmse2_va, 4), "\n")
escolhido3 <- ifelse(rmse1_va < rmse2_va, "M1 (rígido)", "M2 (flexível)")
cat("Escolhido na validação:", escolhido3, "\n")

# Reporte no TESTE, uma única vez, do escolhido
m_final <- if (escolhido3 == "M1 (rígido)") m1_3 else m2_3
rmse_final <- rmse(m_final, te3)
cat("\n--- Reporte final no TESTE (uma vez) ---\n")
cat("RMSE no teste do escolhido:", round(rmse_final, 4), "\n")

# ==============================================================================
# PARTE C — O U DO ERRO DE TESTE (viés-variância)
# ==============================================================================
# Eixo de flexibilidade: grau polinomial em pib_per_capita.
# Ajustamos graus 1, 2, 3, 5, 8, 12 no treino e medimos MSE no treino
# e no teste. Espera-se: treino desce monotonicamente; teste faz U.

cat("\n========== PARTE C — U DO ERRO DE TESTE ==========\n")

graus <- c(1, 2, 3, 5, 8, 12)
res_u <- data.frame(
  grau    = graus,
  mse_tr  = NA_real_,
  mse_te  = NA_real_,
  rmse_te = NA_real_
)

for (i in seq_along(graus)) {
  g <- graus[i]
  m <- lm(mortalidade_60_69 ~ poly(pib_per_capita, g), data = tr)
  res_u$mse_tr[i] <- mean((tr$mortalidade_60_69 - predict(m, tr))^2)
  res_u$mse_te[i] <- mean((te$mortalidade_60_69 - predict(m, te))^2)
  res_u$rmse_te[i] <- sqrt(res_u$mse_te[i])
}

cat("\n--- MSE treino vs MSE teste por grau ---\n")
print(res_u)

grau_min <- res_u$grau[which.min(res_u$mse_te)]
cat("\nGrau que minimiza MSE de teste:", grau_min, "\n")
cat("MSE de teste no mínimo:", round(min(res_u$mse_te), 2), "\n")
cat("MSE de treino no mínimo:", round(res_u$mse_tr[which.min(res_u$mse_te)], 2), "\n")
cat("\nMSE de treino no grau 12:", round(res_u$mse_tr[res_u$grau == 12], 2),
    "(deve ser o menor -> treino sempre desce)\n")
cat("MSE de teste no grau 12: ", round(res_u$mse_te[res_u$grau == 12], 2),
    "(deve subir se houver sobreajuste)\n")

# ==============================================================================
# DIAGNÓSTICO VISUAL — FIGURA 5a (U do erro de teste)
# ==============================================================================

cat("\n========== DIAGNÓSTICO VISUAL — FIG 5a (U do erro) ==========\n")
cat("\n--- Amplitude dos erros ---\n")
cat("MSE treino mínimo:", round(min(res_u$mse_tr), 2),
    "| máximo:", round(max(res_u$mse_tr), 2), "\n")
cat("MSE teste  mínimo:", round(min(res_u$mse_te), 2),
    "| máximo:", round(max(res_u$mse_te), 2), "\n")
cat("Razão (max/min) teste:",
    round(max(res_u$mse_te) / min(res_u$mse_te), 3), "\n")
cat("(se > 1.5 -> U bem formado; se próximo de 1 -> sem U claro)\n")

# ==============================================================================
# FIGURA 5a — U do erro de teste
# ==============================================================================
df_u_long <- data.frame(
  grau = rep(res_u$grau, 2),
  mse  = c(res_u$mse_tr, res_u$mse_te),
  conj = rep(c("Treino", "Teste"), each = nrow(res_u))
)

g1 <- ggplot(df_u_long, aes(x = grau, y = mse, color = conj)) +
  geom_line(linewidth = 1.1) +
  geom_point(size = 2.6) +
  scale_color_manual(values = c("Treino" = "steelblue", "Teste" = "firebrick")) +
  labs(
    title = "Erro de treino vs erro de teste por grau do polinômio",
    subtitle = "Treino desce sempre; teste faz U — o ponto ótimo é o fundo do U",
    x = "Grau do polinômio (flexibilidade)",
    y = "MSE (mortalidade, por mil hab.)²",
    color = NULL
  ) +
  theme_minimal(base_size = 12) +
  theme(aspect.ratio = 1, legend.position = "top")
ggsave(file.path(caminho_fig, "fig5_u_erro.png"),
       g1, width = 7, height = 7, dpi = 150)

# ==============================================================================
# PARTE D — COMPARAÇÃO DE CANDIDATOS (dois modelos)
# ==============================================================================
# Para a figura comparativa: M1 vs M2 no mesmo gráfico previsto x real.

cat("\n========== PARTE D — COMPARAÇÃO DE CANDIDATOS (teste) ==========\n")

pred1 <- predict(m1, te)
pred2 <- predict(m2, te)
real  <- te$mortalidade_60_69

cat("\n--- Faixa das previsões no teste ---\n")
cat("M1: min", round(min(pred1), 2), "| max", round(max(pred1), 2),
    "| amplitude", round(diff(range(pred1)), 4), "\n")
cat("M2: min", round(min(pred2), 2), "| max", round(max(pred2), 2),
    "| amplitude", round(diff(range(pred2)), 4), "\n")
cat("Real: min", round(min(real), 2), "| max", round(max(real), 2),
    "| amplitude", round(diff(range(real)), 4), "\n")

cat("\n--- Correlação previsto x real no teste ---\n")
cat("M1: cor =", round(cor(pred1, real), 4), "\n")
cat("M2: cor =", round(cor(pred2, real), 4), "\n")

cat("\n--- RMSE de cada candidato no teste ---\n")
cat("M1:", round(rmse(m1, te), 4), "\n")
cat("M2:", round(rmse(m2, te), 4), "\n")

# ==============================================================================
# FIGURA 5b — Previsto x real, M1 vs M2
# ==============================================================================
df_pp <- rbind(
  data.frame(real = real, previsto = pred1, Modelo = "M1 (rígido)"),
  data.frame(real = real, previsto = pred2, Modelo = "M2 (flexível)")
)

g2 <- ggplot(df_pp, aes(x = real, y = previsto, color = Modelo)) +
  geom_point(size = 2.6, alpha = 0.85) +
  geom_abline(slope = 1, intercept = 0,
              linetype = "dashed", color = "gray40") +
  scale_color_manual(values = c("M1 (rígido)" = "steelblue",
                                "M2 (flexível)" = "firebrick")) +
  labs(
    title = "Previsto vs real — dois candidatos no mesmo teste",
    subtitle = "Linha tracejada = identidade (y = x)",
    x = "Mortalidade observada",
    y = "Mortalidade prevista",
    color = NULL
  ) +
  theme_minimal(base_size = 12) +
  theme(aspect.ratio = 1, legend.position = "top")
ggsave(file.path(caminho_fig, "fig5_previsto_real_candidatos.png"),
       g2, width = 7, height = 7, dpi = 150)

# ==============================================================================
# PARTE E — SENSIBILIDADE SEM CUBATÃO
# ==============================================================================
# Repete o exercício do U-curve sem Cubatão.

cat("\n========== PARTE E — U SEM CUBATÃO ==========\n")

df_sc <- df %>% filter(Municipio != "Cubatão")

set.seed(42)
n_sc <- nrow(df_sc)
idx_tr_sc <- sample(seq_len(n_sc), size = floor(0.7 * n_sc))
tr_sc <- df_sc[idx_tr_sc, ]
te_sc <- df_sc[-idx_tr_sc, ]

res_u_sc <- data.frame(
  grau    = graus,
  mse_tr  = NA_real_,
  mse_te  = NA_real_
)
for (i in seq_along(graus)) {
  g <- graus[i]
  m <- lm(mortalidade_60_69 ~ poly(pib_per_capita, g), data = tr_sc)
  res_u_sc$mse_tr[i] <- mean((tr_sc$mortalidade_60_69 - predict(m, tr_sc))^2)
  res_u_sc$mse_te[i] <- mean((te_sc$mortalidade_60_69 - predict(m, te_sc))^2)
}

cat("\n--- MSE por grau SEM Cubatão ---\n")
print(res_u_sc)

cat("\n--- Comparação com/sem Cubatão no grau 1 ---\n")
cat("Com Cubatão: MSE treino =", round(res_u$mse_tr[1], 2),
    "| MSE teste =", round(res_u$mse_te[1], 2), "\n")
cat("Sem Cubatão: MSE treino =", round(res_u_sc$mse_tr[1], 2),
    "| MSE teste =", round(res_u_sc$mse_te[1], 2), "\n")

cat("\nScript 5 concluído.\n")


# ==============================================================================
# MICRO-RELATÓRIO — SCRIPT 5 (Avaliação e Seleção de Modelos)
# ==============================================================================
# Documenta decisões metodológicas e leitura esperada dos resultados.
# NÃO é executado. Serve para redação do trabalho e releitura futura.
#
# ------------------------------------------------------------------------------
# 1. O QUE A AULA 6 TROUXE DE NOVO
# ------------------------------------------------------------------------------
# Os scripts 1-4 já usavam treino/teste. A Aula 6 formaliza o PROTOCOLO e
# introduz três conceitos que faltavam:
#
#   (a) TRÊS CONJUNTOS: treino ajusta, validação escolhe, teste reporta.
#       O teste só é tocado UMA vez — no final, para reportar honestamente.
#
#   (b) VIÉS-VARIÂNCIA: o erro de teste faz um U em função da flexibilidade.
#       Modelo muito rígido -> viés alto. Muito flexível -> variância alta.
#       O ótimo está no fundo do U.
#
#   (c) VAZAMENTO: qualquer informação do teste (ou do futuro) usada no
#       ajuste ou na escolha contamina o resultado. Sintoma: desempenho
#       ótimo no papel, decepção em produção.
#
# ------------------------------------------------------------------------------
# 2. O QUE MUDOU NA PRÁTICA EM RELAÇÃO AOS SCRIPTS 3 E 4
# ------------------------------------------------------------------------------
# Nos scripts 3 e 4 fizemos split 70/30 — apenas dois conjuntos. Isso funciona
# quando o modelo está FIXO. Quando precisamos ESCOLHER entre candidatos, o
# teste não pode ser usado para a escolha. É para isso que serve a validação.
#
# O script 5 introduz o protocolo de três conjuntos (60/20/20) para mostrar
# o protocolo correto.
#
# ------------------------------------------------------------------------------
# 3. A TAREFA EXPLÍCITA DO SLIDE 27
# ------------------------------------------------------------------------------
# O slide pede:
#   1) Split 70/30 ANTES de qualquer ajuste.
#   2) Dois candidatos ajustados SÓ no treino.
#   3) RMSE no teste de cada um.
#   4) Relatório: split, candidatos, métrica, escolha, tradução.
#
# A Parte A do script executa isso passo a passo, imprimindo cada item.
#
# ------------------------------------------------------------------------------
# 4. POR QUE RMSE E NÃO MSE?
# ------------------------------------------------------------------------------
# MSE é a métrica natural para COMPARAR modelos (é a que o lm minimiza).
# RMSE é MSE na mesma unidade de Y — é o que o dono do problema entende.
# Neste banco, Y = mortalidade 60-69 em por mil hab.
# Então RMSE = "erro típico em por mil hab." — diretamente interpretável.
#
# Tradução para a imobiliária/problema:
#   "O modelo erra a mortalidade, tipicamente, em X por mil hab."
#   Comparar com a faixa observada (~14 a ~33) dá a régua.
#
# ------------------------------------------------------------------------------
# 5. O U DO ERRO DE TESTE
# ------------------------------------------------------------------------------
# A Parte C ajusta polinômios de grau 1, 2, 3, 5, 8, 12 no treino e mede
# MSE no treino e no teste.
#
# Comportamento esperado:
#   - MSE de TREINO: desce monotonicamente (mais flexibilidade = mais ajuste).
#     Isso é sempre verdade em amostra de ajuste — é tautológico.
#   - MSE de TESTE: desce (viés caindo) até um ponto e volta a subir
#     (variância dominando). Forma de U.
#
# Como ler os números:
#   - Se o MSE de teste é decrescente em todos os graus -> o ótimo está no
#     extremo superior da faixa testada. Ampliar a faixa.
#   - Se é crescente em todos -> ótimo no grau 1. O preditor é rígido.
#   - Se tem mínimo interno -> este é o grau ótimo.
#
# ATENÇÃO: em amostra pequena (37 no treino, 17 no teste), o U pode ser
# muito achatado ou ruidoso. O mínimo do teste é INSTÁVEL: uma única obs
# trocada muda o grau ótimo. Reportar com ressalva.
#
# ------------------------------------------------------------------------------
# 6. INTERPRETAÇÃO DE VIÉS-VARIÂNCIA NESTE BANCO
# ------------------------------------------------------------------------------
# Dado o que já sabemos dos scripts 1-4:
#   - PIB per capita isolado explica pouco (R² ~ 0,06).
#   - Adicionar preditores correlacionados não ajuda muito.
#   - Cubatão atrapalha.
#
# Expectativa: a curva do U será BEM ACHATADA — o MSE de teste não varia
# dramaticamente com o grau. Motivo: a associação real é fraca, então
# qualquer modelo faz previsões parecidas (todas próximas da média).
#
# Se isso se confirmar, é um achado substantivo:
#   "Não há grau de flexibilidade que resolva — o problema é o preditor,
#    não a rigidez do modelo."
# A direção natural é buscar mais/outros preditores, não polinômios.
#
# ------------------------------------------------------------------------------
# 7. VAZAMENTO — AUTOCRÍTICA RETROATIVA
# ------------------------------------------------------------------------------
# Olhando para os scripts 1-4, há dois pontos de vazamento MILD (não
# catastróficos, mas que a Aula 6 ensina a evitar):
#
#   (a) ESCOLHA DE PREDITOR COM BASE NA AMOSTRA COMPLETA.
#       Em scripts 1-4 escolhemos PIB e descartamos outros preditores
#       (Longevidade, Riqueza, IPDM) POR CIRCULARIDADE — analisando a
#       amostra completa. Isso é razoável metodologicamente (é uma decisão
#       de desenho, não de performance), mas é uma decisão que usa o todo.
#
#   (b) MEDIANA DA AMOSTRA COMPLETA NO ALVO BINÁRIO.
#       Em scripts 2 e 4 usamos a mediana da amostra completa (54 obs) para
#       definir mortalidade_alta. Isso faz o teste "ver" a distribuição
#       completa. O rigoroso seria calcular a mediana SÓ no treino e
#       aplicá-la ao teste. Optamos por manter a comparabilidade com o
#       script 2 — trade-off explícito.
#
# O script 5 NÃO repete esses erros na Parte A/B: tudo é feito depois do
# split. Mas a decisão de preditores já está feita nos scripts anteriores.
#
# ------------------------------------------------------------------------------
# 8. SENSIBILIDADE — CUBATÃO
# ------------------------------------------------------------------------------
# Mesmo fio condutor dos scripts 1-4: Cubatão distorce os resultados.
# A Parte E refaz a curva do U sem ele para comparar. Expectativa: o U
# fica mais nítido (a variância residual cai, o viés aparece com mais força).
#
# ------------------------------------------------------------------------------
# 9. AMARRAÇÃO COM OS DEMAIS SCRIPTS
# ------------------------------------------------------------------------------
# - Scripts 1-2: ajuste na amostra completa (agora sabemos: apenas descritivo).
# - Scripts 3-4: split 70/30 com escolha implícita de modelo.
# - Script 5: protocolo formal. Introduz três conjuntos para separar
#   "escolher" de "reportar".
# - O achado central (Cubatão mascara a relação renda-saúde) reaparece.
# ==============================================================================