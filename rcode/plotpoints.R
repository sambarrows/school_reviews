library(maps)
library(colorRamps)

nat <- read.table("/Users/sambarrows/Dropbox/greatschools - share/SamBarrows/stars_lat_lon_national.txt", sep=",")
head(nat)
range(nat$V1)
hist(nat$V1)

rbPal <- colorRampPalette(c('red','green'))
cutpoints = length(seq(2, 5, 2/8)) - 0.00000000001
nat$Col <- rbPal(20)[as.numeric(cut(nat$V1,breaks = cutpoints))]
#nat$Col <- heat.colors(10)[as.numeric(cut(nat$V1,breaks = cutpoints))]


map("state", interior=FALSE)
map("state", boundary=FALSE, col="gray", add=TRUE)
points(y=nat$V2, x=nat$V3, col=nat$Col, cex=0.2, pch=16)


