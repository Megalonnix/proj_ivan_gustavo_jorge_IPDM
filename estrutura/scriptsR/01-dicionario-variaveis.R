# =============================================================
# ATIVIDADE 01 - DICIONÁRIO DE VARIÁVEIS E TIPAGEM ESTATÍSTICA
# =============================================================
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
