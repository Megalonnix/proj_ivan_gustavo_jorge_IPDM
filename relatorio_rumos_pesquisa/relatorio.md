# Conclusões da Pesquisa — IPDM da Baixada Santista

**Disciplina:** Teoria do Aprendizado Estatístico
**Integrantes:** Ivan, Gustavo, Jorge
**Escopo:** Testar modelos de aprendizado supervisionado sobre o IPDM
(Fundação Seade) para os 9 municípios da Baixada Santista, 2014–2024.

---

## Nota de propósito deste documento

Este relatório **não é um relato de resultados positivos**. É um documento de
**reflexão metodológica**.

A pesquisa foi conduzida com o objetivo explícito de **testar modelos** de
aprendizado supervisionado sobre um banco real — não de produzir um modelo
preditivo operacional. Essa distinção orienta toda a leitura que segue.

Consequentemente, o valor deste documento não está na magnitude dos números
obtidos (que são modestos, e o leitor deve saber disso desde o início), e sim
naquilo que a experiência de **aplicar o protocolo completo a um banco
pequeno e ruidoso** revelou sobre:

- o comportamento real dos métodos quando o sinal é fraco;
- as armadilhas que só aparecem em amostras pequenas;
- a diferença entre "modelo que pontua bem numa métrica" e "modelo útil";
- o papel de um caso atípico como fenômeno substantivo, não como ruído.

O leitor que buscar aqui um "resultado bonito" não o encontrará. O leitor que
buscar **o que se aprende quando o resultado não é bonito** — esse é o
público-alvo deste relatório.

---

## 1. Objetivo e natureza do trabalho

O objetivo declarado **não é produzir um modelo preditivo operacional**, e sim
**exercitar o protocolo de modelagem supervisionada** — ajuste, diagnóstico,
avaliação out-of-sample, seleção — sobre um banco real, pequeno e ruidoso,
como é típico em dados públicos municipais brasileiros.

Essa distinção é importante para a leitura dos resultados: **o mérito do
trabalho está no rigor do método**, não na magnitude dos números obtidos.

## 2. O que foi executado

Seis módulos, em complexidade crescente, cobrindo as Aulas 2 a 6 do curso:

| Módulo | Conteúdo |
|--------|----------|
| 0 | Análise exploratória, tipagem de variáveis, dicionário |
| 1 | Regressão linear (simples + múltipla) na amostra completa |
| 2 | Regressão logística com três limiares de decisão |
| 3 | Regressão linear com split treino/teste (70/30) |
| 4 | Regressão logística com split, matriz de confusão e ROC |
| 5 | Protocolo treino/validação/teste, viés-variância, seleção |

Em todos os módulos foram produzidos: código reprodutível, figuras
diagnósticas, micro-relatórios no próprio `.R` e consolidados em Markdown.

## 3. Achado empírico central — Cubatão

O resultado substantivo mais consistente do trabalho **não é um coeficiente**,
é um caso atípico:

> **Cubatão tem PIB per capita de R$ 170 mil a R$ 270 mil — de 3 a 10 vezes
> o dos demais municípios — mas sua mortalidade 60–69 está na média dos
> vizinhos mais pobres (~18–21 por mil hab.).**

Esse município **contraria a hipótese renda–saúde** e reaparece como
perturbador em todos os módulos:

| Efeito | Com Cubatão | Sem Cubatão |
|--------|-------------|-------------|
| R² linear (amostra completa) | 0,062 | **0,311** |
| β₁ logístico (amostra completa) | −5,25 × 10⁻⁶ | −9,22 × 10⁻⁵ |
| AUC logística (amostra completa) | 0,690 | **0,737** |
| R² linear (teste, script 3) | 0,019 | **−0,022** |

**Interpretação:** Cubatão mascara a relação na amostra completa, mas
removê-lo não é solução — quando ele cai no teste (scripts 3 e 4), o modelo
treinado sem conhecê-lo faz previsões piores que a média. O ponto não é
ruído a ser deletado: é **fenômeno substantivo** que merece investigação
própria (composição populacional, exposição ambiental histórica, acesso a
serviços).

## 4. Peculiaridades metodológicas reveladas

### 4.1 O caso da AUC alta enganosa

No script 4, o modelo logístico produziu **AUC = 0,868** com coeficientes
estatisticamente nulos (p = 0,986) e probabilidades previstas todas no
intervalo **[0,508; 0,514]**. O classificador nunca escolhe uma classe
distinta — apenas ranqueia internamente de forma residualmente favorável.

**Lição:** AUC mede ranking, não utilidade. Uma métrica isolada pode
"aprovar" um modelo inútil. Só a inspeção conjunta (faixa de probabilidades,
matrizes de confusão em vários limiares, curva de calibração) revela o
problema.

### 4.2 A curva que não é U

No script 5, o erro de teste em função do grau do polinômio **não** forma o
U clássico dos slides:

- Graus 1–3: erro de teste desce (viés caindo, como esperado).
- Graus 5+: **colapso numérico** do `poly()` — MSE de treino explode para
  10³³, ou seja, o modelo nem consegue ajustar o treino.

**Lição:** em variáveis com escala extrema (PIB de 20 mil a 270 mil), a
flexibilidade não é uma escolha estatística — é limitada por condicionamento
numérico. A correção natural (padronizar antes de gerar o polinômio) não foi
aplicada no script, mas é a direção de aprofundamento.

### 4.3 A escolha de modelo dominada pelo split

No script 5, os mesmos dois candidatos (M1 rígido e M2 flexível) foram
avaliados em dois splits diferentes:

| Split | Modelo escolhido | RMSE teste |
|-------|------------------|------------|
| 70/30 | M1 (rígido) | 4,82 |
| 60/20/20 | M2 (flexível) | 2,73 |

A escolha **mudou com o split**, e o RMSE final caiu para quase metade —
não porque o modelo ficou melhor, mas porque o teste da Parte B tem
observações mais fáceis.

**Lição:** em amostra pequena (n=54), decisões de seleção são dominadas pela
partição aleatória, não pelo mérito dos candidatos. Reportar uma única
métrica é enganoso; reportar a sensibilidade ao split é o que torna a
análise honesta.

## 5. Limitações estruturais (declaradas)

1. **Amostra pequena.** 54 observações, apenas 9 unidades verdadeiramente
   independentes (estrutura de painel). Toda métrica tem variância alta.

2. **Split por linha, não por unidade.** O mesmo município aparece em treino
   e teste em anos diferentes — vazamento leve de "identidade". O split
   correto em painéis é por município.

3. **Vazamento mild retroativo.** A mediana usada para definir o alvo
   binário nos scripts 2 e 4 é da amostra completa, não do treino. Optamos
   por manter a comparabilidade entre módulos — trade-off explícito, não
   erro escondido.

4. **Preditor único fraco.** PIB per capita isoladamente explica pouco da
   mortalidade. Adicionar preditores correlacionados não resolve; o
   problema é falta de informação, não rigidez do modelo.

## 6. Conclusão substantiva

Aplicamos o protocolo completo de modelagem supervisionada ao IPDM da
Baixada Santista. O achado central é o seguinte:

> **Existe uma associação negativa real entre PIB per capita e mortalidade
> 60–69 na região, mas ela é fraca, sensível ao split, e mascarada por
> Cubatão — um município com PIB industrial altíssimo e mortalidade na
> média dos vizinhos mais pobres.**

Nenhum dos modelos testados tem poder preditivo suficiente para uso
operacional. As razões são estruturais: amostra pequena, painel com poucas
unidades, preditor único fraco, um caso extremo dominante.

**Direções naturais de aprofundamento** (fora do escopo deste trabalho):

- Ampliar a amostra (IPDM completo, 645 municípios).
- Adicionar preditores substantivamente distintos (saneamento, estrutura
  etária, acesso a saúde).
- Modelos com efeitos fixos por município e por ano.
- Padronizar variáveis antes de gerar termos polinomiais.
- Split por município (`leave-one-municipality-out`).

## 7. Valor do trabalho

Este é um resultado **negativo** no sentido estatístico — os modelos não
generalizam bem. Mas é um resultado **honesto, reprodutível e completo**,
com três contribuições concretas:

1. **Demonstra domínio do protocolo.** Split, validação, teste, diagnóstico
   de resíduos, análise de alavancagem, matrizes de confusão em múltiplos
   limiares — tudo aplicado no lugar certo, na ordem certa.

2. **Expõe armadilhas metodológicas reais.** A AUC alta com coeficientes
   nulos, o colapso numérico dos polinômios, a escolha de modelo dominada
   pelo split — três armadilhas que só aparecem quando se trabalha com
   dados pequenos e ruidosos de verdade.

3. **Identifica um fenômeno substantivo da região.** Cubatão não é um
   "outlier a remover". É um caso que a literatura de economia da saúde
   reconhece como interessante — e que merece investigação própria, não
   tratamento estatístico.

O trabalho cumpre o objetivo da disciplina: **testar modelos em dados
reais**, com rigor, e documentar honestamente o que foi encontrado — inclusive
quando o encontrado é "o modelo não funciona".