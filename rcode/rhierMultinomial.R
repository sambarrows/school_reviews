rhierMultinomial=function (Data, Prior, Mcmc) 
{
rmultireg=function (Y, X, Bbar, A, nu, V) {
    n = nrow(Y)
    m = ncol(Y)
    k = ncol(X)
    RA = chol(A)
    W = rbind(X, RA)
    Z = rbind(Y, RA %*% Bbar)
    IR = backsolve(chol(crossprod(W)), diag(k))
    Btilde = crossprod(t(IR)) %*% crossprod(W, Z)
    S = crossprod(Z - W %*% Btilde)
    rwout = rwishart(nu + n, chol2inv(chol(V + S)))
    B = Btilde + IR %*% matrix(rnorm(m * k), ncol = m) %*% t(rwout$CI)
    return(list(B = B, Sigma = rwout$IW))
}

### likelihood function

loglike=function(param,y,x){
	

	# x = N x p, p = number of covariates
	# y is N x k, k = number of choices
	# param is vector of length p*k

	N=nrow(y)
	k=ncol(y)
	param.mat=matrix(param,ncol=(k-1))
	util=cbind(exp(x %*% param.mat),1) # fix last option = 1
	pchoice=matrix(c(util)/c(rowSums(util)),nrow=N)
	ll=sum(y*log(pchoice))
	return(ll)
}


adjust.step=function(stepsize,reject.vector){
		perc=1-mean(reject.vector) # accept rate
		if(perc>.6){
			stepsize=stepsize*1.2
		}
		if(perc>.5){
			stepsize=stepsize*1.1
		}
		if(perc>.4){
			stepsize=stepsize*1.05
		}
		if(perc<.05){
			stepsize=stepsize*.95
		}
		if(perc<.1){
			stepsize=stepsize*.9
		}
		if(perc<.2){
			stepsize=stepsize*.8
		}
		return(stepsize)
}	






    append = function(l) {
        l = c(l, list(XpX = crossprod(l$X), Xpy = crossprod(l$X, 
            l$y)))
    }
    getvar = function(l) {
        v = var(l$y)
        if (is.na(v)) 
            return(1)
        if (v > 0) 
            return(v)
        else return(1)
    }
    pandterm = function(message) {
        stop(message, call. = FALSE)
    }
    if (missing(Data)) {
        pandterm("Requires Data argument -- list of regdata and Z")
    }
    if (is.null(Data$regdata)) {
        pandterm("Requires Data element regdata")
    }
    regdata = Data$regdata
    nreg = length(regdata)
    if (is.null(Data$Z)) {
        cat("Z not specified -- putting in iota", fill = TRUE)
        Z = matrix(rep(1, nreg), ncol = 1)
    } else {
        if (nrow(Data$Z) != nreg) {
            pandterm(paste("Nrow(Z) ", nrow(Z), "ne number regressions ", 
                nreg))
        }
        else {
            Z = Data$Z
        }
    }
    nz = ncol(Z)
    nvar = ncol(regdata[[1]]$X)*(ncol(regdata[[1]]$y)-1)
    if (missing(Prior)) {
        Deltabar = matrix(rep(0, nz * nvar), ncol = nvar)
        A = 0.01 * diag(nz)
        nu.e = 3
        nu = nvar + 3
        V = nu * diag(nvar)
    }   else {
        if (is.null(Prior$Deltabar)) {
            Deltabar = matrix(rep(0, nz * nvar), ncol = nvar)
        }    else {
            Deltabar = Prior$Deltabar
        }
        if (is.null(Prior$A)) {
            A = 0.01 * diag(nz)
        }        else {
            A = Prior$A
        }
        if (is.null(Prior$nu.e)) {
            nu.e = 3
        }        else {
            nu.e = Prior$nu.e
        }
        if (is.null(Prior$nu)) {
            nu = nvar + 3
        }        else {
            nu = Prior$nu
        }
        if (is.null(Prior$V)) {
            V = nu * diag(nvar)
        }        else {
            V = Prior$V
        }
    }
    if (ncol(A) != nrow(A) || ncol(A) != nz || nrow(A) != nz) {
        pandterm(paste("bad dimensions for A", dim(A)))
    }
    if (nrow(Deltabar) != nz || ncol(Deltabar) != nvar) {
        pandterm(paste("bad dimensions for Deltabar ", dim(Deltabar)))
    }
    if (ncol(V) != nvar || nrow(V) != nvar) {
        pandterm(paste("bad dimensions for V ", dim(V)))
    }
    if (missing(Mcmc)) {
        pandterm("requires Mcmc argument")
    }    else {
        if (is.null(Mcmc$R)) {
            pandterm("requires Mcmc element R")
        }    else {
            R = Mcmc$R
        }
        if (is.null(Mcmc$keep)) {
            keep = 1
        }    else {
            keep = Mcmc$keep
        }
    }
    cat(" ", fill = TRUE)
    cat("Starting MH for multinomial", 
        fill = TRUE)
    cat("   ", nreg, " Regressions", fill = TRUE)
    cat("   ", ncol(Z), " Variables in Z (if 1, then only intercept)", 
        fill = TRUE)
    cat(" ", fill = TRUE)
    cat("Prior Parms: ", fill = TRUE)
    cat("Deltabar", fill = TRUE)
    print(Deltabar)
    cat("A", fill = TRUE)
    print(A)
    cat("nu.e (d.f. parm for regression error variances)= ", 
        nu.e, fill = TRUE)
    cat("Vbeta ~ IW(nu,V)", fill = TRUE)
    cat("nu = ", nu, fill = TRUE)
    cat("V ", fill = TRUE)
    print(V)
    cat(" ", fill = TRUE)
    cat("MCMC parms: ", fill = TRUE)
    cat("R= ", R, " keep= ", keep, fill = TRUE)
    cat(" ", fill = TRUE)
    Vbetadraw = matrix(double(floor(R/keep) * nvar * nvar), ncol = nvar * 
        nvar)
    Deltadraw = matrix(double(floor(R/keep) * nz * nvar), ncol = nz * 
        nvar)
    betadraw = array(double(floor(R/keep) * nreg * nvar), dim = c(nreg, 
        nvar, floor(R/keep)))
    Delta = c(rep(0, nz * nvar))
    Vbeta = as.vector(diag(nvar))
	rej.keep=rep(0,R)
	logl.keep=rep(0,R/keep)
	mcmc.keep=rep(0,R/keep)
    betas = matrix(double(nreg * nvar), ncol = nvar)
#    regdata = lapply(regdata, append)
    itime = proc.time()[3]
    cat("MCMC Iteration (est time to end - min) ", fill = TRUE)
    for (rep in 1:R) {
        Abeta = chol2inv(chol(matrix(Vbeta, ncol = nvar)))
        betabar = Z %*% matrix(Delta, ncol = nvar)
	rej=0
	logl=0
        for (reg in 1:nreg) {

            betad = betas[reg, ]
            betan = betad + rnorm(nvar,mean=0,sd=mcmc.sd)

	    paramd = c(betad)
	    paramn = c(betan)

	    lognew = loglike(param=paramn,
			y=regdata[[i]]$y,
			x=regdata[[i]]$X)

	    logold = loglike(param=paramd,
			y=regdata[[i]]$y,
			x=regdata[[i]]$X)
				
            logknew = -0.5 * t(betan - Delta) %*% 
                matrix(Vbeta,ncol=nvar) %*% (betan - Delta )
            logkold = -0.5 * t(betad - Delta ) %*% 
                matrix(Vbeta,ncol=nvar) %*% (betad - Delta )
            alpha = exp(lognew + logknew - logold - logkold)
            if (alpha == "NaN") {
                alpha = -1
		}
            u = runif(n = 1, min = 0, max = 1)
            if (u < alpha) {
                betas[reg,]= betan
                logl = logl + lognew
            } else {
                logl = logl + logold
                rej = rej + 1
            }


        }
        rmregout = rmultireg(betas, Z, Deltabar, A, nu, V)
        Vbeta = as.vector(rmregout$Sigma)
        Delta = as.vector(rmregout$B)

	rej.keep[rep]=rej/nreg

        if ((rep>=(2*sd.step)) && (rep%%sd.step == 0)) {
		mcmc.sd=adjust.step(mcmc.sd,rej.keep[(rep-sd.step):rep])
	
        }


        if (rep%%100 == 0) {
            ctime = proc.time()[3]
            timetoend = ((ctime - itime)/rep) * (R - rep)
            cat(" ", rep, " (", round(timetoend/60, 1), ")", 
                fill = TRUE)
        }
        if (rep%%keep == 0) {
            mkeep = rep/keep
            Vbetadraw[mkeep, ] = Vbeta
            Deltadraw[mkeep, ] = Delta
            betadraw[, , mkeep] = betas
		logl.keep[mkeep]=logl
		mcmc.keep[mkeep]=mcmc.sd
        }
    }
    ctime = proc.time()[3]
    cat("  Total Time Elapsed: ", round((ctime - itime)/60, 2), 
        "\n")
    attributes(Deltadraw)$class = c("bayesm.mat", "mcmc")
    attributes(Deltadraw)$mcpar = c(1, R, keep)
    attributes(Vbetadraw)$class = c("bayesm.var", "bayesm.mat", 
        "mcmc")
    attributes(Vbetadraw)$mcpar = c(1, R, keep)
    attributes(betadraw)$class = c("bayesm.hcoef")
    return(list(Vbetadraw = Vbetadraw, Deltadraw = Deltadraw, 
        betadraw = betadraw,llike=logl.keep,rej=rej.keep,step=mcmc.keep))
}
