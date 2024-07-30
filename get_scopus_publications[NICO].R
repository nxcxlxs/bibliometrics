# Load necessary libraries
library(httr)
library(jsonlite)
library(openxlsx)

# get publication details from Scopus with multiple keywords and year filters
get_scopus_publications <- function(keywords, api_key, start_year = NULL,
                                    end_year = NULL, start_index = 0, count = 25) {
  url <- "https://api.elsevier.com/content/search/scopus"
  
  # combine keywords using AND
  query_string <- paste(keywords, collapse = " AND ")
  
  # add year filters to the query string
  if (!is.null(start_year) && !is.null(end_year)) {
    query_string <- paste0(query_string, " AND PUBYEAR AFT ", start_year - 1,
                           " AND PUBYEAR BEF ", end_year + 1)
  } else if (!is.null(start_year)) {
    query_string <- paste0(query_string, " AND PUBYEAR AFT ", start_year - 1)
  } else if (!is.null(end_year)) {
    query_string <- paste0(query_string, " AND PUBYEAR BEF ", end_year + 1)
  }
  
  # API request
  response <- GET(url, 
                  add_headers(`X-ELS-APIKey` = api_key),
                  query = list(query = query_string,
                               httpAccept = "application/json",
                               start = start_index,
                               count = count))
  
  if (status_code(response) != 200) {
    stop("Failed to fetch data from Scopus API.
         Please check your API key and query.")
  }
  
  content <- content(response, "text", encoding = "UTF-8")
  json_data <- fromJSON(content)
  
  return(json_data)
}

# set parameters
api_key <- "xXxXxXxXxXxXxXxXxXxXxXxXxXx"  #replace with valid API key
keywords <- c("soil", "microplastics", "coastal")
start_year <- 2022
end_year <- 2023

# get publication data
json_data <- get_scopus_publications(keywords, api_key, start_year, end_year)

# extract authors, titles and DOIs
author <- json_data$`search-results`$entry$`dc:creator`
title <- json_data$`search-results`$entry$`dc:title`
doi <- json_data$`search-results`$entry$`prism:doi`

# data frame
article_data <- data.frame(
  Title = title,
  DOI = doi,
  Authors = sapply(author, function(x)
    if (is.null(x)) NA
    else paste(x, collapse = ", ")),
  stringsAsFactors = FALSE
)

# write spreadsheet
write.xlsx(article_data, paste0("scopus_articles_",
                                start_year, "-",
                                end_year, ".xlsx"))
