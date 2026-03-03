library(terra)
r <- flip(rast("data-raw/sooty_windsor.png"), "vertical")
plotRGB(r, asp = 1)
## from plotrix::hexagon
unitcell <- nrow(r)-190
x <- 20
y <- 95
xx <- cbind(cbind(c(x, x, x + unitcell/2, x + unitcell, x + unitcell,
        x + unitcell/2), c(y + unitcell * 0.125, y + unitcell *
        0.875, y + unitcell * 1.125, y + unitcell * 0.875, y +
        unitcell * 0.125, y - unitcell * 0.125)))
lines(rbind(xx, xx[1,]))

p <- vect(xx, "poly")
writeRaster(mask(r, p, inverse = F), "man/figures/hex-sooty.png", datatype = "INT1U")
