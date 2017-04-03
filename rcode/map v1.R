# install.packages("maps")
# install.packages("ggplot2")

library(maps)
library(ggplot2)

### open up list of words
filenames <- list.files("/Users/jdavin/Dropbox/greatschools - share/BrianFeeny/word frequency counts/by-state", full.names=TRUE)
ldf <- lapply(filenames, read.csv,header=F,stringsAsFactors=F)

states <- substr(filenames, 86, 87)

topwords=matrix("",nrow=nrow(ldf[[1]]),ncol=length(ldf))

for(i in 1:length(ldf)){
	topwords[,i]=ldf[[i]][,1]
}	




# word cloud
# http://onertipaday.blogspot.com/2011/07/word-cloud-in-r.html
require(XML)
require(tm)
#install.packages("wordcloud")
require(wordcloud)

outdir="/Users/jdavin/Dropbox/greatschools - share/JosephDavin/analysis/"

### school type
filenames <- list.files("/Users/jdavin/Dropbox/greatschools - share/BrianFeeny/word frequency counts/by-type", full.names=TRUE)
ldf <- lapply(filenames, read.csv,header=F,stringsAsFactors=F)

type <- substr(filenames, 90, 92)

topwords=matrix("",nrow=nrow(ldf[[1]]),ncol=length(ldf))
topfreq=matrix(0,nrow=nrow(ldf[[1]]),ncol=length(ldf))

for(i in 1:length(ldf)){
	topwords[,i]=ldf[[i]][,1]
	topfreq[,i]=ldf[[i]][,2]
}	

for(i in 1:length(type)){
ap.d <- data.frame(word = topwords[-c(1:2),i],freq=topfreq[-c(1:2),i])
#ap.d <- data.frame(word = topwords[,i],freq=topfreq[,i])
table(ap.d$freq)
pal2 <- brewer.pal(8,"Dark2")
png(paste(outdir,"wordcloud-",type[i],sep=""), width=1200,height=800)
wordcloud(ap.d$word,ap.d$freq, scale=c(8,.2),min.freq=2,
max.words=Inf, random.order=FALSE, rot.per=.15, colors=pal2)
dev.off()
}


### reviewer
filenames <- list.files("/Users/jdavin/Dropbox/greatschools - share/BrianFeeny/word frequency counts/by-reviewer", full.names=TRUE)
ldf <- lapply(filenames, read.csv,header=F,stringsAsFactors=F)

reviewer <- substr(filenames, 98, 103)

topwords=matrix("",nrow=nrow(ldf[[1]]),ncol=length(ldf))
topfreq=matrix(0,nrow=nrow(ldf[[1]]),ncol=length(ldf))

for(i in 1:length(ldf)){
	topwords[,i]=ldf[[i]][,1]
	topfreq[,i]=ldf[[i]][,2]
}	

for(i in 1:length(reviewer)){
ap.d <- data.frame(word = topwords[-c(1:2),i],freq=topfreq[-c(1:2),i])
#ap.d <- data.frame(word = topwords[,i],freq=topfreq[,i])
table(ap.d$freq)
pal2 <- brewer.pal(8,"Dark2")
png(paste(outdir,"wordcloud-",reviewer[i],sep=""), width=1200,height=800)
wordcloud(ap.d$word,ap.d$freq, scale=c(8,.2),min.freq=2,
max.words=Inf, random.order=FALSE, rot.per=.15, colors=pal2)
dev.off()
}



