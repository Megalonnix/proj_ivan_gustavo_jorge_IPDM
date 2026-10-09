# =============================================================
# ATIVIDADE 09 - DA EXPLORAÇÃO À PERGUNTA
# Duas perguntas candidatas, linha de base, CV(5) e diagnóstico.
#
# P1 (regressão, inferência):
#    mortalidade_60_69 ~ municipio + ano (ano como categoria)
# P2 (classificação, predição):
#    mortalidade_alta ~ riqueza + escolaridade + distorcao_em
#
# Local sugerido: estrutura/codigo/09-escolha-da-pergunta.R
# Gera: consolidado/09-escolha-da-pergunta.md (entrega de 09/10)
# =============================================================
if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) {
  caminho_script <- rstudioapi::getSourceEditorContext()$path
  if (nzchar(caminho_script) && dir.exists(dirname(caminho_script))) {
    setwd(dirname(caminho_script))
  }
}

# ----- Origem dos dados (local primeiro, GitHub como reserva) -----
nome_csv   <- "df_ipdm_baixada_por_municipio.csv"
candidatos <- c(file.path("..", "bancoDeDados", nome_csv),
                file.path("estrutura", "bancoDeDados", nome_csv),
                nome_csv)
url_github <- "https://raw.githubusercontent.com/Megalonnix/proj_ivan_gustavo_jorge_IPDM/main/estrutura/bancoDeDados/df_ipdm_baixada_por_municipio.csv"
achados      <- candidatos[file.exists(candidatos)]
origem_dados <- if (length(achados) > 0) achados[1] else url_github

# ----- Pasta de saída do .md (consolidado/ se existir; senão, pasta atual) -----
pasta_md <- c(file.path("..", "..", "consolidado"), "consolidado", ".")
pasta_md <- pasta_md[dir.exists(pasta_md)][1]

dados_brutos <- read.csv(origem_dados, sep = ";", dec = ",", fileEncoding = "latin1",
                         check.names = FALSE, stringsAsFactors = FALSE)

dados <- data.frame(
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
dados$ano_f <- factor(dados$ano)   # ano como CATEGORIA (não como número)
n <- nrow(dados)

# ----- Utilitários -----
buffer <- character(0)
add <- function(...) { txt <- paste0(...); cat(txt, "\n"); buffer <<- c(buffer, txt) }
add_print <- function(x) {
  out <- capture.output(print(x)); cat(paste(out, collapse = "\n"), "\n")
  buffer <<- c(buffer, out)
}
fmt <- function(x, d = 2) format(round(x, d), nsmall = d, decimal.mark = ",")
pct <- function(x) paste0(format(round(100 * x, 1), nsmall = 1, decimal.mark = ","), "%")
sgn <- function(x) paste0(ifelse(x >= 0, "+", "-"), fmt(abs(x)))

# AUC = P(prob de um positivo > prob de um negativo); empates contam 0,5
auc_fun <- function(prob, real) {
  if (length(unique(real)) < 2) return(NA_real_)
  pos <- prob[real == 1]; neg <- prob[real == 0]
  mean(outer(pos, neg, ">") + 0.5 * outer(pos, neg, "=="))
}

# Dobras aleatórias, refeitas até que TODO treino contenha todos os níveis
# de município e de ano (senão o predict() falha com nível novo).
faz_dobras <- function(n, k, fatores, seed = 1) {
  set.seed(seed)
  repeat {
    d <- sample(rep(1:k, length.out = n))
    ok <- TRUE
    for (j in 1:k) for (f in fatores) {
      if (!all(levels(f) %in% as.character(f[d != j]))) ok <- FALSE
    }
    if (ok) return(d)
  }
}

# =============================================================
# DIAGNÓSTICO DO BANCO - os quatro comandos da Aula 09
# =============================================================
add("================ DIAGNÓSTICO DO BANCO ================")

# 1) Vazamento
num   <- dados[sapply(dados, is.numeric)]
cor_y <- sort(abs(cor(num, use = "complete.obs")[, "mortalidade_60_69"]), decreasing = TRUE)
add(""); add("--- 1) Vazamento: |correlação| com mortalidade_60_69 ---")
add_print(round(cor_y, 3))
add("Atenção: o dicionário diz que longevidade INCLUI a mortalidade de 60-69 e que o")
add("ipdm inclui longevidade. A correlação sozinha não denuncia isso.")
cor_sem_y <- cor_y[names(cor_y) != "mortalidade_60_69"]
nome_cmax <- names(cor_sem_y)[1]

# 2) Tamanho (n contra p)
p1 <- (nlevels(dados$municipio) - 1) + (nlevels(dados$ano_f) - 1)
p2 <- 3
min_cat <- min(table(dados$municipio), table(dados$ano_f))
add(""); add("--- 2) Tamanho: n contra p ---")
add("n = ", n, " | P1: p = ", p1, " (n/p = ", round(n / p1, 1),
    ") | P2: p = ", p2, " (n/p = ", round(n / p2, 1), ")")
add("Menor número de observações em uma categoria (município ou ano): ", min_cat)

# 3) Balanço (binária pela mediana)
tab_cls <- table(dados$mortalidade_60_69 > median(dados$mortalidade_60_69))
n_cls   <- as.vector(tab_cls)
add(""); add("--- 3) Balanço de mortalidade_alta (mediana global, só para diagnóstico) ---")
add_print(tab_cls)

# 4) Faltantes
falt <- colSums(is.na(dados)); n_na <- sum(falt)
add(""); add("--- 4) Faltantes ---")
add("Total de NAs: ", n_na)
if (n_na > 0) add_print(falt[falt > 0])

# =============================================================
# CV(5): mesmas dobras para as duas perguntas
# =============================================================
k <- 5
dobras <- faz_dobras(n, k, list(dados$municipio, dados$ano_f), seed = 1)

mse_b1 <- numeric(k); mse_q1 <- numeric(k); mse_q1x <- numeric(k)
acc_b  <- numeric(k); acc_q2 <- numeric(k); auc_q2  <- numeric(k)

for (j in 1:k) {
  tr <- dados[dobras != j, ]; te <- dados[dobras == j, ]

  # ---- P1 (regressão) ----
  m1  <- lm(mortalidade_60_69 ~ municipio + ano_f, data = tr)
  m1x <- lm(mortalidade_60_69 ~ municipio + ano_f + riqueza + escolaridade + distorcao_em,
            data = tr)
  mse_q1[j]  <- mean((te$mortalidade_60_69 - predict(m1,  newdata = te))^2)
  mse_q1x[j] <- mean((te$mortalidade_60_69 - predict(m1x, newdata = te))^2)
  mse_b1[j]  <- mean((te$mortalidade_60_69 - mean(tr$mortalidade_60_69))^2)

  # ---- P2 (classificação): mediana SÓ do treino da dobra ----
  med   <- median(tr$mortalidade_60_69)
  tr$y  <- as.integer(tr$mortalidade_60_69 > med)
  te$y  <- as.integer(te$mortalidade_60_69 > med)
  m2    <- glm(y ~ riqueza + escolaridade + distorcao_em, data = tr, family = binomial)
  prob  <- predict(m2, newdata = te, type = "response")
  maj   <- as.integer(mean(tr$y) >= 0.5)
  acc_b[j]  <- mean(te$y == maj)
  acc_q2[j] <- mean((prob > 0.5) == te$y)
  auc_q2[j] <- auc_fun(prob, te$y)
}

cv_b1  <- sqrt(mean(mse_b1))
cv_q1  <- sqrt(mean(mse_q1))
cv_q1x <- sqrt(mean(mse_q1x))
ac_b   <- mean(acc_b)
ac_q2  <- mean(acc_q2)
au_q2  <- mean(auc_q2, na.rm = TRUE)

# "Erro removido": fração do erro da linha de base que o modelo elimina
ganho1  <- 1 - cv_q1  / cv_b1
ganho1x <- 1 - cv_q1x / cv_b1
ganho2  <- (ac_q2 - ac_b) / (1 - ac_b)

add(""); add("================ CV(5) ================")
add_print(data.frame(
  Candidato     = c("P1: municipio + ano", "P1 + 3 indicadores sociais", "P2: riqueza + escol. + distorção"),
  Metrica       = c("RMSE", "RMSE", "Acurácia"),
  Base          = round(c(cv_b1, cv_b1, ac_b), 4),
  Modelo        = round(c(cv_q1, cv_q1x, ac_q2), 4),
  Erro_removido = round(c(ganho1, ganho1x, ganho2), 4)
))
add("AUC (P2), média das dobras: ", round(au_q2, 4))

# =============================================================
# Efeitos descritivos (painel balanceado: desvio da média geral)
# =============================================================
mu <- mean(dados$mortalidade_60_69)
ef_mun <- setNames(as.vector(tapply(dados$mortalidade_60_69, dados$municipio, mean)) - mu,
                   levels(dados$municipio))
ef_mun <- sort(ef_mun, decreasing = TRUE)
ef_ano <- setNames(as.vector(tapply(dados$mortalidade_60_69, dados$ano_f, mean)) - mu,
                   levels(dados$ano_f))
ano_max <- names(which.max(ef_ano)); ano_min <- names(which.min(ef_ano))

add(""); add("--- Efeito de município (média do município - média geral) ---")
add_print(round(ef_mun, 2))
add(""); add("--- Efeito de ano (média do ano - média geral) ---")
add_print(round(ef_ano, 2))

# =============================================================
# TEXTO DA ENTREGA (.md, no máximo 2 páginas)
# =============================================================
md <- c(
  "# Atividade 09 — Da exploração à pergunta",
  "",
  paste0("**Gerado por:** `09-escolha-da-pergunta.R` · **Data:** ",
         format(Sys.time(), "%Y-%m-%d %H:%M"),
         " · **Banco:** IPDM, Baixada Santista (n = ", n, ")"),
  ""
)

# ---- 1. Fichas ----
md <- c(md,
  "## 1. Duas perguntas candidatas",
  "",
  "| Campo | Pergunta 1 | Pergunta 2 |",
  "|---|---|---|",
  "| 1. Pergunta | Quanto a mortalidade de 60 a 69 anos varia com *onde* (município) e *quando* (ano) — e quais municípios ficam acima do esperado para o seu ano? | Só com indicadores sociais, dá para antecipar quais município-anos terão mortalidade de 60 a 69 anos acima da mediana? |",
  "| 2. Resposta Y | `mortalidade_60_69` · quantitativa contínua · mortes por mil hab. | `mortalidade_alta` (1 = acima da mediana do treino) · binária · sem unidade |",
  paste0("| 3. Preditores X | `municipio` (9 níveis) e `ano` como categoria (6 níveis) · p = ", p1,
         " | `riqueza`, `escolaridade`, `distorcao_em` · p = ", p2, " |"),
  "| 4. Tipo | supervisionado · regressão · **inferência** | supervisionado · classificação · **predição** |",
  "| 5. Métrica | RMSE (mortes por mil hab.) em CV(5) | AUC e acurácia em CV(5) |",
  paste0("| 6. Linha de base | RMSE de prever sempre a média: ", fmt(cv_b1),
         " | AUC = 0,50; acurácia de chutar a classe majoritária: ", pct(ac_b), " |"),
  "| 7. Dono do problema | Secretarias de saúde da Baixada: decidir onde priorizar a atenção à população de 60 a 69 anos | Gestão regional de saúde: sinalizar risco com indicadores sociais já divulgados, sem esperar o dado de óbito |",
  ""
)

# ---- 2. Resultados ----
md <- c(md,
  "## 2. Linha de base e modelo (validação cruzada, 5 dobras)",
  "",
  "| Pergunta | Modelo | Linha de base | Modelo | Erro removido |",
  "|---|---|---|---|---|",
  paste0("| P1 | `lm`: município + ano | RMSE ", fmt(cv_b1), " | RMSE **", fmt(cv_q1),
         "** | ", pct(ganho1), " |"),
  paste0("| P1 (teste extra) | `lm`: município + ano + 3 indicadores sociais | RMSE ", fmt(cv_b1),
         " | RMSE ", fmt(cv_q1x), " | ", pct(ganho1x), " |"),
  paste0("| P2 | `glm`: riqueza + escolaridade + distorção | acurácia ", pct(ac_b),
         " | acurácia **", pct(ac_q2), "** · AUC **", fmt(au_q2), "** | ", pct(ganho2), " |"),
  "",
  "“Erro removido” é a fração do erro da linha de base que o modelo elimina (RMSE na P1; taxa de erro na P2). É a régua comum entre as duas perguntas. As dobras são as mesmas nas duas; na P2 a mediana é recalculada dentro de cada dobra, sem olhar o teste.",
  ""
)

# ---- 3. Diagnóstico ----
md <- c(md,
  "## 3. Diagnóstico do banco (os quatro comandos)",
  "",
  paste0("- **Vazamento.** A maior correlação com Y é `", nome_cmax, "` (", fmt(cor_sem_y[1]),
         "): longe de 1, sem alarme numérico. Mas o dicionário mostra que `longevidade` já contém a taxa de mortalidade de 60–69 e que o `ipdm` contém `longevidade` — o Y escondido em X, que a correlação não denuncia. Ficam **fora** das duas perguntas."),
  paste0("- **Tamanho.** n = ", n, ". P1 tem p = ", p1, " (n/p = ", fmt(n / p1, 1),
         "): apertado, mas cada categoria aparece ao menos ", min_cat,
         " vezes e o erro é medido fora da amostra (CV). P2 tem p = ", p2,
         " (n/p = ", fmt(n / p2, 1), ")."),
  paste0("- **Balanço.** Classes ", n_cls[1], " / ", n_cls[2],
         ": 50/50 por construção (mediana). A acurácia não engana, mas dicotomizar descarta informação; por isso a P2 também é avaliada por AUC."),
  if (n_na == 0) "- **Faltantes.** Nenhum: nada a imputar." else
    paste0("- **Faltantes.** ", n_na, " valores ausentes (ver saída do script)."),
  "- **Dependência (extra).** Cada município aparece 6 vezes. Na CV aleatória, anos do mesmo município caem no treino e no teste, o que é otimista para a P2 (que quer generalizar para município novo).",
  ""
)

# ---- 4. Escolha ----
efeitos_txt <- paste0(
  "Desvios da média geral (mortes por mil hab.): ",
  names(ef_mun)[1], " (", sgn(ef_mun[1]), ") e ", names(ef_mun)[2], " (", sgn(ef_mun[2]),
  ") ficam acima; ", names(ef_mun)[length(ef_mun)], " (", sgn(ef_mun[length(ef_mun)]),
  ") fica abaixo. O ano de maior mortalidade é ", ano_max, " (", sgn(ef_ano[ano_max]),
  ") e o de menor é ", ano_min, " (", sgn(ef_ano[ano_min]), ")."
)
sociais_txt <- paste0(
  "Somar os três indicadores sociais a município e ano leva o RMSE de ",
  fmt(cv_q1), " para ", fmt(cv_q1x),
  if (cv_q1x < cv_q1) " (melhora)." else " (piora: excesso de parâmetros para n tão pequeno)."
)

md <- c(md, "## 4. Escolha")
md <- c(md, "")
if (max(ganho1, ganho2) <= 0) {
  md <- c(md,
    paste0("Nenhuma das duas supera a linha de base (P1 remove ", pct(ganho1),
           " do erro; P2, ", pct(ganho2), "). Antes de escolher, vale revisar as perguntas com o professor."))
} else if (ganho1 >= ganho2) {
  md <- c(md,
    paste0("Escolhemos a **Pergunta 1**. Ela remove ", pct(ganho1), " do erro da linha de base (RMSE ",
           fmt(cv_q1), " contra ", fmt(cv_b1), "), enquanto a Pergunta 2 remove ", pct(ganho2),
           " (acurácia ", pct(ac_q2), ", AUC ", fmt(au_q2), "), e ainda de forma otimista (ver dependência acima)."),
    "",
    paste0("**O que ela mostra.** ", efeitos_txt, " ", sociais_txt),
    "",
    "**Correção de rota.** As Atividades 03–08 nunca usaram `municipio` e, quando usaram `ano`, foi como número (Atividade 08). Tratar os dois como categorias é o que muda o quadro em relação à conclusão de que a mortalidade seria “imprevisível”.",
    "",
    "**Limites.** Em dado observacional, os efeitos são associação, não causa: o pico de mortalidade coincide com o período da pandemia de COVID-19, mas os dados não provam causa. A P1 descreve e interpola os 9 municípios e 6 anos observados; como `ano` é categoria, ela não projeta anos futuros."
  )
} else {
  md <- c(md,
    paste0("Escolhemos a **Pergunta 2**. Ela remove ", pct(ganho2), " do erro da linha de base (acurácia ",
           pct(ac_q2), ", AUC ", fmt(au_q2), "), contra ", pct(ganho1), " da Pergunta 1 (RMSE ",
           fmt(cv_q1), " contra ", fmt(cv_b1), ")."),
    "",
    "**Limites.** A CV aleatória é otimista para a P2: anos do mesmo município aparecem no treino e no teste. A confirmação honesta seria deixar um município inteiro de fora."
  )
}
md <- c(md, "")

# ---- 5. Próximas aulas ----
md <- c(md,
  "## 5. O que as próximas aulas podem mudar",
  "",
  "Árvores e ensembles (Aulas 11–12) e regularização podem melhorar a P2 e permitir testar interações município × ano; a pergunta volta para revisão depois da Aula 12.",
  ""
)

arquivo_md <- file.path(pasta_md, "09-escolha-da-pergunta.md")
con <- file(arquivo_md, open = "w", encoding = "UTF-8")
writeLines(md, con)
close(con)
cat("\n[OK] Entrega gravada em:", arquivo_md, "\n")
