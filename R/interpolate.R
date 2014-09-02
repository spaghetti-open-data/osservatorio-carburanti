

# http://casoilresource.lawr.ucdavis.edu/drupal/node/442
library(sp)
library(gstat)
library(raster)

#CREATE VIEW prezzi_benzina AS SELECT X(d.the_geom) x,Y(d.the_geom) y, p.prezzo prezzo FROM distributori d JOIN prezzi p ON d.id=p.id_d JOIN (SELECT p2.id_d, MAX(p2.dIns) dIns FROM prezzi p2 GROUP BY id_d) pmax ON p.id_d=pmax.id_d AND  p.dIns = pmax.dIns  WHERE p.carb='Benzina' AND isSelf=1;
d <- read.csv('prezzi_benzina.csv')
## gstat does not like missing data, subset original data:
e <- na.omit(d)


## convert simple data frame into a spatial data frame object:
coordinates(e) <- ~ x+y
e=remove.duplicates(e)

e$elev=e$elev*1000
e=e[e$elev >= 1500,]

## test result with simple bubble plot:
#bubble(e, zcol='elev', fill=FALSE, do.sqrt=FALSE, maxsize=2)

if (file.exists('italiaGrid.RData')) {
        load('italiaGrid.RData')
} else { if (FALSE) {
                ## create a grid onto which we will interpolate:
                ## first get the range in data
                x.range <- range(e@coords[,1])
                y.range <- range(e@coords[,2])

                ## now expand to a grid with 0.1 spacing:
                grd <- expand.grid(x=seq(from=x.range[1], to=x.range[2], by=0.02), y=seq(from=y.range[1], to=y.range[2], by=0.02) )

                ## convert to SpatialPixel class
                #coordinates(grd) <- ~ x+y
                #gridded(grd) <- TRUE
                gridded(grd) <- ~ x+y

                library(maptools)
                clipShape=readShapeSpatial("download/confini/italia")
                clipShape$COD_REG=NULL
                clipShape$NOME_REG=NULL
                clipShape$SHAPE_Leng=NULL
                clipShape$SHAPE_Area=NULL

                clipShape$ciSono=1

                grd=grd[which(!is.na(over(grd,clipShape))),]
        }
}
#lst=over(grd,clipShape)

#library(FNN)
#data=data.matrix(cbind(e$x,e$y))
#query=data.matrix(cbind(grd$x,grd$y))
#
#grd=grd[which(knnx.dist(data,query,k=1)<0.3),]

library(raster)
fit=idw(elev~1,e,grd,idp=0.7)

r=raster(fit)

library(classInt)

breakPoints=classIntervals(values(r),n=100,style='kmeans')
#cols=heat.colors(100)
#cols=colorRampPalette(c("blue", 'white',"red"))( 100 )
#cols=colorRampPalette(c("blue","red"))( 100 )
cols=colorRampPalette(c("lightblue","darkred"))( 100 )
png('prezziBenzinaSelf.png',width=2000,height=2000)
plot(r,breaks=breakPoints$brks,col=cols)
dev.off()

### make gstat object:
#g <- gstat(id="elev", formula=elev ~ 1, data=e)
#
### the original data had a large north-south trend, check with a variogram map
#plot(variogram(g, map=TRUE, cutoff=0.5, width=200), threshold=10)
#
### another approach:
## create directional variograms at 0, 45, 90, 135 degrees from north (y-axis)
##v <- variogram(g, alpha=c(0,45,90,135))
#v <- variogram(g, map=TRUE, cutoff=0.5)
#
### 0 and 45 deg. look good. lets fit a linear variogram model:
### an un-bounded variogram suggests additional source of anisotropy... oh well.
##v.fit <- fit.variogram(v, model=vgm(model='Lin' , anis=c(0, 0.5)))
#v.fit <- fit.variogram(v, model=vgm(model='Gau',range=0.1))
#
### plot results:
#plot(v, model=v.fit, as.table=TRUE)
#
### update the gstat object:
#g <- gstat(g, id="elev", model=v.fit,maxdist=0.1)
#
### perform ordinary kriging prediction:
#p <- predict(g, model=v.fit, newdata=grd)
#
#par(mar=c(2,2,2,2))
#image(p, col=terrain.colors(20))
#contour(p, add=TRUE, drawlabels=FALSE, col='brown')
#points(e, pch=4, cex=0.5)
#title('OK Prediction')
#
#pts <- list("sp.points", e, pch = 4, col = "black", cex=0.5)
#spplot(p, zcol="elev.pred", col.regions=terrain.colors(20), cuts=19, sp.layout=list(pts), contour=TRUE, labels=FALSE, pretty=TRUE, col='brown', main='OK Prediction')
#
### plot the kriging variance as well
#spplot(p, zcol='elev.var', col.regions=heat.colors(100), cuts=99, main='OK Variance',sp.layout=list(pts) )
#
