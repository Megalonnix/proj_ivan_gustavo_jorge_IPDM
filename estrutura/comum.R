# Rotinas compartilhadas. Executar os scripts a partir da raiz do projeto.
raiz <- normalizePath('.')
if (!dir.exists(file.path(raiz, 'estrutura/bancoDeDados'))) stop('Execute a partir da raiz do repositório.')

pega_col <- function(df, padrao) {
  idx <- grep(padrao, names(df), ignore.case = TRUE)
  if (length(idx) != 1L) {
    stop("Coluna nao encontrada ou ambigua para o padrao: ", padrao)
  }
  df[[idx]]
}

bruto <- read.csv('estrutura/bancoDeDados/df_ipdm_baixada_por_municipio.csv',
                  sep = ';', dec = ',', fileEncoding = 'latin1',
                  check.names = FALSE, stringsAsFactors = FALSE)

dados <- data.frame(
  municipio         = factor(pega_col(bruto, '^Municipio$')),
  ano               = as.integer(pega_col(bruto, '^Ano$')),
  riqueza           = as.numeric(pega_col(bruto, '^Riqueza')),
  escolaridade      = as.numeric(pega_col(bruto, '^Escolaridade')),
  mortalidade_60_69 = as.numeric(pega_col(bruto, '^Taxas de mortalidade')),
  distorcao_em      = as.numeric(pega_col(bruto, '^Taxas de distor')),
  pib_per_capita    = as.numeric(pega_col(bruto, '^Produto Interno Bruto'))
)
stopifnot(nrow(dados) == 54L, !anyNA(dados))

md_table <- function(x) {
  x <- as.data.frame(x)
  x[] <- lapply(x, function(z) if (is.numeric(z)) format(round(z, 4), trim = TRUE) else as.character(z))
  c(paste0('| ', paste(names(x), collapse = ' | '), ' |'),
    paste0('| ', paste(rep('---', ncol(x)), collapse = ' | '), ' |'),
    apply(x, 1, function(z) paste0('| ', paste(z, collapse = ' | '), ' |')))
}

figura <- function(pasta, nome, expr) {
  png(file.path(pasta, paste0(nome, '.png')), 900, 900)
  on.exit(dev.off())
  par(mar = c(5, 6, 3, 2), pty = 's')
  force(expr)
}
