library(httr)
library(jsonlite)
library(openxlsx)

# get publication details from Scopus with multiple keywords and year filters
get_scopus_publications <- function(keywords, api_key, start_year = NULL,
                                    end_year = NULL, start_index = 0, count = 200) {
  url <- "https://api.elsevier.com/content/search/scopus"
  
  # combine keywords using AND
  query_string <- paste(keywords, collapse = " AND ")
  
  # filter to avoid mentions in REFERENCES
  query_string <- paste0("TITLE-ABS-KEY(", query_string, ")")
  
  # filter for affiliation countries plus "brazil"
  #countries <- paste(countries, collapse = " OR ")
  query_string <- paste0(query_string, " AND AFFILCOUNTRY(", countries, ")") 
  
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
    stop("Failed to fetch data from Scopus API. Please check your API key and query.")
  }
  
  content <- content(response, "text", encoding = "UTF-8")
  json_data <- fromJSON(content)
  
  return(json_data)
}

# set parameters
api_key <- "XXXXXXXXXXXXXXXXXXXX"  # replace with your API key
keywords <- c("microplastic","(soil OR land OR terrestrial)")
countries <- c("brazil")
start_year <- 2013
end_year <- 2024

# get the total number of publications
initial_data <- get_scopus_publications(keywords, api_key, start_year, end_year, 0, 1)
total_results <- as.numeric(initial_data$`search-results`$`opensearch:totalResults`)
batch_size <- 200 # that's the limit imposed by Scopus API

# initialize data frame to store all results
all_articles <- data.frame()

# loop to fetch data in batches
for (start_index in seq(0, total_results - 1, by = batch_size)) {
  # Fetch data for the current batch
  json_data <- get_scopus_publications(keywords, api_key, start_year, end_year, start_index, batch_size)
  
  # extract authors, titles, dates, DOIs, and affiliated countries
  author <- json_data$`search-results`$entry$`dc:creator`
  title <- json_data$`search-results`$entry$`dc:title`
  doi <- json_data$`search-results`$entry$`prism:doi`
  date <- json_data$`search-results`$entry$`prism:coverDate`
  
  # extract affiliation countries
  affiliation_countries <- sapply(json_data$`search-results`$entry$affiliation, function(x) {
    if (!is.null(x)) {
      paste(x$`affiliation-country`, collapse = ", ")
    } else {
      NA
    }
  })
  
  # create data frame for the current batch
  batch_data <- data.frame(
    Authors = sapply(author, function(x) if (is.null(x)) NA
              else paste(x, collapse = ", ")),
    Title = title,
    Date = date,
    DOI = doi,
    AffiliationCountry = affiliation_countries,
    stringsAsFactors = FALSE
  )
  
  # append batch data to the main data frame
  all_articles <- rbind(all_articles, batch_data)
  
  # delay to avoid hitting API limits
  Sys.sleep(1)
}

# print the number of articles retrieved
print(paste("Total articles fetched:", nrow(all_articles)))

# write the excel file
write.xlsx(all_articles, paste0("scopus_articles_", start_year, "-", end_year, ".xlsx"))
