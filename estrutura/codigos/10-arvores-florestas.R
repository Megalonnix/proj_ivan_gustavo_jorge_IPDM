# Aula 11: CART, regra 1-SE, bagging e random forest.
source('estrutura/comum.R')
stopifnot(requireNamespace('rpart'),requireNamespace('randomForest'),requireNamespace('mgcv'))
d <- transform(dados, y=mortalidade_60_69)
x <- c('municipio','ano','riqueza','escolaridade','distorcao_em')
f <- reformulate(x,'y'); p <- length(x)
set.seed(1); dobra <- sample(rep(1:5,length.out=nrow(d)))
# rpart recebe cinco dobras explícitas para a escolha de CP em cada treino.
ajusta_arvore <- function(tr, seed=1) {
 set.seed(seed); folds <- sample(rep(1:5,length.out=nrow(tr)))
 a <- rpart::rpart(f,data=tr,control=rpart::rpart.control(cp=0,minsplit=4,minbucket=2,xval=folds))
 tab <- a$cptable; imin <- which.min(tab[,'xerror']); lim <- tab[imin,'xerror']+tab[imin,'xstd']
 i <- which(tab[,'xerror']<=lim)[1]
 list(modelo=rpart::prune(a,cp=tab[i,'CP']),tabela=tab,indice=i)
}
ms <- unique(c(1L,2L,3L,p))
ajusta_rf <- function(tr, m, seed=1, importance=FALSE) {
 set.seed(seed);randomForest::randomForest(f,data=tr,mtry=m,ntree=500,importance=importance)
}
escolhe_m <- function(tr, seed=1) {
 erros <- sapply(ms,function(m)tail(ajusta_rf(tr,m,seed)$mse,1));list(m=ms[which.min(erros)],erros=erros)
}
nomes <- c('Base','MQO socioeconomico','MQO municipio + ano','GAM estrutural','Arvore podada','Bagging','Random forest')
pred <- matrix(NA_real_,nrow(d),length(nomes),dimnames=list(NULL,nomes))
selecoes <- list()
for(j in 1:5) {
 tr <- d[dobra!=j,];va <- d[dobra==j,];i <- which(dobra==j)
 arv <- ajusta_arvore(tr,j);m <- escolhe_m(tr,j)
 pred[i,] <- cbind(mean(tr$y),predict(lm(y~riqueza+escolaridade+distorcao_em,tr),va),
 predict(lm(y~municipio+factor(ano),tr),va),
 predict(mgcv::gam(y~municipio+s(ano,k=5)+s(riqueza,k=4),data=tr),va),
 predict(arv$modelo,va),predict(ajusta_rf(tr,p,j),va),predict(ajusta_rf(tr,m$m,j),va))
 selecoes[[j]] <- data.frame(dobra=j,cp=arv$tabela[arv$indice,'CP'],mtry=m$m)
}
# MSE agrupado pondera cada observação igualmente, apesar de dobras desiguais.
mse <- colMeans((pred-d$y)^2)
placar <- data.frame(Modelo=nomes,MSE_CV5=mse,RMSE_CV5=sqrt(mse),row.names=NULL)
a <- ajusta_arvore(d);m <- escolhe_m(d);rf <- ajusta_rf(d,m$m,importance=TRUE)
placar$MSE_OOB <- c(rep(NA_real_,5),tail(ajusta_rf(d,p)$mse,1),tail(rf$mse,1))
# scale=FALSE: aumento absoluto do MSE, sem chamar o valor de percentual.
imp <- sort(randomForest::importance(rf,type=1,scale=FALSE)[,1],decreasing=TRUE)
raiz_arvore <- as.character(a$modelo$frame$var[1])
split_raiz <- if(raiz_arvore=='<leaf>') 'Árvore selecionada sem divisões (média global).' else paste(capture.output(a$modelo)[1:12],collapse='\n')
g <- 'consolidados-aulas/graficos/10';dir.create(g,recursive=TRUE,showWarnings=FALSE)
figura(g,'01-arvore-podada',{
 if(raiz_arvore=='<leaf>') {plot.new();text(.5,.5,paste('Árvore sem divisões\nMédia:',round(mean(d$y),3)))} else {plot(a$modelo,uniform=TRUE,margin=.15);text(a$modelo,use.n=TRUE,cex=.65)}
})
tab <- a$tabela;s2 <- mean((d$y-mean(d$y))^2)
figura(g,'02-curva-poda-cp',{matplot(tab[,'nsplit']+1,tab[,c('rel error','xerror')]*s2,type='b',pch=c(1,16),xlab='Folhas',ylab='MSE interno (CV5)',col=c('steelblue','darkorange'));abline(h=(tab[which.min(tab[,'xerror']),'xerror']+tab[which.min(tab[,'xerror']),'xstd'])*s2,lty=2);legend('topright',c('Treino','CV interna','Limite 1-SE'),col=c('steelblue','darkorange','black'),lty=c(1,1,2))})
figura(g,'03-importancia-floresta',{par(mar=c(5,10,3,2));barplot(rev(imp),horiz=TRUE,las=1,col='steelblue',xlab='Aumento absoluto do MSE OOB por permutação')})
figura(g,'04-placar-modelos-cv5',{par(mar=c(5,13,3,2));barplot(sort(mse,decreasing=TRUE),horiz=TRUE,las=1,col='steelblue',xlim=c(0,max(mse)*1.05),xlab='MSE CV5 externo')})
capture.output({cat('54 linhas; resposta mortalidade_60_69; seed 1; R:',R.version.string,'\n');print(placar);print(do.call(rbind,selecoes));cat('CP final:',tab[a$indice,'CP'],'mtry final:',m$m,'OOB MSE:',tail(rf$mse,1),'\n');print(data.frame(mtry=ms,OOB=m$erros));print(a$modelo);print(imp);print(sessionInfo())},file='estrutura/codigos/10-numeros.txt')
write.csv(placar,'estrutura/codigos/10-resultados.csv',row.names=FALSE)
write.csv(data.frame(municipio=d$municipio,ano=d$ano,dobra=dobra,y=d$y,pred,check.names=FALSE),'estrutura/codigos/10-predicoes.csv',row.names=FALSE)
campeao <- nomes[which.min(mse)]
# O relatório didático canônico consolidados-aulas/10-arvores-florestas.md já incorpora estes resultados e figuras.
