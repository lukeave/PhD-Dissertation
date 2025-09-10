# Load required packages
library(httr)
library(jsonlite)
library(tidyverse)


# Write function that takes preview JPG URLs from Library of Congress and returns native-resolution JPGs
loc_full_jpeg_from_preview <- function(iiif_jpg_url) {
  stopifnot(length(iiif_jpg_url) == 1, is.character(iiif_jpg_url))
  if (!grepl("/image-services/iiif/", iiif_jpg_url) || !grepl("default\\.jpg", iiif_jpg_url))
    stop("This is not a LoC IIIF JPEG URL.")
  sub("/full/[^/]+/0/default\\.jpg(#.*)?$", "/full/full/0/default.jpg", iiif_jpg_url)
}

# Write function that takes ALTO XML URLs from Library of Congress and returns native-resolution JPGs
loc_full_jpeg_from_alto <- function(alto_wordcoords_url) {
  stopifnot(length(alto_wordcoords_url) == 1, is.character(alto_wordcoords_url))
  if (!grepl("word-coordinates-service\\?segment=", alto_wordcoords_url))
    stop("This doesn't look like a word-coordinates-service (ALTO) URL.")
  
  # Pull the /service/.../<page>.xml bit after 'segment='
  seg <- sub("^.*segment=/service/", "", alto_wordcoords_url)
  seg <- sub("\\.xml.*$", "", seg)
  
  # Convert /service/... to the IIIF identifier: service:...:0015
  iiif_id <- paste0("service:", gsub("/", ":", seg))
  
  paste0("https://tile.loc.gov/image-services/iiif/",
         iiif_id, "/full/full/0/default.jpg")
}

# Write a wrapper function that takes either format as input and returns full-res JPGs
loc_url_to_full_jpeg <- function(url) {
  stopifnot(length(url) == 1, is.character(url))
  if (grepl("/image-services/iiif/", url) && grepl("default\\.jpg", url)) {
    return(loc_full_jpeg_from_preview(url))
  }
  if (grepl("word-coordinates-service\\?segment=", url)) {
    return(loc_full_jpeg_from_alto(url))
  }
  stop("Argument must be a LoC IIIF JPEG preview URL or a word-coordinates-service ALTO URL.")
}


# test run:
u_prev_1 <- "https://tile.loc.gov/image-services/iiif/service:ndnp:nn:batch_nn_fernandez_ver01:data:sn83030272:00175045065:1893010101:0015/full/pct:6.25/0/default.jpg#h=409&w=327"
u_prev_2 <- "https://tile.loc.gov/image-services/iiif/service:ndnp:nn:batch_nn_fernandez_ver01:data:sn83030272:00175045065:1893010101:0015/full/pct:12.5/0/default.jpg#h=818&w=654"
u_alto <- "https://tile.loc.gov/text-services/word-coordinates-service?segment=/service/ndnp/nn/batch_nn_fernandez_ver01/data/sn83030272/00175045065/1893010101/0015.xml&format=alto_xml"

loc_full_jpeg_from_preview(u_prev_1)
loc_full_jpeg_from_preview(u_prev_2)
loc_full_jpeg_from_alto(u_alto)

# wrapper test:

loc_url_to_full_jpeg(u_prev_1)
loc_url_to_full_jpeg(u_alto)
