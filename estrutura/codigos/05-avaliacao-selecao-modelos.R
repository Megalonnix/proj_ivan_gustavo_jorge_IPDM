# Aula 06: avaliação de regressão e classificação nas mesmas partições.
source('estrutura/comum.R')
d <- dados
set.seed(1); treino <- sample(seq_len(nrow(d)),floor(.7*nrow(d)))
set.seed(1); dobras <- sample(rep(1:5,length.out=nrow(d)))
auc <- function(y,p) {
 a <- p[y==1];b <- p[y==0]
 if (!length(a)||!length(b)) return(NA_real_)
 mean(outer(a,b,'>')+.5*outer(a,b,'=='))
}
# A mediana usada para criar classes é aprendida exclusivamente no treino.
avalia <- function(indices,particao) {
 tr <- d[indices,];te <- d[-indices,]
 corte <- median(tr$mortalidade_60_69)
 tr$alta <- as.integer(tr$mortalidade_60_69>corte)
 real <- te$mortalidade_60_69;classe <- as.integer(real>corte)
 modelos <- list(Base=rep(mean(tr$mortalidade_60_69),nrow(te)),
 Simples=predict(lm(mortalidade_60_69~escolaridade,tr),te),
 Multipla=predict(lm(mortalidade_60_69~escolaridade+distorcao_em,tr),te))
 prob <- list(Base=rep(mean(tr$alta),nrow(te)),
 Simples=predict(glm(alta~escolaridade,tr,family=binomial()),te,type='response'),
 Multipla=predict(glm(alta~escolaridade+distorcao_em,tr,family=binomial()),te,type='response'))
 do.call(rbind,lapply(names(modelos),function(nome) {
  r <- data.frame(Particao=particao,Linha=setdiff(seq_len(nrow(d)),indices),Modelo=nome,Real=real,Previsto=modelos[[nome]],Classe=classe,Probabilidade=prob[[nome]],Corte=corte)
  r
 }))
}
teste <- avalia(treino,'Teste 30%')
cv <- do.call(rbind,lapply(1:5,function(j)avalia(which(dobras!=j),paste('Dobra',j))))
resume <- function(r,tipo)do.call(rbind,lapply(split(r,r$Modelo),function(z)data.frame(Avaliacao=tipo,Modelo=z$Modelo[1],RMSE=sqrt(mean((z$Real-z$Previsto)^2)),MAE=mean(abs(z$Real-z$Previsto)),Acuracia=mean((z$Probabilidade>.5)==z$Classe),Brier=mean((z$Probabilidade-z$Classe)^2))))
resultados <- rbind(resume(teste,'Teste 30%'),resume(cv,'CV5 externa'))
# AUC por dobra evita comparar probabilidades de alvos com cortes diferentes.
aucs <- do.call(rbind,lapply(split(cv,list(cv$Particao,cv$Modelo),drop=TRUE),function(z)data.frame(Dobra=z$Particao[1],Modelo=z$Modelo[1],AUC=auc(z$Classe,z$Probabilidade))))
auc_media <- aggregate(AUC~Modelo,aucs,mean)
g <- 'consolidados-aulas/graficos/05';dir.create(g,recursive=TRUE,showWarnings=FALSE)
figura(g,'01-regressao-cv5',{z<-subset(resultados,Avaliacao=='CV5 externa');barplot(setNames(z$RMSE,z$Modelo),col='steelblue',ylab='RMSE CV5')})
figura(g,'02-classificacao-cv5',{barplot(setNames(auc_media$AUC,auc_media$Modelo),col='steelblue',ylim=c(0,1),ylab='AUC média entre dobras');abline(h=.5,lty=2)})
figura(g,'03-previsto-real',{z<-subset(cv,Modelo=='Multipla');plot(z$Real,z$Previsto,pch=19,xlab='Mortalidade observada',ylab='Predição fora da amostra');abline(0,1,col='darkorange')})
write.csv(resultados,'estrutura/codigos/05-resultados.csv',row.names=FALSE)
write.csv(rbind(teste,cv),'estrutura/codigos/05-predicoes.csv',row.names=FALSE)
capture.output({cat('54 registros; seed 1; treino 70% e teste 30%; CV5 com mesmas dobras para os modelos.\n');print(resultados);cat('\nAUC média por modelo (corte de classe varia por treino):\n');print(auc_media);print(aucs);print(sessionInfo())},file='estrutura/codigos/05-numeros.txt')
# O relatório didático canônico consolidados-aulas/05-avaliacao-selecao-modelos.md já incorpora estes resultados e figuras.
