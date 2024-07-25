library(httr)
library(jsonlite)

#get the number of publications from Scopus with multiple keywords and a year filter
get_scopus_count <- function(keywords, api_key, start_year = NULL, end_year = NULL) {
  url <- "https://api.elsevier.com/content/search/scopus"
  
  #combine keywords using AND
  query_string <- paste(keywords, collapse = " AND ")
  
  #add year filters to the query string
  if (!is.null(start_year) && !is.null(end_year)) {
    query_string <- paste0(query_string, " AND PUBYEAR AFT ", start_year - 1,
                           " AND PUBYEAR BEF ", end_year + 1)
  } else if (!is.null(start_year)) {
    query_string <- paste0(query_string, " AND PUBYEAR AFT ", start_year - 1)
  } else if (!is.null(end_year)) {
    query_string <- paste0(query_string, " AND PUBYEAR BEF ", end_year + 1)
  }
  
  query <- list(
    query = query_string,
    apiKey = api_key,
    httpAccept = "application/json"
  )
  
  response <- GET(url, query = query)
  
  if (status_code(response) != 200) {
    stop("Failed to fetch data from Scopus API.
         Please check your API key and query.")
  }
  
  content <- content(response, "text")
  json_data <- fromJSON(content)
  
  count <- as.numeric(json_data$`search-results`$`opensearch:totalResults`)
  
  return(count)
}

#set parameters
api_key <- "xXxXxXxXxXxXxXxXxXxXxXxXxXx"  # replace with API key
keywords <- c("soil", "microplastics", "coastal")
start_year <- 2022
end_year <- 2023
count <- get_scopus_count(keywords, api_key, start_year, end_year)

#output
print(paste("Number of publications on Scopus for keywords",
            paste(keywords, collapse = " AND "), "from", start_year,
            "to", end_year, ":", count))
