# ==============================================================================
# 1. INSTALAÇÃO E CARREGAMENTO DE PACOTES
# ==============================================================================
if (!require('pacman')) install.packages('pacman')
pacman::p_load(readr, dplyr, tidyr) # Carrega os pacotes essenciais para manipulação de dados

# ==============================================================================
# 2. DEFINIÇÃO DE CAMINHOS E IMPORTAÇÃO DOS DADOS
# ==============================================================================
# Define o caminho absoluto da pasta onde o banco de dados está salvo
caminho_banco <- file.path(
  "C:/", "Users", "Ivan", "Documents",
  "Pasta-Documentos-PC-antigo",
  "GITHUB-Meus-Repositorios",
  "PesquisaTeoAprendiEstati_2026_v2",
  "proj_ivan_gustavo_jorge_(IPDM)",
  "estrutura", "bancoDeDados"
)

# Importa o arquivo CSV usando ponto e vírgula como separador e codificação Latin1
df_ipdm <- read_csv2(
  file.path(caminho_banco, "dados_ipdm.csv"),
  locale = locale(encoding = "Latin1")
)

# Remove a última coluna (...12) que contém apenas valores vazios
df_ipdm <- df_ipdm %>% select(-`...12`)

# ==============================================================================
# 3. FILTRAGEM DOS MUNICÍPIOS DA BAIXADA SANTISTA
# ==============================================================================
# Vetor com as cidades que compõem a Região Metropolitana da Baixada Santista
baixada_santista <- c(
  'Santos', 'Guarujá', 'São Vicente',
  'Praia Grande', 'Cubatão', 'Itanhaém',
  'Mongaguá', 'Bertioga', 'Peruíbe'
)

# Filtra o dataframe principal para manter apenas os municípios da lista
df_ipdm_baixada <- df_ipdm %>% 
  filter(Municipio %in% baixada_santista)

# ==============================================================================
# 4. ANÁLISE EXPLORATÓRIA DOS DADOS (EDA)
# ==============================================================================
View(df_ipdm_baixada)                 # Abre o dataframe em uma janela interativa
str(df_ipdm_baixada)                  # Exibe a estrutura das colunas e tipos de dados
summary(df_ipdm_baixada)              # Mostra o resumo estatístico das variáveis
head(df_ipdm_baixada)                 # Exibe as 6 primeiras linhas do banco
dim(df_ipdm_baixada)                  # Retorna o número de linhas e colunas
colSums(is.na(df_ipdm_baixada))       # Conta a quantidade de valores nulos (NA) por coluna

# Identifica os valores únicos/distintos presentes nos Indicadores de 1 a 5
sapply(df_ipdm_baixada[, c('Indicador 1', 'Indicador 2', 'Indicador 3', 
                           'Indicador 4', 'Indicador 5'), drop = FALSE], unique)

# Conta quantos indicadores preenchidos (não nulos) existem por linha (município)
rowSums(!is.na(df_ipdm_baixada[, c("Indicador 1", "Indicador 2", 
                                   "Indicador 3", "Indicador 4")]))

# ==============================================================================
# 5. CÁLCULO DO IPDM E FORMATAÇÃO DAS VARIÁVEIS (FORMATO WIDE)
# ==============================================================================
# Nota: Certifique-se de que o objeto 'wide' foi criado no seu script antes desta etapa.
wide <- wide %>%
  # Calcula a média simples das três dimensões para gerar o IPDM final
  mutate(IPDM = (`Indicador Riqueza` + `Indicador Longevidade` + `Indicador Escolaridade`) / 3) %>%
  # Renomeia as colunas para incluir a escala (0 a 1) e melhorar a legibilidade
  rename(
    `Riqueza [índice 0-1]`      = `Indicador Riqueza`,
    `Longevidade [índice 0-1]`  = `Indicador Longevidade`,
    `Escolaridade [índice 0-1]` = `Indicador Escolaridade`,
    `IPDM [índice 0-1]`         = IPDM
  ) %>%
  # Reposiciona as novas colunas calculadas logo após a coluna 'Ano'
  relocate(`Riqueza [índice 0-1]`, `Longevidade [índice 0-1]`, 
           `Escolaridade [índice 0-1]`, `IPDM [índice 0-1]`, .after = Ano)

# Salvando dataframe com VOLUMETRIA arrumada:

df_ipdm_baixada_por_municipio <- wide

URL_destino = 'C:/Users/Ivan/Documents/Pasta-Documentos-PC-antigo/GITHUB-Meus-Repositorios/PesquisaTeoAprendiEstati_2026_v2/proj_ivan_gustavo_jorge_(IPDM)/estrutura/bancoDeDados'

write.csv2(
  df_ipdm_baixada_por_municipio,
  file = file.path(caminho_banco, "df_ipdm_baixada_por_municipio.csv"),
  row.names = FALSE,
  fileEncoding = "Latin1"
)
           
           