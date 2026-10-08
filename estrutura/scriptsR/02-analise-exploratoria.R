# =============================================================
# ATIVIDADE 02 - DIAGNÓSTICO EM 4 PASSOS, BASELINE E EDA
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
  riqueza           = as.numeric(dados_brutos[[4]]),
  longevidade       = as.numeric(dados_brutos[[5]]),
  escolaridade      = as.numeric(dados_brutos[[6]]),
  ipdm              = as.numeric(dados_brutos[[7]]),
  mortalidade_60_69 = as.numeric(dados_brutos[[8]]),
  distorcao_em      = as.numeric(dados_brutos[[9]]),
  pib_per_capita    = as.numeric(dados_brutos[[10]])
)

# Resposta binária: IPDM Alto (acima da mediana regional)
mediana_ipdm <- median(dados$ipdm)
dados$ipdm_alto <- as.integer(dados$ipdm > mediana_ipdm)

n <- nrow(dados)
p <- ncol(dados) - 2 # excluindo o alvo continuo e binario

# Cores oficiais do professor
cazul    <- "#276DC3"
claranja <- "#E66101"
cverde   <- "#2CA02C"
croxo    <- "#5E3C99"
cfill    <- "#E0E7FF"

# =============================================================
# PARTE 2 - PROTOCOLO DE DIAGNÓSTICO DO BANCO (4 PASSOS)
# =============================================================
cat("\n================ PROTOCOLO DE DIAGNÓSTICO (4 PASSOS) ================\n")

# Passo 1: Checagem de Vazamento (Data Leakage)
num_vars <- dados[sapply(dados, is.numeric)]
cor_y <- sort(abs(cor(num_vars, use = "complete.obs")[, "ipdm"]), decreasing = TRUE)
cat("\n--- Passo 1: Checagem de Vazamento (correlações com IPDM) ---\n")
print(round(cor_y, 4))

# Passo 2: Relação n vs p
cat("\n--- Passo 2: Relação n vs p ---\n")
cat("n =", n, "| p =", p, "| Relação n/p =", round(n / p, 2), "\n")
if (n / p > 10) {
  cat("Diagnóstico: n >> p (adequado para modelos lineares clássicos).\n")
} else {
  cat("Diagnóstico: n/p moderado (recomenda-se modelos parsimoniosos ou regularização).\n")
}

# Passo 3: Balanço de Classes (IPDM Alto)
cat("\n--- Passo 3: Balanço de Classes (IPDM Alto > Mediana) ---\n")
tab_classes <- table(dados$ipdm_alto)
print(tab_classes)
print(prop.table(tab_classes))
cat("Proporção classe 0:", round(mean(dados$ipdm_alto == 0) * 100, 1), "%\n")
cat("Proporção classe 1:", round(mean(dados$ipdm_alto == 1) * 100, 1), "%\n")

# Passo 4: Dados Faltantes (NAs)
cat("\n--- Passo 4: Dados Faltantes (NAs por coluna) ---\n")
print(colSums(is.na(dados)))

# =============================================================
# PARTE 3 - CÁLCULO DAS LINHAS DE BASE (BASELINES)
# =============================================================
cat("\n================ LINHAS DE BASE (BASELINES) ================\n")
baseline_reg_rmse <- stats::sd(dados$ipdm)
baseline_class_acc <- max(table(dados$ipdm_alto)) / n

cat("Linha de Base - Regressão (RMSE de chutar a média / sd):", round(baseline_reg_rmse, 4), "\n")
cat("Linha de Base - Classificação (Acurácia majoritária):   ", round(baseline_class_acc * 100, 2), "%\n")

# =============================================================
# PARTE 4 - RESUMO ESTATÍSTICO DAS VARIÁVEIS
# =============================================================
cat("\n================ RESUMO DAS VARIÁVEIS NUMÉRICAS ================\n")
print(summary(dados[, sapply(dados, is.numeric)]))

# =============================================================
# PARTE 5 - GRÁFICOS EXPLORATÓRIOS (EXIBIÇÃO DIRETA)
# =============================================================

# Gráfico 1: Histograma do IPDM com Média vs Mediana e Normal Teórica
png(file.path(dir_figuras, "02-analise-exploratoria_img1.png"), width = 700, height = 700)
par(mar = c(4, 4, 1, 1), pty = "s")
hist(dados$ipdm, prob = TRUE, col = cfill, border = "white",
     xlab = "IPDM [índice 0-1]", ylab = "Densidade",
     main = "Distribuição do IPDM na Baixada")
curve(dnorm(x, mean = mean(dados$ipdm), sd = sd(dados$ipdm)),
      add = TRUE, lwd = 3, col = claranja)
abline(v = mean(dados$ipdm), col = cazul, lwd = 3)
abline(v = median(dados$ipdm), col = cverde, lwd = 3, lty = 2)
legend("topright", c("Média", "Mediana", "Normal teórica"),
       col = c(cazul, cverde, claranja), lwd = 3, lty = c(1, 2, 1), bty = "n")
dev.off()

# Gráfico 2: Boxplot do IPDM por Município
png(file.path(dir_figuras, "02-analise-exploratoria_img2.png"), width = 700, height = 700)
par(mar = c(6, 4, 1, 1), pty = "s")
boxplot(ipdm ~ municipio, data = dados, col = cfill, border = "gray30",
        main = "IPDM por Município", xlab = "", ylab = "IPDM [índice 0-1]", las = 2)
abline(h = mean(dados$ipdm), col = claranja, lwd = 2, lty = 2)
dev.off()

# Gráfico 3: Dispersão Bivariada Escolaridade vs IPDM
png(file.path(dir_figuras, "02-analise-exploratoria_img3.png"), width = 700, height = 700)
par(mar = c(4, 4, 1, 1), pty = "s")
plot(dados$escolaridade, dados$ipdm, pch = 19, col = cazul,
     xlab = "Escolaridade [índice 0-1]", ylab = "IPDM [índice 0-1]",
     main = "Dispersão: Escolaridade vs IPDM")
abline(lm(ipdm ~ escolaridade, data = dados), col = claranja, lwd = 3)
dev.off()


cat("\nFiguras salvas em:", normalizePath(dir_figuras, winslash = "/"), "\n")
cat("Arquivos:", paste(list.files(dir_figuras, pattern = "^02-analise-exploratoria_img"), collapse = ", "), "\n")

# =============================================================
# Fim do script
# =============================================================
