# Load required packages
library(tidyverse)
library(wordVectors)

#### Vector Model Training ####

# retrieve and store each OCR'ed item as an individual text file
newdir <- paste("data/Chicago_1893/txt_files/") # make sure to replace this for the local path of the directory you want to create for text files in your machine
if (!dir.exists(newdir)) {
  dir.create(newdir, recursive = TRUE)
}

for (i in 1:length(metadata$ocr_eng)) {
  filename <- paste0(metadata$lccn[i], "_", metadata$title[i], "_", metadata$full_date[i], "_page_", metadata$sequence[i], ".txt") # this is the best way I found to name each OCR file uniquely.
  print(paste0("retrieving OCR: Row ", metadata$rowID[i], "..."))
  file_content <- paste(metadata$ocr_eng[i])
  write_file(file_content, file = paste0(newdir, filename))
  print(paste0("file ", filename, " ", "created."))
}

# create full corpus text file (in case word vector analysis or similar is expected)
# this code comes from Schmidt's word2vec code. hence why the library is loaded
fullcorpus_dir <- paste("data/Chicago_1893/full_corpi/") # change to your local path
if (!dir.exists(fullcorpus_dir)) {
  dir.create(fullcorpus_dir, recursive = TRUE)
}

if (!file.exists("data/Chicago_1893/full_corpi/1893-fullcorpus.txt")) prep_word2vec(origin="data/Chicago_1893/txt_files/",destination="data/Chicago_1893/full_corpi/1893-fullcorpus.txt")

if (!file.exists("data/Chicago_1893/full_corpi/1893-fullcorpus.bin")) {model = train_word2vec("data/Chicago_1893/full_corpi/1893-fullcorpus.txt","data/Chicago_1893/full_corpi/1893-fullcorpus.bin",vectors=100,threads=4,window=30,iter=30,negative_samples=0)} else model = read.vectors("data/Chicago_1893/full_corpi/1893-fullcorpus.bin")