# Cálculos canônicos da Entrega 1, compartilhados com o artigo Rnw.
set.seed(1)
# =========================================================================
#  BLOCO DO BANCO DE DADOS E VALIDAÇÃO CRUZADA: IPDM Baixada Santista
# =========================================================================
arq_csv <- "../../estrutura/bancoDeDados/df_ipdm_baixada_por_municipio.csv"
if (!file.exists(arq_csv)) stop("Execute a entrega a partir de entregas/entrega-1.")

bruto <- read.csv(arq_csv, sep = ";", dec = ",", fileEncoding = "latin1",
                  check.names = FALSE, stringsAsFactors = FALSE)

dados <- data.frame(
  municipio         = factor(bruto[[2]]),
  ano               = as.integer(bruto[[3]]),
  riqueza           = as.numeric(bruto[[4]]),
  longevidade       = as.numeric(bruto[[5]]),
  escolaridade      = as.numeric(bruto[[6]]),
  ipdm              = as.numeric(bruto[[7]]),
  mortalidade_60_69 = as.numeric(bruto[[8]]),
  distorcao_em      = as.numeric(bruto[[9]]),
  pib_per_capita    = as.numeric(bruto[[10]])
)
dados$ano_f <- factor(dados$ano)

f1 <- function(x, d = 2) formatC(x, format = "f", digits = d, big.mark = ".", decimal.mark = ",")
f0 <- function(x) formatC(as.integer(x), format = "d", big.mark = ".")
sgn <- function(x, d = 2) paste0(ifelse(x >= 0, "+", "-"), f1(abs(x), d))
tex <- function(x) gsub("_", "\\\\_", x)

y <- dados$mortalidade_60_69
n <- nrow(dados)
n_mun <- nlevels(dados$municipio)
n_ano <- nlevels(dados$ano_f)
p1 <- (n_mun - 1) + (n_ano - 1)
p2 <- 3
n_por_p1 <- n / p1
n_por_p2 <- n / p2
min_cat <- min(table(dados$municipio), table(dados$ano_f))

# --- Diagnóstico 1: Vazamento e correlações ---
num <- dados[sapply(dados, is.numeric)]
cc_all <- sort(abs(cor(num, use = "complete.obs")[, "mortalidade_60_69"]), decreasing = TRUE)
cc_all <- cc_all[names(cc_all) != "mortalidade_60_69"]

validos <- c("riqueza", "pib_per_capita", "distorcao_em", "ano", "escolaridade")
cc_val <- sort(abs(cor(dados[, validos], y)[, 1]), decreasing = TRUE)

# --- Diagnóstico 3 e 4: Balanço e faltantes ---
med_global <- median(y)
n_alta <- sum(y > med_global)
n_baixa <- n - n_alta
faltantes <- sum(is.na(dados))

# --- Validação cruzada em k = 5 dobras (mesmas dobras para P1 e P2) ---
auc_fun <- function(prob, real) {
  if (length(unique(real)) < 2) return(NA_real_)
  pos <- prob[real == 1]; neg <- prob[real == 0]
  mean(outer(pos, neg, ">") + 0.5 * outer(pos, neg, "=="))
}

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

k <- 5
dobras <- faz_dobras(n, k, list(dados$municipio, dados$ano_f), seed = 1)

mse_b1 <- numeric(k); mse_q1 <- numeric(k); mse_q1x <- numeric(k)
mae_b1 <- numeric(k); mae_q1 <- numeric(k); mae_q1x <- numeric(k)
acc_b  <- numeric(k); acc_q2 <- numeric(k); auc_q2  <- numeric(k)
acc_q1c <- numeric(k); auc_q1c <- numeric(k)

for (j in 1:k) {
  tr <- dados[dobras != j, ]; te <- dados[dobras == j, ]

  # P1: regressão (efeitos fixos de município e ano)
  m1  <- lm(mortalidade_60_69 ~ municipio + ano_f, data = tr)
  m1x <- lm(mortalidade_60_69 ~ municipio + ano_f + riqueza + escolaridade + distorcao_em, data = tr)
  p_m1  <- predict(m1, newdata = te)
  p_m1x <- predict(m1x, newdata = te)
  b_m1  <- mean(tr$mortalidade_60_69)

  mse_b1[j]  <- mean((te$mortalidade_60_69 - b_m1)^2)
  mse_q1[j]  <- mean((te$mortalidade_60_69 - p_m1)^2)
  mse_q1x[j] <- mean((te$mortalidade_60_69 - p_m1x)^2)

  mae_b1[j]  <- mean(abs(te$mortalidade_60_69 - b_m1))
  mae_q1[j]  <- mean(abs(te$mortalidade_60_69 - p_m1))
  mae_q1x[j] <- mean(abs(te$mortalidade_60_69 - p_m1x))

  # P2: classificação (mediana calculada apenas no treino da dobra)
  med_tr <- median(tr$mortalidade_60_69)
  tr$y_bin <- as.integer(tr$mortalidade_60_69 > med_tr)
  te$y_bin <- as.integer(te$mortalidade_60_69 > med_tr)
  m2 <- glm(y_bin ~ riqueza + escolaridade + distorcao_em, data = tr, family = binomial)
  prob2 <- predict(m2, newdata = te, type = "response")
  maj <- as.integer(mean(tr$y_bin) >= 0.5)

  acc_b[j]  <- mean(te$y_bin == maj)
  acc_q2[j] <- mean((prob2 > 0.5) == te$y_bin)
  auc_q2[j] <- auc_fun(prob2, te$y_bin)

  # P1 cortado na mediana do treino da dobra (teste de dominância sobre P2)
  acc_q1c[j] <- mean((p_m1 > med_tr) == te$y_bin)
  auc_q1c[j] <- auc_fun(p_m1, te$y_bin)
}

rmse_b1  <- sqrt(mean(mse_b1));  dp_b1  <- sd(sqrt(mse_b1))
rmse_q1  <- sqrt(mean(mse_q1));  dp_q1  <- sd(sqrt(mse_q1))
rmse_q1x <- sqrt(mean(mse_q1x)); dp_q1x <- sd(sqrt(mse_q1x))

m_mae_b1  <- mean(mae_b1)
m_mae_q1  <- mean(mae_q1)
m_mae_q1x <- mean(mae_q1x)

m_acc_b   <- mean(acc_b);   dp_acc_b   <- sd(acc_b)
m_acc_q2  <- mean(acc_q2);  dp_acc_q2  <- sd(acc_q2)
m_auc_q2  <- mean(auc_q2);  dp_auc_q2  <- sd(auc_q2)
m_acc_q1c <- mean(acc_q1c); dp_acc_q1c <- sd(acc_q1c)
m_auc_q1c <- mean(auc_q1c); dp_auc_q1c <- sd(auc_q1c)

ganho_p1  <- 100 * (1 - rmse_q1 / rmse_b1)
ganho_p1x <- 100 * (1 - rmse_q1x / rmse_b1)
ganho_p2  <- 100 * ((m_acc_q2 - m_acc_b) / (1 - m_acc_b))
ganho_p1c <- 100 * ((m_acc_q1c - m_acc_b) / (1 - m_acc_b))

# Efeitos estruturais descritivos
mu_geral <- mean(y)
ef_mun <- sort(tapply(y, dados$municipio, mean) - mu_geral, decreasing = TRUE)
ef_ano <- tapply(y, dados$ano_f, mean) - mu_geral

resultados <- data.frame(Modelo=c("Base","MQO estrutural","MQO estrutural + sociais","Logistica","MQO binarizado"), RMSE=c(rmse_b1,rmse_q1,rmse_q1x,NA,NA), MAE=c(m_mae_b1,m_mae_q1,m_mae_q1x,NA,NA), AUC=c(NA,NA,NA,m_auc_q2,m_auc_q1c), Acuracia=c(NA,NA,NA,m_acc_q2,m_acc_q1c))
write.csv(resultados,"entrega-1-resultados.csv",row.names=FALSE)
escalas <- data.frame(Variavel=c("mortalidade_60_69","riqueza","escolaridade","distorcao_em"), Unidade=c("mortes por mil habitantes","indice","indice","percentual"))
write.csv(escalas,"entrega-1-escalas.csv",row.names=FALSE)
capture.output({print(resultados);print(escalas);print(data.frame(Dobra=1:k,MSE_Base=mse_b1,MSE_MQO=mse_q1));print(sessionInfo())},file="entrega-1-numeros.txt")
