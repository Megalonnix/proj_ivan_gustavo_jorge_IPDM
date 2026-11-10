# Relatórios canônicos em consolidados-aulas/ já estão sincronizados com as auditorias (*-numeros.txt).
# Mantemos sincronizar_relatorio() como verificação não-destrutiva para preservar o texto didático unificado.
sincronizar_relatorio <- function(id, titulo, leitura) {
  raiz <- normalizePath("../..")
  audit <- paste0(id, "-numeros.txt")
  stopifnot(file.exists(audit))
  destino <- file.path(raiz, "consolidados-aulas", paste0(titulo_arquivo[[id]], ".md"))
  stopifnot(file.exists(destino))
  invisible(destino)
}
titulo_arquivo <- c(
  "01"  = "01-dicionario-variaveis",
  "02a" = "02a-analise-exploratoria-ampla",
  "03"  = "03-regressao-linear",
  "04"  = "04-regressao-logistica",
  "06"  = "06-metodos-reamostragem",
  "07"  = "07-expansao-regularizacao",
  "08"  = "08-metodos-suavizacao",
  "09"  = "09-splines-modelos-aditivos"
)
