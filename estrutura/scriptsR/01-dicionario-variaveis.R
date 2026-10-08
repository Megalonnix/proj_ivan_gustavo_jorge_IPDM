# =============================================================
# ATIVIDADE 01 - DICIONÁRIO DE VARIÁVEIS E TIPAGEM ESTATÍSTICA
# =============================================================
# ALVO ATUAL: mortalidade_60_69 (não mais ipdm)
# Motivo: ipdm é composto por riqueza+longevidade+escolaridade;
# usá-lo como alvo gera circularidade com os preditores.
# =============================================================
if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) {
  caminho_script <- rstudioapi::getSourceEditorContext()$path
  if (nzchar(caminho_script) && dir.exists(dirname(caminho_script))) {
    setwd(dirname(caminho_script))
  }
}

arquivo_local <- file.path("..", "bancoDeDados", "df_ipdm_baixada_por_municipio.csv")
url_github    <- "https://raw.githubusercontent.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/main/estrutura/bancoDeDados/df_ipdm_baixada_por_municipio.csv"

if (file.exists(arquivo_local)) {
  origem_dados <- arquivo_local
  cat("[INFO] Carregando banco LOCAL:", arquivo_local, "\n")
} else {
  origem_dados <- url_github
  cat("[INFO] Banco local não encontrado. Carregando do GitHub.\n")
}

dados_brutos <- read.csv(origem_dados, sep = ";", dec = ",", fileEncoding = "latin1",
                         check.names = FALSE, stringsAsFactors = FALSE)

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

buffer <- character(0)
add <- function(...) { txt <- paste0(...); cat(txt, "\n"); buffer <<- c(buffer, txt) }
add_print <- function(x) {
  out <- capture.output(print(x)); cat(paste(out, collapse = "\n"), "\n")
  buffer <<- c(buffer, out)
}

add(""); add("================ DIMENSÕES DO BANCO ================")
add("Observações (n): ", n)
add("Preditores potenciais (p): ", p)
add("Municípios: ", length(unique(dados$municipio)))
add("Anos: ", paste(sort(unique(dados$ano)), collapse = ", "))
add("")
add("ALVO DO PROJETO: mortalidade_60_69")
add("(NÃO usar ipdm como alvo: ele é composto por riqueza + longevidade +")
add(" escolaridade. Usar esses componentes como preditores gera circularidade.)")

dicionario <- data.frame(
  Coluna_Original   = names(dados_brutos),
  Nome_Padronizado  = names(dados),
  Tipo_Estatistico  = c("Identificador","Qualitativa Nominal","Quantitativa Discreta",
                        "Quantitativa Contínua","Quantitativa Contínua","Quantitativa Contínua",
                        "Quantitativa Contínua","Quantitativa Contínua","Quantitativa Contínua",
                        "Quantitativa Contínua"),
  Tipo_R            = sapply(dados, function(x) class(x)[1]),
  Valores_Distintos = sapply(dados, function(x) length(unique(x))),
  Nulos             = sapply(dados, function(x) sum(is.na(x))),
  row.names         = NULL
)

add(""); add("================ DICIONÁRIO ================"); add_print(dicionario)
add(""); add("================ sapply(dados, class) ================"); add_print(sapply(dados, class))
add(""); add("================ AMOSTRA (5 LINHAS) ================"); add_print(head(dados, 5))

arquivo_md <- "01-dicionario-variaveis.md"
cabecalho <- c(
  "# Relatório da Atividade 01 — Dicionário de Variáveis e Tipagem",
  "",
  paste0("**Gerado por:** `01-dicionario-variaveis.R`  "),
  paste0("**Data:** ", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "  "),
  paste0("**Origem:** `", origem_dados, "`  "),
  "",
  "> **Alvo do projeto:** `mortalidade_60_69` (por mil hab.).",
  "> O IPDM NÃO é mais o alvo: ele é composto por riqueza + longevidade +",
  "> escolaridade, e usá-lo como resposta gera circularidade com os preditores.",
  "",
  "## 1. Dimensões",
  "",
  paste0("- Observações (n) = ", n),
  paste0("- Preditores potenciais (p) = ", p),
  paste0("- Municípios = ", length(unique(dados$municipio))),
  paste0("- Anos = ", paste(sort(unique(dados$ano)), collapse = ", ")),
  paste0("- n/p = ", round(n / p, 2), " — modelagem parcimoniosa."),
  "",
  "## 2. Dicionário",
  "", "```", paste(capture.output(print(dicionario)), collapse = "\n"), "```",
  "",
  "## 3. Classes",
  "", "```", paste(capture.output(print(sapply(dados, class))), collapse = "\n"), "```",
  "",
  "## 4. Amostra",
  "", "```", paste(capture.output(print(head(dados, 5))), collapse = "\n"), "```",
  "",
  "## 5. Nota metodológica",
  "",
  "Preditores **circulares** com o alvo (excluídos dos modelos):",
  "- `longevidade` — componente do IPDM, altamente correlacionado com mortalidade.",
  "- `ipdm` — composto que contém longevidade.",
  "",
  "Preditores **válidos** para mortalidade_60_69:",
  "`escolaridade`, `distorcao_em`, `pib_per_capita`, `ano`, `riqueza`.",
  ""
)
writeLines(cabecalho, arquivo_md)
cat("\n[OK] Relatório gravado em:", arquivo_md, "\n")