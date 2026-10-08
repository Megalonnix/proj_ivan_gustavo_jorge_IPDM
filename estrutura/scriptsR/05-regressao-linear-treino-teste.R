# =============================================================
# ATIVIDADE 05 - AVALIAÇÃO DE REGRESSÃO: TREINO/TESTE E CV(5)
# =============================================================
# Pergunta: Escolaridade -> IPDM
# Padrão: Prof. Dr. João Paulo Ferreira de Mello (Base R First)
# Carregamento direto via GitHub
# =============================================================

# =============================================================
# PARTE 1 - LER E PREPARAR OS DADOS (DIRETO DO GITHUB)
# =============================================================
nome_csv    <- "df_ipdm_baixada_por_municipio.csv"
url_github  <- "https://raw.githubusercontent.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/main/estrutura/bancoDeDados/df_ipdm_baixada_por_municipio.csv"

# --- Onde o script pode estar? (Rscript, source(), RStudio ou diretório atual) ---
pontos_partida <- getwd()
args_cmd <- commandArgs(trailingOnly = FALSE)
arq_cmd  <- sub("^--file=", "", args_cmd[grep("^--file=", args_cmd)])
if (length(arq_cmd) == 1) pontos_partida <- c(dirname(normalizePath(arq_cmd)), pontos_partida)
arq_src <- tryCatch(sys.frame(1)$ofile, error = function(e) NULL)
if (!is.null(arq_src)) pontos_partida <- c(dirname(normalizePath(arq_src)), pontos_partida)
if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) {
  arq_rs <- tryCatch(rstudioapi::getSourceEditorContext()$path, error = function(e) "")
  if (nzchar(arq_rs)) pontos_partida <- c(dirname(normalizePath(arq_rs)), pontos_partida)
}

# --- Sobe nas pastas-pai até achar estrutura/bancoDeDados/<csv> ---
achar_raiz <- function(pontos) {
  for (ponto in pontos) {
    atual <- normalizePath(ponto, winslash = "/", mustWork = FALSE)
    for (nivel in 1:8) {
      if (file.exists(file.path(atual, "estrutura", "bancoDeDados", nome_csv))) return(atual)
      pai <- dirname(atual)
      if (pai == atual) break
      atual <- pai
    }
  }
  NULL
}
raiz <- achar_raiz(pontos_partida)

ler_csv <- function(f) read.csv(f, sep = ";", dec = ",", fileEncoding = "latin1",
                                check.names = FALSE, stringsAsFactors = FALSE)

# --- 1) LOCAL primeiro; 2) GitHub só se não achar localmente ---
if (!is.null(raiz)) {
  arquivo_local <- file.path(raiz, "estrutura", "bancoDeDados", nome_csv)
  cat("Dados lidos LOCALMENTE de:", arquivo_local, "\n")
  dados_brutos <- ler_csv(arquivo_local)
} else {
  cat("CSV não encontrado localmente. Buscando no GitHub...\n")
  dados_brutos <- tryCatch(ler_csv(url_github), error = function(e) {
    stop("Não achei '", nome_csv, "' nem localmente (procurei a partir de: ",
         paste(unique(pontos_partida), collapse = " | "),
         ") nem no GitHub (", url_github, ").", call. = FALSE)
  })
}

# --- Pasta de figuras: SEMPRE estrutura/scriptsR/figuras da raiz do projeto ---
dir_figuras <- if (!is.null(raiz)) file.path(raiz, "estrutura", "scriptsR", "figuras") else file.path(getwd(), "figuras")
dir.create(dir_figuras, showWarnings = FALSE, recursive = TRUE)
cat("Figuras serão salvas em:", normalizePath(dir_figuras, winslash = "/"), "\n")

dados <- data.frame(
  cod_ibge          = factor(dados_brutos[[1]]),
  municipio         = factor(dados_brutos[[2]]),
  ano               = as.integer(dados_brutos[[3]]),
  escolaridade      = as.numeric(dados_brutos[[6]]),
  ipdm              = as.numeric(dados_brutos[[7]])
)

# Cores oficiais do professor
cazul    <- "#276DC3"
claranja <- "#E66101"
cverde   <- "#2CA02C"
croxo    <- "#5E3C99"
cfill    <- "#E0E7FF"

# =============================================================
# PARTE 2 - DIVISÃO TREINO/TESTE (70/30) E AJUSTE
# =============================================================
set.seed(1)
n <- nrow(dados)
idx_treino <- sample(seq_len(n), size = floor(0.7 * n))
treino <- dados[idx_treino, ]
teste  <- dados[-idx_treino, ]

m_treino <- lm(ipdm ~ escolaridade, data = treino)

cat("\n================ RESUMO DO MODELO NO TREINO (70%) ================\n")
printCoefmat(coef(summary(m_treino)), signif.legend = FALSE)

pred_teste <- predict(m_treino, newdata = teste)
erro <- teste$ipdm - pred_teste

rmse_teste <- sqrt(mean(erro^2))
mae_teste  <- mean(abs(erro))
r2_teste   <- 1 - sum(erro^2) / sum((teste$ipdm - mean(teste$ipdm))^2)
rmse_base_teste <- sqrt(mean((teste$ipdm - mean(treino$ipdm))^2))

cat("\n================ DESEMPENHO NO TESTE (30% -", nrow(teste), "OBSERVAÇÕES) ================\n")
cat("RMSE Teste:              ", round(rmse_teste, 4), "\n")
cat("MAE Teste:               ", round(mae_teste, 4), "\n")
cat("R² Teste:                ", round(r2_teste, 4), "\n")
cat("RMSE Linha de Base Teste:", round(rmse_base_teste, 4), "\n")

# =============================================================
# PARTE 3 - TABELA ILUSTRATIVA: PREVISTO VS REAL NO TESTE
# =============================================================
tab_comparacao <- data.frame(
  municipio    = teste$municipio,
  ano          = teste$ano,
  escolaridade = round(teste$escolaridade, 3),
  real         = round(teste$ipdm, 4),
  previsto     = round(pred_teste, 4),
  residuo      = round(erro, 4)
)
cat("\n================ TABELA: Comparativo Previsto vs Real (Primeiras Linhas) ================\n")
print(head(tab_comparacao, 6))

# =============================================================
# PARTE 4 - GRÁFICOS: RETA TREINO VS TESTE E PREVISTO VS REAL
# =============================================================

# Gráfico 1: Reta de Treino sobreposta aos pontos de Teste
png(file.path(dir_figuras, "05-regressao-linear-treino-teste_img1.png"), width = 700, height = 700)
par(mar = c(4, 4, 1, 1), pty = "s")
plot(treino$escolaridade, treino$ipdm, col = "gray60", pch = 16,
     xlab = "Escolaridade [índice 0-1]", ylab = "IPDM [índice 0-1]",
     main = "Reta de Treino vs Pontos de Teste")
points(teste$escolaridade, teste$ipdm, col = claranja, pch = 19)
abline(m_treino, col = cazul, lwd = 3)
legend("topleft", legend = c("Treino (70%)", "Teste (30%)", "Reta OLS (Treino)"),
       col = c("gray60", claranja, cazul), pch = c(16, 19, NA),
       lwd = c(NA, NA, 3), lty = c(NA, NA, 1), bty = "n")
dev.off()

# Gráfico 2: Previsto vs Real no conjunto de teste (linha diagonal y = x)
png(file.path(dir_figuras, "05-regressao-linear-treino-teste_img2.png"), width = 700, height = 700)
par(mar = c(4, 4, 1, 1), pty = "s")
plot(teste$ipdm, pred_teste, col = cazul, pch = 19,
     xlab = "IPDM Observado (Real)", ylab = "IPDM Previsto",
     main = "Previsto vs Real (Conjunto de Teste)")
abline(a = 0, b = 1, lty = 2, col = claranja, lwd = 2)
dev.off()

# =============================================================
# PARTE 5 - VALIDAÇÃO CRUZADA k-FOLD (k = 5) MANUAL EM BASE R
# =============================================================
k <- 5
set.seed(1)
dobra <- sample(rep(1:k, length = nrow(dados)))
erro_cv <- numeric(k)
erro_cv_base <- numeric(k)

for (j in 1:k) {
  tr <- dados[dobra != j, ]
  te <- dados[dobra == j, ]
  
  m_cv <- lm(ipdm ~ escolaridade, data = tr)
  pred_j <- predict(m_cv, newdata = te)
  
  erro_cv[j] <- mean((te$ipdm - pred_j)^2)
  erro_cv_base[j] <- mean((te$ipdm - mean(tr$ipdm))^2)
}

cv_rmse <- sqrt(mean(erro_cv))
cv_rmse_base <- sqrt(mean(erro_cv_base))

cat("\n================ VALIDAÇÃO CRUZADA k-FOLD (k = 5) ================\n")
cat("RMSE Modelo Linear CV(5):   ", round(cv_rmse, 4), "\n")
cat("RMSE Linha de Base CV(5):   ", round(cv_rmse_base, 4), "\n")
cat("Desvio-Padrão Total (sd Y): ", round(stats::sd(dados$ipdm), 4), "\n")

# Gráfico 3: Volatilidade do MSE de Teste em 200 Divisões Avulsas (Aula 7)
set.seed(1)
mse_avulso <- replicate(200, {
  idx <- sample(n, floor(0.7 * n))
  m_av <- lm(ipdm ~ escolaridade, data = dados[idx, ])
  mean((dados$ipdm[-idx] - predict(m_av, newdata = dados[-idx, ]))^2)
})

png(file.path(dir_figuras, "05-regressao-linear-treino-teste_img3.png"), width = 700, height = 700)
par(mar = c(4, 4, 1, 1), pty = "s")
hist(mse_avulso, breaks = 20, col = cfill, border = "white",
     xlab = "MSE de Teste", ylab = "Densidade", prob = TRUE,
     main = "Volatilidade do MSE (200 Divisões 70/30)")
abline(v = mean(mse_avulso), col = croxo, lwd = 3)
abline(v = cv_rmse^2, col = claranja, lwd = 3, lty = 2)
legend("topright", legend = c("Média Divisões Avulsas", "MSE Estável CV(5)"),
       col = c(croxo, claranja), lwd = 3, lty = c(1, 2), bty = "n")
dev.off()

cat("\nFiguras salvas em:", normalizePath(dir_figuras, winslash = "/"), "\n")
cat("Arquivos:", paste(list.files(dir_figuras, pattern = "^05-regressao-linear-treino-teste_img"), collapse = ", "), "\n")

# =============================================================
# Fim do script
# =============================================================
