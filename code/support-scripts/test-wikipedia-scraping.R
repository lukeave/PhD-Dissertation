library(rvest)
library(tidyverse)

# get url for the Wikipedia page about a specific world's fair
url <- "https://en.wikipedia.org/wiki/Centennial_Exposition"

# read the html script
html <- read_html(url)

# store the html element of the "infobox" as a table
test1 <- html %>% 
  html_elements(xpath = '//*[@id="mw-content-text"]/div[1]/table') %>% # got this from the web page html elements view.
  html_table()
test1 <- test1[[1]]
head(test1)
# test1 is a table in which each variable is a row, and the values are stored in column 2.  

# prepare table for pivoting
colnames(test1)[1] <- "variables"
colnames(test1)[2] <- "values"
test1 <- test1[-1,] # first row is information about the media. remove it

# widen the table
test2 <- pivot_wider(test1, names_from = variables, values_from = values)

# future steps: figure out how to run a loop that goes through each of the Wikipedia pages for world's fairs and extract the same information, adding each info as a new row to the table.
