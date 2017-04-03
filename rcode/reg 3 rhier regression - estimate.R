
rm(list=ls())
library(bayesm)

#newdata=read.csv("/Users/jdavin/Desktop/greatschools/reg/cs109_regwide_lvl2_20131212.txt")[,-1]
indata=read.csv("/Users/jdavin/Desktop/greatschools/reg/cs109_regwide_lvl1_20131212.txt")[,-1]

## keep only those with 500 matched reviews in the state
keepstates=names(which(table(indata[,2])>500))
newdata=indata[(which(indata[,2] %in% keepstates)),]


# lunch, test scores, school type
x=cbind(1,newdata[,5],newdata[,6],newdata[,8])
y=newdata[,-c(1:8)] # relative to school type
y=cbind(y[,-2],y[,2]) # relative to behavior
#y=cbind(y[,-4],y[,4]) # relative to other

#set.seed(1)
set.seed(871)
param.0=rnorm((ncol(y)-1)*ncol(x))
#loglike(param.0,y,x)




# hier bayesian regression
source("/Users/jdavin/Dropbox/greatschools - share/JosephDavin/regression/rhierMultinomial.R")



# MCMC parameters
R = 60000
keep=5
mcmc.sd=.1
sd.step=500

## put into data for mcmc
regdata=NULL
states=keepstates
nlgt=length(states) # number of states


for (i in 1:nlgt) {
	instate=which(newdata[,2]==states[i])

  regdata[[i]]=list(y=y[instate,],X=x[instate,])
}


Data=list(regdata=regdata)
Mcmc=list(R=R,mcmc.sd=mcmc.sd,sd.step=sd.step,keep=keep)

# Fit HMM Linear model
out=rhierMultinomial(Data=Data,Mcmc=Mcmc)

burn=(R/keep)*.5

par(mfrow=c(3,3))
for(i in 1:9){
	plot(out$Deltadraw[burn:(R/keep),i],type="l")
}

# population effect estimates
matrix(apply(out$Deltadraw[burn:(R/keep),],2,mean),nrow=4)
matrix(apply(out$Deltadraw[burn:(R/keep),],2,quantile,prob=.05),nrow=4)
matrix(apply(out$Deltadraw[burn:(R/keep),],2,quantile,prob=.95),nrow=4)
#sig if positive
sign(matrix(apply(out$Deltadraw[burn:(R/keep),],2,quantile,prob=.05),nrow=4))*sign(matrix(apply(out$Deltadraw[burn:(R/keep),],2,quantile,prob=.95),nrow=4))



# state effect estimates
matrix(apply(out$betadraw[1,,burn:(R/keep)],1,mean),nrow=4)
matrix(apply(out$betadraw[1,,burn:(R/keep)],1,quantile,prob=.05),nrow=4)
matrix(apply(out$betadraw[1,,burn:(R/keep)],1,quantile,prob=.95),nrow=4)
#sig if positive

sig=matrix(0,nrow=4,ncol=7)
coef.sig=matrix(0,nrow=28,ncol=length(states))
coef.mat=matrix(0,nrow=28,ncol=length(states))


for(i in 1:length(states)){
thissig=ifelse(sign(matrix(apply(out$betadraw[i,,burn:(R/keep)],1,quantile,prob=.05),nrow=4))*sign(matrix(apply(out$betadraw[i,,burn:(R/keep)],1,quantile,prob=.95),nrow=4))>0,1,0)
sig=sig+thissig
coef=matrix(apply(out$betadraw[i,,burn:(R/keep)],1,mean),nrow=4)

sigcoef=thissig*coef
coef.sig[,i]=c(sigcoef)
coef.mat[,i]=c(coef)

}

sign(coef.sig)
coef.sig







par(mfrow=c(3,3))
for(i in 1:7){
	plot(out$betadraw[i,i,burn:(R/keep)],type="l")
}
plot(out$llike,type="l")
plot(out$step,type="l")



