

# read data by topics
topicsdata=read.csv("/Users/jdavin/Dropbox/greatschools - share/JosephDavin/analysis/topicsbystate.csv",header=F,stringsAsFactors=F)
names(topicsdata)=c("state","topic","val")

n.states=51

newdata=matrix(0,nrow=51,ncol=9)
for(i in 1:51){
	start=(i-1)*8+1	
	end=(i-1)*8+8	
	newdata[i,1]=topicsdata[start,1]
	newdata[i,2:9]=topicsdata[start:end,3]
}


clust1=kmeans(newdata[,2:9],centers=1)
clust2=kmeans(newdata[,2:9],centers=2)
clust3=kmeans(newdata[,2:9],centers=3)
clust4=kmeans(newdata[,2:9],centers=4)
clust5=kmeans(newdata[,2:9],centers=5)
clust6=kmeans(newdata[,2:9],centers=6)
clust7=kmeans(newdata[,2:9],centers=7)
clust8=kmeans(newdata[,2:9],centers=8)
clust9=kmeans(newdata[,2:9],centers=9)
clust10=kmeans(newdata[,2:9],centers=10)

bet.totss=c(clust1$betweenss,clust2$betweenss,clust3$betweenss,clust4$betweenss,clust5$betweenss,clust6$betweenss,
	clust7$betweenss,
	clust8$betweenss,
	clust9$betweenss,
	clust10$betweenss)


plot(bet.totss,ylab="betweenss/totss")
diff(bet.totss)

# choose 3 clusters

clust3$centers

library(maps)
# name of states in map package
mapstates=map("state",fill=T,plot=F,names=T)

# match to abbreviation which does most of them
statematch=state.abb[match(tolower(mapstates),tolower(state.name))]
# see which is problematic and manually name them
mapstates[which(is.na(statematch))]
statematch[which(is.na(statematch))]=c("DC","MA","MA","MA","MI","MI","NY","NY","NY","NY","NC","NC","NC","VA","VA","VA","WA","WA","WA","WA","WA")
# match to the states in topics data
clust.state=unique(topicsdata[,1])
col.group=clust3$cluster[match(statematch,clust.state)]

colors.touse=c("grey70","chocolate","cadetblue3")


outdir="/Users/jdavin/Dropbox/greatschools - share/JosephDavin/analysis/"
png(paste(outdir,"statemap-clustertopics.png",sep=""), width=1200,height=800)
map("state",fill=T,col=colors.touse[col.group])
dev.off()


cbind(clust.state,clust3$cluster,colors.touse[clust3$cluster])[which(clust3$cluster==1),]
cbind(clust.state,clust3$cluster,colors.touse[clust3$cluster])[which(clust3$cluster==2),]
cbind(clust.state,clust3$cluster,colors.touse[clust3$cluster])[which(clust3$cluster==3),]



