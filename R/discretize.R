#' Discretize, not too badly
#'
#' Low memory and low performance and error-prone version of fasterize.
#' @param x object decomposable to segments
#' @param ... ignored
#'
#' @return haha nothing
#' @export
#' @importFrom raster extent raster res yFromRow xFromCol
#' @importFrom dplyr arrange
#' @importFrom tibble as_tibble
#' @examples
#' library(raster)
#' library(silicate)
#' sc <- SC(inlandwaters)
#' x <- sc #filter(sc, object_ == sample(sc$object$object_, 3))
#' discretize(x, 1500, 1300)
#'
#'
#' discretize(SC0(minimal_mesh), 550, 550)
discretize <- function(x, nrow = 50, ncol = 30, ..., draw = TRUE) {
  p <- silicate::SC0(x)
  r <- raster::raster(raster::extent(range(p$vertex$x_), range(p$vertex$y_)),
                      nrow = nrow, ncol = ncol)
  if (draw && raster::ncell(r) > 5e6) {
    warning("we aren't going to draw this")
    draw <- FALSE
  }
#  polyi <- sample(1:nrow(p$object), 1)
#  idx <- as.matrix(p$object$topology_[[polyi]][c(".vx0", ".vx1")])
idx <- as.matrix(do.call(rbind, p$object$topology_)[c(".vx0", ".vx1")])
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
  resy <- raster::res(r)[2L]
  resx <- raster::res(r)[1L]

  row_ys <- raster::yFromRow(r, seq_len(nrow(r))) + resy/2
  col_xs <- raster::xFromCol(r, seq_len(ncol(r))) - resx/2

  if (draw) plot(p$vertex$x_, p$vertex$y_, asp = 1, pch = ".")
  nfill <- 0
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
      nfill <- nfill + dim(fill)[1L]
      if (draw) draw_fill(col_xs, fill, row_ys[irow])
    }
  }
#  abline(h = row_ys, v = col_xs)

 cat(sprintf("scanned %i lines\n", irow))
  cat(sprintf("produced %i fill bands\n", nfill))
  invisible("ha ha nothing")
}
