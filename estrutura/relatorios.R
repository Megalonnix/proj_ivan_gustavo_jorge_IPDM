# Relatórios canônicos em consolidados-aulas/ estão sincronizados com as auditorias (*-numeros.txt).
# Mantemos sincronizar_relatorio() como verificação não-destrutiva de existência, conteúdo e números-chave.
sincronizar_relatorio <- function(id, titulo, leitura, checar = NULL) {
  raiz <- normalizePath("../..")
  audit <- paste0(id, "-numeros.txt")
  stopifnot(file.exists(audit), file.info(audit)$size > 0)
  destino <- file.path(raiz, "consolidados-aulas", paste0(titulo_arquivo[[id]], ".md"))
  stopifnot(file.exists(destino), file.info(destino)$size > 0)
  if (!is.null(checar) && length(checar) > 0L) {
    txt_rel <- paste(readLines(destino, encoding = "UTF-8", warn = FALSE), collapse = "\n")
    faltantes <- checar[!vapply(checar, function(tok) grepl(tok, txt_rel, fixed = TRUE), logical(1L))]
    if (length(faltantes) > 0L) {
      stop("Divergência numérica em ", basename(destino), ": não encontrado(s) ",
           paste(faltantes, collapse = ", "))
    }
  }
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
