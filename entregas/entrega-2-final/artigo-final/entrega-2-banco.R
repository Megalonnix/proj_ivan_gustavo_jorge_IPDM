# Entrega 2 - Banco limpo e calculos canonicos do artigo final
# Na raiz: Rscript entregas/entrega-2-final/artigo-final/entrega-2-banco.R
# Tambem carregado diretamente por artigo-final.Rnw via source().

for (pkg in c("rpart", "randomForest")) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    stop("Pacote ausente: ", pkg, ". Instale com install.packages(c('rpart', 'randomForest')).")
  }
}

wd_orig <- getwd()
on.exit(setwd(wd_orig), add = TRUE)

root <- if (file.exists(file.path("estrutura", "bancoDeDados", "df_ipdm_baixada_por_municipio.csv"))) {
  "."
} else if (file.exists(file.path("..", "..", "..", "estrutura", "bancoDeDados", "df_ipdm_baixada_por_municipio.csv"))) {
  file.path("..", "..", "..")
} else {
  stop("Rode na raiz do repositorio ou em entregas/entrega-2-final/artigo-final/.")
}
setwd(root)

saida <- file.path("entregas", "entrega-2-final", "artigo-final")
dir.create(saida, recursive = TRUE, showWarnings = FALSE)

pega_col <- function(df, padrao) {
  idx <- grep(padrao, names(df), ignore.case = TRUE)
  if (length(idx) != 1L) {
    stop("Coluna nao encontrada ou ambigua para o padrao: ", padrao)
  }
  df[[idx]]
}

arq_csv <- file.path("estrutura", "bancoDeDados", "df_ipdm_baixada_por_municipio.csv")
bruto <- read.csv(arq_csv, sep = ";", dec = ",", fileEncoding = "latin1",
                  check.names = FALSE, stringsAsFactors = FALSE)

# Banco limpo: apenas resposta e preditores definidos na pergunta (sem vazamento)
banco <- data.frame(
  municipio         = as.character(pega_col(bruto, "^Municipio$")),
  ano               = as.integer(pega_col(bruto, "^Ano$")),
  mortalidade_60_69 = as.numeric(pega_col(bruto, "^Taxas de mortalidade")),
  stringsAsFactors  = FALSE
)
banco <- na.omit(banco)
stopifnot(nrow(banco) == 54L)

write.csv(banco, file.path(saida, "entrega-2-dados.csv"), row.names = FALSE)

# Fatores para modelagem
dados <- data.frame(
  municipio         = factor(banco$municipio),
  ano_f             = factor(banco$ano),
  mortalidade_60_69 = banco$mortalidade_60_69
)

f1 <- function(x, d = 2) formatC(x, format = "f", digits = d, big.mark = ".", decimal.mark = ",")

n_obs <- nrow(dados)
media_global <- mean(dados$mortalidade_60_69)
dp_global    <- sd(dados$mortalidade_60_69)

medias_mun <- sort(tapply(banco$mortalidade_60_69, banco$municipio, mean))
medias_ano <- tapply(banco$mortalidade_60_69, banco$ano, mean)

# Divisao treino (38) / teste reservado (16) garantindo cobertura de todos os niveis
separa_treino <- function(df, n_tr = 38L, seed = 42L) {
  set.seed(seed)
  repeat {
    idx <- sort(sample.int(nrow(df), size = n_tr))
    tr <- df[idx, , drop = FALSE]
    if (all(levels(df$municipio) %in% as.character(tr$municipio)) &&
        all(levels(df$ano_f) %in% as.character(tr$ano_f))) {
      return(idx)
    }
  }
}

# Dobras K-fold dentro do treino conservando todos os niveis dos fatores
faz_dobras <- function(df, k = 5L, seed = 1L) {
  set.seed(seed)
  repeat {
    d <- sample(rep(seq_len(k), length.out = nrow(df)))
    ok <- TRUE
    for (j in seq_len(k)) {
      tr_j <- df[d != j, , drop = FALSE]
      if (!all(levels(df$municipio) %in% as.character(tr_j$municipio)) ||
          !all(levels(df$ano_f) %in% as.character(tr_j$ano_f))) {
        ok <- FALSE
        break
      }
    }
    if (ok) return(d)
  }
}

idx_tr <- separa_treino(dados, n_tr = 38L, seed = 42L)
treino <- dados[idx_tr, , drop = FALSE]
teste  <- dados[-idx_tr, , drop = FALSE]
dobras <- faz_dobras(treino, k = 5L, seed = 1L)

k <- 5L
mse_base <- numeric(k); mae_base <- numeric(k)
mse_mqo  <- numeric(k); mae_mqo  <- numeric(k)
mse_arv  <- numeric(k); mae_arv  <- numeric(k)
mse_bag  <- numeric(k); mae_bag  <- numeric(k)
mse_rf   <- numeric(k); mae_rf   <- numeric(k)

for (j in seq_len(k)) {
  tr <- treino[dobras != j, , drop = FALSE]
  va <- treino[dobras == j, , drop = FALSE]

  # 1. Media do treino
  p_base <- rep(mean(tr$mortalidade_60_69), nrow(va))
  mse_base[j] <- mean((va$mortalidade_60_69 - p_base)^2)
  mae_base[j] <- mean(abs(va$mortalidade_60_69 - p_base))

  # 2. MQO: municipio + ano
  m_mqo <- lm(mortalidade_60_69 ~ municipio + ano_f, data = tr)
  p_mqo <- predict(m_mqo, newdata = va)
  mse_mqo[j] <- mean((va$mortalidade_60_69 - p_mqo)^2)
  mae_mqo[j] <- mean(abs(va$mortalidade_60_69 - p_mqo))

  # 3. Arvore podada pela regra 1-SE com 5 dobras internas
  set.seed(1)
  ctrl <- rpart::rpart.control(xval = 5L, minsplit = 2L, cp = 0)
  arv_full <- rpart::rpart(mortalidade_60_69 ~ municipio + ano_f, data = tr, method = "anova", control = ctrl)
  cpt <- arv_full$cptable
  i_min <- which.min(cpt[, "xerror"])
  lim_1se <- cpt[i_min, "xerror"] + cpt[i_min, "xstd"]
  i_1se <- which(cpt[, "xerror"] <= lim_1se)[1]
  arv_pod <- rpart::prune(arv_full, cp = cpt[i_1se, "CP"])
  p_arv <- predict(arv_pod, newdata = va)
  mse_arv[j] <- mean((va$mortalidade_60_69 - p_arv)^2)
  mae_arv[j] <- mean(abs(va$mortalidade_60_69 - p_arv))

  # 4. Bagging (500 arvores, mtry = 2)
  set.seed(1)
  m_bag <- randomForest::randomForest(mortalidade_60_69 ~ municipio + ano_f,
                                      data = tr, mtry = 2L, ntree = 500L)
  p_bag <- predict(m_bag, newdata = va)
  mse_bag[j] <- mean((va$mortalidade_60_69 - p_bag)^2)
  mae_bag[j] <- mean(abs(va$mortalidade_60_69 - p_bag))

  # 5. Floresta aleatoria (500 arvores, mtry in {1, 2} pelo OOB no treino da dobra)
  set.seed(1)
  rf1 <- randomForest::randomForest(mortalidade_60_69 ~ municipio + ano_f,
                                    data = tr, mtry = 1L, ntree = 500L)
  set.seed(1)
  rf2 <- randomForest::randomForest(mortalidade_60_69 ~ municipio + ano_f,
                                    data = tr, mtry = 2L, ntree = 500L)
  m_rf <- if (tail(rf1$mse, 1) <= tail(rf2$mse, 1)) rf1 else rf2
  p_rf <- predict(m_rf, newdata = va)
  mse_rf[j] <- mean((va$mortalidade_60_69 - p_rf)^2)
  mae_rf[j] <- mean(abs(va$mortalidade_60_69 - p_rf))
}

rmse_cv <- function(m) sqrt(mean(m))
rmse_cv_base <- rmse_cv(mse_base); mae_cv_base <- mean(mae_base)
rmse_cv_mqo  <- rmse_cv(mse_mqo);  mae_cv_mqo  <- mean(mae_mqo)
rmse_cv_arv  <- rmse_cv(mse_arv);  mae_cv_arv  <- mean(mae_arv)
rmse_cv_bag  <- rmse_cv(mse_bag);  mae_cv_bag  <- mean(mae_bag)
rmse_cv_rf   <- rmse_cv(mse_rf);   mae_cv_rf   <- mean(mae_rf)
dp_dobras    <- sd(sqrt(mse_mqo))
red_rmse     <- (1 - rmse_cv_mqo / rmse_cv_base) * 100

tabela_cv <- data.frame(
  Modelo = c("Media do treino", "MQO", "Arvore podada", "Bagging", "Floresta aleatoria"),
  RMSE   = c(rmse_cv_base, rmse_cv_mqo, rmse_cv_arv, rmse_cv_bag, rmse_cv_rf),
  MAE    = c(mae_cv_base, mae_cv_mqo, mae_cv_arv, mae_cv_bag, mae_cv_rf),
  stringsAsFactors = FALSE
)

# Ajuste final nas 38 linhas de treino e avaliacao no teste reservado (16 linhas)
modelo_final <- lm(mortalidade_60_69 ~ municipio + ano_f, data = treino)
pred_teste <- predict(modelo_final, newdata = teste)
media_treino <- mean(treino$mortalidade_60_69)

rmse_teste_mqo  <- sqrt(mean((teste$mortalidade_60_69 - pred_teste)^2))
mae_teste_mqo   <- mean(abs(teste$mortalidade_60_69 - pred_teste))
rmse_teste_base <- sqrt(mean((teste$mortalidade_60_69 - media_treino)^2))

coef_est <- coef(modelo_final)
diff_mong_santos <- unname(coef_est["municipioMongaguá"] - coef_est["municipioSantos"])
diff_2022_2014   <- unname(coef_est["ano_f2022"])

res_pad <- rstandard(modelo_final)
idx_max <- which.max(abs(res_pad))

capture.output({
  cat("n=", n_obs, " treino=", nrow(treino), " teste=", nrow(teste), " params=", length(coef_est), "\n", sep = "")
  cat("media_global=", round(media_global, 2),
      " dp_global=", round(dp_global, 2), "\n", sep = "")
  cat("\n--- Medias descritivas por municipio (54 linhas) ---\n")
  print(round(medias_mun, 2))
  cat("\n--- Medias descritivas por edicao (54 linhas) ---\n")
  print(round(medias_ano, 2))
  cat("\n--- Validacao em 5 partes no treino (38 linhas) ---\n")
  print(transform(tabela_cv, RMSE = round(RMSE, 2), MAE = round(MAE, 2)), row.names = FALSE)
  cat(sprintf("reducao_rmse_mqo=%.2f%%\n", red_rmse))
  cat(sprintf("dp_rmse_dobras_mqo=%.2f\n", dp_dobras))
  cat("\n--- Teste reservado (16 linhas) ---\n")
  cat(sprintf("rmse_teste_mqo=%.2f\n", rmse_teste_mqo))
  cat(sprintf("mae_teste_mqo=%.2f\n", mae_teste_mqo))
  cat(sprintf("rmse_teste_media=%.2f\n", rmse_teste_base))
  cat("\n--- Contrastes e diagnostico (MQO nas 38 linhas de treino) ---\n")
  cat(sprintf("contraste_mongagua_santos=%.2f\n", diff_mong_santos))
  cat(sprintf("contraste_2022_2014=%.2f\n", diff_2022_2014))
  cat(sprintf("maior_residuo_padronizado=%s %s (%.2f)\n",
              as.character(treino$municipio[idx_max]),
              as.character(treino$ano_f[idx_max]),
              res_pad[idx_max]))
}, file = file.path(saida, "entrega-2-numeros.txt"))
