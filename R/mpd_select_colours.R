#' Select colours from a palette to maximize perceptual distance between the colours
#' 
#' This function takes a palette as a character vector of hexidecimal colours, and returns a smaller palette, 
#' attempting to maximize the mean perceptual distance (MPD) between the colours in the new palette. It uses CIELAB
#' colorspace to map colour to a perceptually meaningful scale before maximizing distances
#' 
#' @param pal A palette as a character vector containing hexidecimal coded colours
#' @param sat.thresh Minimum saturation of colours in resulting palette (between 0 and 1)
#' @param light.thresh Maximum luminosity of colours in resulting palette (between 0 and 1)
#' @param dark.thresh Minimum luminosity of colours in resulting palette (between 0 and 1)
#' @param nreps The number of samples of the new colour palette to perform for brute force optimization of MPD
#' @param ncolours The number of colours to select for the new palette
#' @param nreturn The number of palettes to return
#' @return If \code{nreturn} > 1 then a list of length \code{nreturn}, each element of which is a character vector of length ncolours consisting of hexidecimal colour codes, 
#' else a character vector of length ncolours consisting of hexidecimal colour codes
#' @importFrom picante mpd
#' @import colorspace
#' @export
mpd_select_colours <- function(pal, sat.thresh = NULL, light.thresh = NULL, dark.thresh = NULL, nreps = 10000, ncolours = ceiling(length(pal)/2), nreturn = 1) {
  if (ncolours > length(pal)) {
    stop("Number of colours to select must be less than the total number of colours in the palette")  
  }
  if (ncolours < 2) {
    stop("You must select at least two colours")  
  }
  ## get rid of undesirable colours
  pal_red <- palette_reduce(pal, sat.thresh = sat.thresh, light.thresh = light.thresh, dark.thresh = dark.thresh)
  if (length(pal_red) == 0) {
    stop("No colours after thresholding")  
  }
  if (length(pal_red) < 2) {
    stop("Too few colours after thresholding")  
  }
  ## convert hex colours to RGB space
  cols <- hex2RGB(pal_red, gamma = TRUE)
  rownames(cols@coords) <- pal_red
  ## convert colours to CIELAB colorspace
  cols.LAB <- coords(as(cols, "LAB"))
  ## generate distances between all colours in perceptual space
  col_dists <- dist(cols.LAB)
  ## randomly sample nreps palettes of ncolours
  col_samp <- t(replicate(nreps, as.numeric((rownames(cols.LAB) %in% sample(rownames(cols.LAB),ncolours)))))
  colnames(col_samp) <- rownames(cols.LAB)
  ## calculate MPD: Mean Phylogenetic Distance, which happens to have the same acronym as Mean Perceptual Distance :)
  col_mpd <- mpd(col_samp, as.matrix(col_dists))
  ## take indices of only unique values of MPD
  col_unique <- which(duplicated(col_mpd)==FALSE)
  ## return top nreturn palettes in a list
  if (nreturn > length(col_unique)) {
    warning("There were fewer than nreturn palettes generated; Returning all palettes")
    new_pals_index <- apply(col_samp[col_unique,], 1, function(x) x==1)
    new_pals <- apply(new_pals_index, 2, function(x) rownames(new_pals_index)[x])
    new_pals <- lapply(seq_len(ncol(new_pals)), function(x) new_pals[,x])
    new_pals <- new_pals[order(col_unique)]
  } else {
    col_unique <- col_unique[rank(-col_mpd[col_unique]) <= nreturn]
    if (nreturn > 1) {
      new_pals_index <- apply(col_samp[col_unique,], 1, function(x) x==1)
      new_pals <- apply(new_pals_index, 2, function(x) rownames(new_pals_index)[x])
      new_pals <- lapply(seq_len(ncol(new_pals)), function(x) new_pals[,x])
      new_pals <- new_pals[order(col_unique)]
    } else {
      new_pals_index <- col_samp[col_unique,]==1
      new_pals <- names(new_pals_index)[new_pals_index]  
    }
  }
  return(new_pals)  
}
