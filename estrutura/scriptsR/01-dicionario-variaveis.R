# =============================================================
# ATIVIDADE 01 - DICIONÁRIO DE VARIÁVEIS E TIPAGEM ESTATÍSTICA
# =============================================================
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

# Conversão explícita de tipos conforme Aula 02 do Professor:
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

n <- nrow(dados)
p <- ncol(dados) - 1

# =============================================================
# PARTE 2 - ESTRUTURA E TIPAGEM DAS VARIÁVEIS
# =============================================================
cat("\n================ DIMENSÕES DO BANCO ================\n")
cat("Observações (n):", n, "\n")
cat("Preditores potenciais (p):", p, "\n")
cat("Municípios:", length(unique(dados$municipio)), "\n")
cat("Anos:", paste(sort(unique(dados$ano)), collapse = ", "), "\n")

dicionario <- data.frame(
  Coluna_Original   = names(dados_brutos),
  Nome_Padronizado  = names(dados),
  Tipo_Estatistico  = c("Identificador", "Qualitativa Nominal", "Quantitativa Discreta",
                        "Quantitativa Contínua", "Quantitativa Contínua", "Quantitativa Contínua",
                        "Quantitativa Contínua", "Quantitativa Contínua", "Quantitativa Contínua",
                        "Quantitativa Contínua"),
  Tipo_R            = sapply(dados, function(x) class(x)[1]),
  Valores_Distintos = sapply(dados, function(x) length(unique(x))),
  Nulos             = sapply(dados, function(x) sum(is.na(x))),
  row.names         = NULL
)

cat("\n================ DICIONÁRIO DE VARIÁVEIS ================\n")
print(dicionario)

cat("\n================ VERIFICAÇÃO COM sapply(dados, class) ================\n")
print(sapply(dados, class))

cat("\n================ AMOSTRA DOS DADOS (PRIMEIRAS 5 LINHAS) ================\n")
print(head(dados, 5))

# =============================================================
# Fim do script
# =============================================================
