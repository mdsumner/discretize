draw_fill <- function(xs, rle, y) {
  for (i in seq_len(nrow(rle))) {
    xxs <- xs[seq(rle[i, 1], rle[i, 2])]
    points(cbind(xxs, y), pch = ".")
  }
}
