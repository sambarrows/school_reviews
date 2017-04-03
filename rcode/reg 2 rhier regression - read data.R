regdata=read.csv("/Users/jdavin/Desktop/greatschools/reg/cs109_gs_regression_set_review_level_20131212.txt",header=F,stringsAsFactors=F)[,-1]

dim(regdata)
names(regdata)=c("school_name","state","type","lunch_perc","topic1","topic2","score2011","score2012","star","val")

# make into wide data
n.topics=30
n.schools=nrow(regdata)/n.topics
newdata=data.frame(matrix(0,nrow=n.schools,ncol=(n.topics+ncol(regdata)-2)))
for(i in 1:n.schools){
	start=(i-1)*n.topics+1	
	end=(i-1)*n.topics+n.topics
	newdata[i,1:4]=regdata[start,1:4]
	newdata[i,5:7]=regdata[start,7:9]
	newdata[i,8]=ifelse(regdata[start,3]=="charter",1,0)
	newdata[i,-c(1:8)]=regdata[start:end,10]
	if(i %% 250 == 0){
		cat("Finished", i,"of",n.schools,"\n")
	}
}

shortdata=data.frame(matrix(0,nrow=nrow(newdata),ncol=16))
shortdata[,1:8]=newdata[,1:8]
shortdata[,9]=rowSums(newdata[,9:11])
shortdata[,10]=newdata[,12]
shortdata[,11]=newdata[,13]
shortdata[,12]=rowSums(newdata[,14:18])
shortdata[,13]=rowSums(newdata[,19:24])
shortdata[,14]=rowSums(newdata[,25:31])
shortdata[,15]=rowSums(newdata[,32:33])
shortdata[,16]=rowSums(newdata[,34:38])


write.csv(newdata,"/Users/jdavin/Desktop/greatschools/reg/cs109_regwide_lvl2_review_20131212.txt")
write.csv(shortdata,"/Users/jdavin/Desktop/greatschools/reg/cs109_regwide_lvl1_review_20131212.txt")

a=newdata


#newdata=read.csv("/Users/jdavin/Desktop/greatschools/reg/cs109_regwide_lvl2_20131212.txt")[,-1]
newdata=read.csv("/Users/jdavin/Desktop/greatschools/reg/cs109_regwide_lvl1_20131212.txt")[,-1]

# lunch, test scores, school type
x=cbind(1,newdata[,5],newdata[,6],newdata[,8])
y=newdata[,-c(1:8)]
#y=cbind(y[,-2],y[,2])

#set.seed(1)
set.seed(871)
param.0=rnorm((ncol(y)-1)*ncol(x))



