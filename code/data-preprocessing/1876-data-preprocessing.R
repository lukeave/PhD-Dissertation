# Load required packages
library(httr)
library(jsonlite)
library(tidyverse)
library(wordVectors)

####--------- API Request for Philadelphia 1876 World's Fair --------####

## As of Summer 2025, Chronicling America's dedicated API is deprecated.This script was updated in September of 2025 to reflect recent changes to the Library of Congress API and the JSON Response Objects to bulk data requests. Please refer to the LoC-API-Data-Dictionary.txt file. # nolint: line_length_linter.

## The base URL below is an advanced search for the phrase "centennial exhibition" across all newspaper publications in 1876. # nolint: line_length_linter.

## "&c=" facet in the URL is the number of matches per result page. Recent update allows up to 160 per page, but I recommend 100 as a parameter here. In any case make sure to keep track of how many results per page you're using. # nolint: line_length_linter.

## "&sb =" currently sorts query results by title. The option to sort by date (both ascending and descending) seems to be causing random duplicates in the API request. Final metadata files have been sorted by date (oldest to new), and the rowID reflects that. # nolint: line_length_linter.


####----------- Prep Steps ----------------####

# Define fixed base URL (first page of query results)
base_url <- "https://www.loc.gov/collections/chronicling-america/?c=100&dl=page&end_date=1876-12-31&ops=PHRASE&qs=centennial+exhibition&searchType=advanced&start_date=1876-01-01&language=english&fo=json&sb=title_s" # nolint: line_length_linter. # nolint: line_length_linter.

# Define fair year that names data, metadata, and code files
fair_year <- "1876"

# Set max_results to the total number of matching results to the query
# Alternatively, set max_results to an arbitrary number if breaking Request into multiple sessions is necessary
max_results <- 7866

# Get file paths
state_path <- paste0("metadata/API-Request-Info/", fair_year, "-state.rds")
partial_path <- "metadata/Partial-Results/"
partial_results <- paste0(partial_path, fair_year, "-newspaper-metadata_partial.csv")
complete_path <- "metadata/Complete-Results/"
complete_results <- paste0(complete_path, fair_year, "-newspaper-metadata.csv")


# Initialize empty data frame to store results
results <- data.frame()

# Check if this request has already been initiated before. If so, resume from where previous session stopped. # nolint: line_length_linter.

if (file.exists(state_path)) {
  state <- readRDS(state_path)
  existent_file <- read.csv(ifelse(file.exists(complete_results), complete_results, partial_results))
  current_page <- as.numeric(state$current_page)
  retrieved_results <- as.numeric(state$retrieved_results)
  api_url <- state$api_url
} else {
  # Start from page 1 of query results
  api_url <- base_url
  current_page <- 1
  retrieved_results <- 0
}

# Write a function that forces HTTP/1.1 and avoids connection hiccups
safe_GET <- function(url, tries = 10, timeout_s = 30) {
  RETRY(
    "GET", url,
    times = tries,
    pause_base = 1, # 1s, 2s, 4s, 8s, 16s...
    pause_cap = 30,
    terminate_on = c(400, 401, 403, 404), # don't retry hard client errors
    quiet = FALSE,
    timeout(timeout_s),
    user_agent("R (httr) LOC fetcher"),
    config = httr::config(http_version = 2L), # force http/1.1
    add_headers(Connection = "close", Accept = "application/json")
  )
}




####----- API Request Loop -----####

## Loop continues through query results until max_results is reached or no more data is available

while (retrieved_results <= max_results) {

  # If all results have been retrieved, don't repeat loop.
  if (file.exists(complete_results)) {
    merged_metadata <- existent_file
    message("This API request has been done. Complete metadata file already exists.")
    break
  }

  # Send GET request
  print(paste0("New request initiated... Current page: ", current_page, "."))
  response <- safe_GET(api_url)

  # Check if request was successful
  ## usually, successful API requests have a status_code of 200
  if (status_code(response) != 200) {
    message("Error: API request failed.")
    break
  }

  # Parse response as JSON data object
  data <- content(response, as = "text", encoding = "UTF-8") # Store request content in a temporary character vector
  data_json <- fromJSON(data) # Store content from character vector as a JSON object

  print(paste0("Parsing JSON data... Current index range: ", data_json$pagination$results))

  ## Note on data_json$pagination$results: character vector within the JSOn object that shows the index of the first item and the last item being parsed during this time. If the total matches were 2000, and your "&rows=" are 100, then each time the loop runs it will show an index range of 100. Should go up every round. I.e.: 101-200; 201-300; 301-400...) # nolint: line_length_linter.

  # Extract results to current batch
  current_batch <- as.data.frame(data_json$results)

  # Account for duplicates between current batch and total results of this session
  results_with_dupes <- bind_rows(results, current_batch)
  dupes <- results_with_dupes[duplicated(results_with_dupes$page_id), ]
  results <- results_with_dupes %>%
    distinct(page_id, .keep_all = TRUE)

  if (nrow(dupes) == 0 && nrow(results_with_dupes) == nrow(results)) {
    rm(dupes)
    rm(results_with_dupes)
  }

  ## data_json$results is the data frame within the JSON object that contains all the retrieved items for each query match. In this case, each match is a newspaper page in which the query term shows up at least once). # nolint: line_length_linter.

  ## Note on data_json$results$description: consists of a snippet of the back-end OCR data from Chronicling America. That snippet seems to be the words surrounding query search terms. This variable has been renamed to "snippet_ocr" during metadata manipulation. # nolint: line_length_linter.

  ## Note on data_json$results$image_url: contains a list of URLs for each retrieved item that redirects to varied resolutions of JPG scans. This variable is mutated during metadata manipulation to create a new column with a single URL per item that redirects to the item's full-resolution JPG file for OCR processing. # nolint: line_length_linter.


  # Progress log
  if (file.exists(state_path)) {
    retrieved_results <- retrieved_results + nrow(current_batch)
  } else {
    retrieved_results <- nrow(results)
  }
  print(paste0("Total results retrieved: ", retrieved_results, " out of ", data_json$search$hits, "."))

  # Move on to next page
  api_url <- data_json$pagination$`next`
  current_page <- current_page + 1

  ##### Conditions for stopping #####

  # 1) In case we reach the end of the query results
  if (nrow(results) == data_json$search$hits) {
    message("No more results available.")
    break
  }

  # 2) In case we hit our own cap
  if (retrieved_results >= max_results) {
    message("Maximum results reached.")
    break
  }

  # Wait 5 seconds between requests
  print("waiting 5 seconds before next request...")
  Sys.sleep(5)

  ## Note: Must avoid excessive API calls in a short span of time. A 5-second break between requests already takes into account Library of Congress' burst and crawl limits as per the API documentation, although we are erring on the side of caution here. # nolint: line_length_linter.

}




####------ Manipulate Metadata ------####

# Check for duplicate rows -- ideally, none.
print(length(unique(results$page_id)))  # Count unique records
print(nrow(results))                # Count total rows


# Check for duplicate rows in current batch
print(length(unique(current_batch$page_id)))  # Count unique records
print(nrow(current_batch))                # Count total rows

# Remember it is sorted by title. We want to sort it by date before establishing a fixed row ID.
results$date <- as.Date(results$date, "%Y-%m-%d")
results <- results %>%
  arrange(date)

# get rowID for each row.
results <- rowid_to_column(results, var = "rowID") # This will function as a new index. Might keep the old index column as well just in case.

# Create new metadata frame where list columns are converted into character
metadata <- results %>%
  mutate(across(everything(), as.character))
# some columns came as lists. It happens because things like "subjects" include multiple values in a single cell, so it shows up as c("History", "Gender", "Race"), for example. Date column can be converted back to character now, no onus. # nolint: line_length_linter.

metadata <- metadata %>%
  select(-access_restricted, -aka, -campaigns, -composite_location, -location_country, -dates, -digitized, -subject, -location, -extract_timestamp, -group, -hassegments, -mime_type, -number, -number_edition, -number_reel, -online_format, -original_format, -partof, -partof_collection, -partof_division, -resources, -site, -timestamp, -type) # nolint: line_length_linter.

if ("subject_ethnicity" %in% names(metadata)) {
  metadata <- metadata %>%
    select(-subject_ethnicity)
} # This variable sometimes is present, sometimes isn't

# Clean date and location data

# Format full date column and create separate dd, mm, yyyy
names(metadata)[names(metadata) == "date"] <- "full_date"
metadata <- metadata %>%
  mutate(
    year = substr(full_date, 1, 4),
    month = substr(full_date, 6, 7),
    day = substr(full_date, 9, 10)
  )

# Rename title column to descriptive_title first
names(metadata)[names(metadata) == "title"] <- "descriptive_title"

# Split partof_title column into separate attributes
metadata <- metadata %>%
  separate_wider_delim(partof_title, "(", names = c("newspaper_title", "city_of_publication"), too_few = "align_start", too_many = "drop")

# Extract start_date and end_date attributes from city_of_publication
metadata <- metadata %>%
  separate_wider_delim(city_of_publication, ") ", names = c("city_of_publication", "start_date"), too_few = "align_start", too_many = "drop")

metadata <- metadata %>%
  separate_wider_delim(start_date, "-", names = c("start_date", "end_date"), too_few = "align_start", too_many = "drop")

# Clean city_of_publication and create separate state_of_publication column
metadata <- metadata %>%
  separate_wider_delim(city_of_publication, ",", names = c("city_of_publication", "state_of_publication"), too_few = "align_end", too_many = "merge") # nolint: line_length_linter.

# Split state_of_publication into county and state
metadata <- metadata %>%
  separate_wider_delim(state_of_publication, ",", names = c("county_of_publication", "state_of_publication"), too_few = "align_end", too_many = "merge") # NAs introduced by coercion to county_of_publication # nolint: line_length_linter.



# The columns below were previously of class list, so values were formatted like c("Atlanta", "Clemson", "Greenville"). Remove parenthesis and quotations from the values and keep the commas only for easier processing. # nolint: line_length_linter.
metadata <- metadata %>%
  mutate(image_url = gsub('c\\(|\\)|"', "", image_url)) %>%
  mutate(other_title = gsub('c\\(|\\)|"', "", other_title)) %>%
  mutate(location_city = gsub('c\\(|\\)|"', "", location_city)) %>%
  mutate(location_county = gsub('c\\(|\\)|"', "", location_county)) %>%
  mutate(location_state = gsub('c\\(|\\)|"', "", location_state))



# Write function that takes preview JPG URLs from Library of Congress and returns native-resolution JPG URLs
loc_full_jpeg_from_preview <- function(iiif_jpg_url) {
  stopifnot(length(iiif_jpg_url) == 1, is.character(iiif_jpg_url))
  if (!grepl("/image-services/iiif/", iiif_jpg_url) || !grepl("default\\.jpg", iiif_jpg_url))
    stop("This is not a LoC IIIF JPEG URL.")
  sub("/full/[^/]+/0/default\\.jpg(#.*)?$", "/full/full/0/default.jpg", iiif_jpg_url)
}

# Write function that takes ALTO XML URLs from Library of Congress and returns native-resolution JPG URLs
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

# Write a wrapper function that takes either format as input and returns full-res JPG URLs
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

# Isolate one URL from the image_url attribute, discard others
metadata <- metadata %>%
  separate_wider_delim(image_url, ",", name = c("image_url", "trash_1", "trash_2"), too_few = "align_start", too_many = "drop") %>%
  select(-trash_1, -trash_2)

# Create new column for full-res JPG URL
metadata$jpg_url <- ""

# Use image_url to loop over rows and fill new column
for (i in seq_along(metadata$image_url)) {
  u <- metadata$image_url[i]
  if (is.na(u)) next  # skip blanks

  metadata$jpg_url[i] <- tryCatch(
    loc_url_to_full_jpeg(u),
    error = function(e) NA_character_   # keep going if one row fails
  )
}

# Check for duplicate URLs in jpg_url -- ideally, none.
print(length(unique(metadata$jpg_url)))  # Count unique records

# Remove image_url
metadata <- metadata %>%
  select(-image_url)

# reorder columns
metadata <- metadata[, c("rowID", "descriptive_title", "newspaper_title", "other_title", "shelf_id", "number_page", "number_lccn", "page_id", "publication_frequency", "start_date", "end_date", "location_city", "location_county", "location_state", "full_date", "day", "month", "year", "city_of_publication", "county_of_publication", "state_of_publication", "batch", "contributor", "language", "description", "segmentof", "id", "url", "word_coordinates_url", "jpg_url", "index")] # nolint: line_length_linter.

# rename final columns
metadata <- metadata %>%
  rename(
    newspaper_alt_title = other_title,
    sequence            = shelf_id,
    sequence_2          = number_page,
    lccn                = number_lccn,
    city_coverage       = location_city,
    county_coverage     = location_county,
    state_coverage      = location_state,
    provenance          = contributor,
    snippet_ocr         = description,
    resource_url        = segmentof,
    sequence_url        = id,
    query_url           = url,
    query_url_xml       = word_coordinates_url
  )

# create new columns for manual data collection
metadata$status <- ""
metadata$notes <- ""

metadata$rowID <- as.numeric(metadata$rowID)
metadata$index <- as.numeric(metadata$index)
metadata$sequence <- as.numeric(metadata$sequence)
metadata$sequence_2 <- as.numeric(metadata$sequence_2)
metadata$day <- as.numeric(metadata$day)
metadata$month <- as.numeric(metadata$month)
metadata$year <- as.numeric(metadata$year)

# Account for duplicates between new results and existent file before appending
if (file.exists(partial_results)) {
  metadata_with_dupes <- bind_rows(metadata, existent_file)
  duplicates <- metadata_with_dupes[duplicated(metadata_with_dupes$page_id), ]
  metadata_without_dupes <- metadata_with_dupes %>%
    distinct(page_id, .keep_all = TRUE)
  if (nrow(metadata_with_dupes) == nrow(metadata_without_dupes)) {
    rm(metadata_with_dupes)
    rm(metadata_without_dupes)
    rm(duplicates)
    dupes <- FALSE
  } else {
    dupes <- TRUE
  }
} else {
  dupes <- FALSE
}

# Create merged metadata file
if (dupes == TRUE) {
  merged_metadata <- metadata_without_dupes
} else {
  if (file.exists(partial_results)) {
    merged_metadata <- bind_rows(metadata, existent_file)
  } else {
    merged_metadata <- metadata
  }
}




####------ Save Results ------####

if (nrow(merged_metadata) == data_json$search$hits) {
  # If all results were fetched, create final metadata file.
  write.csv(merged_metadata, complete_results, row.names = FALSE)
  file.remove(partial_results)
  message("API Request for this data set complete. Final metadata file created.")
} else {
  if (file.exists(partial_results)) {
    # If results are partial, append to existing file.
    message("Appending new results to existing partial results...")
    write.csv(merged_metadata, partial_results, row.names = FALSE)
    message("Partial metadata file updated.")
  } else {
    # If this is the first batch of results, indicate that.
    message("Creating metadata file to store first bach of results...")
    write.csv(merged_metadata, partial_results, row.names = FALSE)
    message("Partial metadata file created.")
  }
}


# Aggregate results and rank newspapers by highest count
newspaper_count <- merged_metadata %>%
  group_by(newspaper_title, city_of_publication, state_of_publication) %>%
  summarise(count = n())

write.csv(newspaper_count, paste0("metadata/Results-Count/", fair_year, "-newspaper-count.csv"), row.names = FALSE)

# Store counters information in RDS file
saveRDS(
  list(current_page = current_page,
       retrieved_results = retrieved_results,
       api_url = api_url),
  state_path
)
