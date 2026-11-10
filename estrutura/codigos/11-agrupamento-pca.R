# Aula 12: PCA e agrupamento; Y só é consultada após a partição.
source('estrutura/comum.R')
stopifnot(requireNamespace('cluster'))
xnomes <- c('riqueza','escolaridade','distorcao_em','pib_per_capita')
X <- dados[xnomes]; stopifnot(all(sapply(X,sd)>0))
Z <- scale(X);pca <- prcomp(Z,center=FALSE,scale.=FALSE)
ve <- pca$sdev^2/sum(pca$sdev^2);pesos <- pca$rotation[,1:2]
ks <- 2:min(10,nrow(unique(Z))-1)
modelos <- lapply(ks,function(k){set.seed(1);kmeans(Z,centers=k,nstart=50)})
distancias <- dist(Z)
sil <- sapply(modelos,function(m)mean(cluster::silhouette(m$cluster,distancias)[,'sil_width']))
i <- which.max(sil);k <- ks[i];km <- modelos[[i]]
centros <- sweep(sweep(km$centers,2,attr(Z,'scaled:scale'),'*'),2,attr(Z,'scaled:center'),'+')
completa <- hclust(distancias,method='complete');simples <- hclust(distancias,method='single')
cruz <- table(Kmeans=km$cluster,Completa=cutree(completa,k));cruz_simples <- table(Kmeans=km$cluster,Simples=cutree(simples,k))
y <- dados$mortalidade_60_69
resposta <- do.call(rbind,lapply(1:k,function(j)data.frame(Grupo=j,N=sum(km$cluster==j),Media=mean(y[km$cluster==j]),DP=sd(y[km$cluster==j]),Min=min(y[km$cluster==j]),Max=max(y[km$cluster==j]))))
# Rótulos derivados dos maiores desvios dos centros, sem inferir vulnerabilidade causal.
rotulos <- apply(km$centers,1,function(z) {j<-order(abs(z),decreasing=TRUE)[1:2];paste(paste(names(z)[j],ifelse(z[j]>0,'acima da média','abaixo da média')),collapse='; ')})
nome_pc <- function(j){z<-pesos[,j];o<-order(abs(z),decreasing=TRUE)[1:2];paste(paste(names(z)[o],ifelse(z[o]>0,'(+)','(-)')),collapse=' / ')}
g <- 'consolidados-aulas/graficos/11';dir.create(g,recursive=TRUE,showWarnings=FALSE)
figura(g,'01-variancia-pca',{barplot(ve,names.arg=paste0('PC',seq_along(ve)),col='steelblue',ylim=c(0,1),ylab='Proporção da variância');lines(seq_along(ve)*1.2-.5,cumsum(ve),type='b',col='darkorange');legend('right',c('Individual','Acumulada'),fill=c('steelblue','darkorange'))})
figura(g,'02-silhueta',{plot(ks,sil,type='b',pch=19,xlab='K',ylab='Silhueta média');points(k,sil[i],col='darkorange',pch=19,cex=2);abline(h=.35,lty=2)})
figura(g,'03-pca-grupos',{plot(pca$x[,1:2],col=km$cluster+1,pch=19,xlab='PC1',ylab='PC2');legend('topright',paste('Grupo',1:k),col=(1:k)+1,pch=19)})
figura(g,'04-dendrograma-hierarquico',{plot(completa,labels=FALSE,hang=-1,main='Ligação completa',xlab='',ylab='Distância');rect.hclust(completa,k=k,border='darkorange')})
figura(g,'05-dendrograma-simples',{plot(simples,labels=FALSE,hang=-1,main='Ligação simples',xlab='',ylab='Distância');rect.hclust(simples,k=k,border='steelblue')})
variance <- data.frame(PC=paste0('PC',seq_along(ve)),Individual=ve,Acumulada=cumsum(ve))
capture.output({cat('Y excluída de X; X padronizada; seed 1; nstart 50\n');print(variance);print(pesos);print(data.frame(K=ks,Silhueta=sil));cat('K escolhido:',k,'\n');print(centros);print(rotulos);print(cruz);print(cruz_simples);print(resposta);print(sessionInfo())},file='estrutura/codigos/11-numeros.txt')
write.csv(data.frame(dados[c('municipio','ano')],Grupo=km$cluster,PC1=pca$x[,1],PC2=pca$x[,2]),'estrutura/codigos/11-grupos.csv',row.names=FALSE)
# O relatório didático canônico consolidados-aulas/11-agrupamento-pca.md já incorpora estes resultados e figuras.
