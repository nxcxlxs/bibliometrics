library(httr)
library(jsonlite)

# function to get the number of publications from Scopus with multiple keywords and a year filter
get_scopus_count <- function(keywords, api_key, start_year = NULL, end_year = NULL) {
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

# set parameters
api_key <- "8e9352f580e657e97a97a21797982e7d"  # replace with API key
keywords <- c("soil", "coastal", "microplastics")
start_year <- 2007 # it can be NULL
end_year <- 2025 # it can be NULL

# get the publication count
count <- get_scopus_count(keywords, api_key, start_year, end_year)

# construct answer based on the year range
print({
  year_range <- if (!is.null(start_year) && !is.null(end_year)) {
    paste("from", start_year, "to", end_year)
  } else if (!is.null(start_year)) {
    paste("from", start_year, "to present")
  } else if (!is.null(end_year)) {
    paste("until", end_year)
  } else {
    "until present"
  }
  
  # print
  paste("Number of publications on Scopus for keywords",
        paste(keywords, collapse = " AND "),
        year_range, ":", count)
})

################################################################################
# generate a dataframe within the years range
years <- start_year:end_year

# vector to store publication counts
publication_counts <- numeric(length(years))

# fetch publication counts for each year
for (i in seq_along(years)) {
  year <- years[i]
  publication_counts[i] <- get_scopus_count(keywords, api_key,
                                            start_year = year,
                                            end_year = year)
}

# data frame (takes a little while)
print({
  data <- data.frame(
    YEAR = years,
    PUBLICATIONS = publication_counts
  )
  data
})

# plot
ggplot(data, aes(x = YEAR, y = PUBLICATIONS)) +
  geom_line(color = "red") +
  geom_point() +
  scale_x_continuous(breaks = seq(min(years), max(years), 1)) +
  scale_y_continuous(breaks = seq(min(publication_counts),
                              max(publication_counts), 535)) +
  labs(
    x = "Year",
    y = "Number of Publications"
  ) +
  theme_minimal()
