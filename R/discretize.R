#' Discretize badly
#'
#' Low memory and low performance and error-prone version of fasterize.
#' @param x object decomposable to segments
#' @param ... ignored
#'
#' @return haha nothing
#' @export
#'
#' @examples
#' library(raster)
#' x <- silicate::inlandwaters[sample(1:nrow(silicate::inlandwaters), 1), ]
#' if (runif(1) < 0.4) {
#'   x <- sf::st_cast(x, "POLYGON")
#'   x <- x[sample(nrow(x), 1), ]
#' }
#' discretize(x)
discretize <- function(x, ...) {
  p <- silicate::SC0(x)
  r <- raster::raster(spex::spex(x), nrow = 150, ncol = 150)
  polyi <- 1
  idx <- as.matrix(p$object$topology_[[polyi]][c(".vx0", ".vx1")])

  xx <- cbind(p$vertex$x_[idx[,1]],
              p$vertex$x_[idx[,2]])
  yy <- cbind(p$vertex$y_[idx[,1]],
              p$vertex$y_[idx[,2]])

  ## remove horizontal edges
  flat <- yy[,1] == yy[,2]
  if (any(flat)) {
    xx <- xx[!flat, ]
    yy <- yy[!flat, ]
  }
  ## orient edges top to bottom
  change <- yy[,1] < yy[,2]
  if (any(change)){
    xx[change, ] <- xx[change, 2:1]
    yy[change, ] <- yy[change, 2:1]
  }
  edges <- cbind(.x0 = xx[,1], .y0 = yy[,1],
                 .x1 = xx[,2], .y1 = yy[,2])
  ## sort edges top to bottom, left to right
  edges <- as.matrix(dplyr::arrange(tibble::as_tibble(edges), dplyr::desc(.y0), .x0))

  ## slope of edge
  edges <- cbind(edges,
                 slope = (edges[,".y1"] - edges[,".y0"]) /
                   (edges[,".x1"] - edges[,".x0"]))
  edges[!is.finite(edges[, "slope"]), "slope"] <- 0

  row_ys <- yFromRow(r, seq_len(nrow(r))) + res(r)[2]/2
  col_xs <- xFromCol(r, seq_len(ncol(r))) - res(r)[1]/2


  plot(p)
  resy <- res(r)[2L]
  resx <- res(r)[1L]
  for (irow in seq_along(row_ys)) {
    active <- edges[,".y0"] >= row_ys[irow] & edges[,".y1"] < row_ys[irow]
    if (any(active)) {
      (idx <- which(active))
      (ycount <- ceiling((edges[idx, ".y0"] - row_ys[irow]) / resy))
      (s <- edges[idx, "slope"])
      (x0 <- edges[idx, ".x0"])
      s <- 1/s
      s[!is.finite(s)] <- 0
      (xx <- x0 + -s * resy * ycount)

      fill <- matrix(findInterval(sort(xx), col_xs),
                     ncol = 2, byrow = TRUE)
      draw_fill(col_xs, fill, row_ys[irow])
    }
  }
  invisible("ha ha nothing")
}