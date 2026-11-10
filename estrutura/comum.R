# Rotinas compartilhadas. Executar os scripts a partir da raiz do projeto.
raiz <- normalizePath('.')
if (!dir.exists(file.path(raiz, 'estrutura/bancoDeDados'))) stop('Execute a partir da raiz do repositório.')
bruto <- read.csv('estrutura/bancoDeDados/df_ipdm_baixada_por_municipio.csv', sep=';', dec=',', fileEncoding='latin1', check.names=FALSE)
dados <- data.frame(municipio=factor(bruto[[2]]), ano=as.integer(bruto[[3]]), riqueza=bruto[[4]], escolaridade=bruto[[6]], mortalidade_60_69=bruto[[8]], distorcao_em=bruto[[9]], pib_per_capita=bruto[[10]])
stopifnot(nrow(dados)==54, !anyNA(dados))
md_table <- function(x) {
 x <- as.data.frame(x); x[] <- lapply(x, function(z) if(is.numeric(z)) format(round(z,4), trim=TRUE) else as.character(z))
 c(paste0('| ',paste(names(x),collapse=' | '),' |'),paste0('| ',paste(rep('---',ncol(x)),collapse=' | '),' |'),apply(x,1,function(z) paste0('| ',paste(z,collapse=' | '),' |')))
}
figura <- function(pasta,nome,expr) {png(file.path(pasta,paste0(nome,'.png')),900,900); on.exit(dev.off()); par(mar=c(5,6,3,2),pty='s');force(expr)}
