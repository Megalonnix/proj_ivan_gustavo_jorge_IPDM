library(readr)

caminho_banco <- file.path(
  "C:/", "Users", "Ivan", "Documents",
  "Pasta-Documentos-PC-antigo",
  "GITHUB-Meus-Repositorios",
  "PesquisaTeoAprendiEstati_2026_v2",
  "proj_ivan_gustavo_jorge_(IPDM)",
  "estrutura", "bancoDeDados"
)

df_ipdm <- read_csv2(
  file.path(caminho_banco, "dados_ipdm.csv"),
  locale = locale(encoding = "Latin1"))

View(df_ipdm)


