#GenericPred_nowindow.R
#PaulR
#11/4/2014

rm(list=ls())
# setwd("C:/Users/PRobson/Desktop/Cool Stuff/GenericPred")
setwd("/home/tj/repos/time-series-prediction/")
getwd()

require(tseriesChaos)
require("parallel")

#Setup params
min_date<-"07/01/2001"
max_date<-"07/01/2007"

#Import TS and limit down to relevant dates
sn <- read.csv("DJA.csv",header=TRUE)
sn$Date <- as.Date(sn$Date,format="%m/%d/%Y")
sn.ho <- sn[sn$Date>as.Date(max_date,format="%m/%d/%Y"),]
sn <- sn[sn$Date>=as.Date(min_date,format="%m/%d/%Y"),]
sn <- sn[sn$Date<=as.Date(max_date,format="%m/%d/%Y"),]
sndj <- sn$DJIA
snho <- sn.ho$DJIA

### ek: alternate way to do the above loop
s.dif <- -1*diff(sndj)

## EK: looks pretty damn gaussian..with the exception of really extreme outliers
hist(s.dif,nclass=50,main="Conditional Distribution P(yi|yi+1)") 

## EK: should the above be P(yi+1 | yi)?  -- e.g.:   s.dif <- diff(sndj)
s <- sqrt(mean(s.dif)) ## EK: note to self RMS difference

## Function to sample values and output best prediction based on given criteria
sample_next_value<-function(in.ds, start.yn, stdev,n.samp)
{
  Pos <- rnorm(n=n.samp, mean=start.yn, sd=stdev)
  jmin <- matrix(NA,nrow=n.samp,ncol=2)
  jmin1 <- invisible(lyap_k(as.ts(sndj), m=1, d=1, ref=length(sndj), t=5, s=3, eps=10)[2])
  for (k in 1:n.samp)
  {
    #lyap_k(time_series, embedding dimension, time delay, number of points take into account, theiler window, iterations following neighbors)
    vsn2 <- invisible(lyap_k(as.ts(append(in.ds,Pos[k])), m=1, d=1, ref=length(in.ds)+1, t=5, s=3, eps=10)[2])
    jmin[k,1]<-abs(jmin1-vsn2)
    jmin[k,2]<-Pos[k]
  }

  jmin <- jmin[order(jmin[,1]),] ## this works
best.y <- jmin[1,2]  
  return(best.y) 
}


#### EK: below i made the whole above thing into a couple functions
runGenericPred <- function(lead_time=600, s=3)
{
  yn <- sndj[length(sndj)]
  yi <- sample_next_value(in.ds=sndj, start.yn=yn, stdev=s, n.samp=2)
  sndj.p <- append(sndj,yi)
  t <- 1
  while(t <= lead_time)
  {
    yi <- sample_next_value(in.ds=sndj.p, start.yn=yi, stdev=s, n.samp=2)
    sndj.p <- append(sndj.p, yi)
    t <- t + 1
  }

  return(sndj.p)
}


boot <- function(x) { return(runGenericPred(lead_time=600))}


runGenericPredStochastic <- function(iter = 2, LEAD_TIME=5)
{
  prediction_array <- NULL
  i <- 1
  temp <- mclapply(i:iter, boot)
  prediction_array <- do.call(cbind, temp)
  cat(dim(prediction_array))
  return(prediction_array)
}



plot_stochastic_experiment <- function(training = sndj, predictions=stochastic_experiment, holdout=snho[1:600])
{
  xmax <- length(training) + length(holdout)
  ymin <- min(c(training, predictions, holdout))
  ymax <- max(c(training, predictions, holdout))
  plot(x= 1:length(training),
      y=training,
      xlim=c(1, xmax), 
      ylim=c(ymin, ymax), lwd=1 , type='l' )
  lines(x= (length(training)+1): xmax, y=holdout, col='blue', lwd=2   )
  

  for(i in 1:ncol(predictions))
  {
    lines(x= (length(training)+1): xmax, y=predictions[(length(training)+1): xmax,i], col='#ff000050', lwd=1   )
  }

  lines(x= (length(training)+1): xmax, y=rowMeans(predictions[(length(training)+1): xmax,]), col='#ff0000', lwd=3   )

  xx <- c((length(training)+1): xmax, rev((length(training)+1): xmax))

  holdout_predictions <- predictions[(length(training)+1): xmax,]
  upper_bound <- apply(FUN=max, X=holdout_predictions, MARGIN=1)
  lower_bound <- apply(FUN=min, X=holdout_predictions, MARGIN=1)

  yy <- c(lower_bound, rev(upper_bound))
  polygon(x=xx, y=yy, col="#ff000010", border=NA) 
}

lead_time <- 600
stochastic_experiment <- invisible(runGenericPredStochastic(iter = 50, LEAD_TIME=lead_time))
plot_stochastic_experiment(training = sndj, predictions=stochastic_experiment, holdout = snho[1:lead_time])


dst = lyap_k(as.ts(sndj), m=1, d=2, ref=length(sndj), t=5, s=200, eps=10)
dst = dst[2:length(dst)]
plot(dst)
lyap(as.ts(dst), 0, end=7)

