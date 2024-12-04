library(httr)
library(jsonlite)
library(ggplot2)

# function to get the number of publications from Scopus with multiple keywords and a year filter
get_scopus_count <- function(keywords, api_key,
                             start_year = NULL, end_year = NULL) {
  url <- "https://api.elsevier.com/content/search/scopus"
  
  # combine keywords using AND
  query_string <- paste(keywords, collapse = " AND ")
  
  # filter to avoid mentions in REFERENCES
  query_string <- paste0("TITLE-ABS-KEY(", query_string, ")")
  
  # filter for affiliation countries plus "brazil"
  #countries <- paste(countries, collapse = " OR ")
  query_string <- 
    paste0(query_string, " AND AFFILCOUNTRY(", countries, ")") 
  
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
api_key <- "XXXXXXXXXXXXXXXXX"  # replace with API key
keywords <- c("microplastic", "(soil OR land OR terrestrial)")
countries <- c("brazil")
start_year <- 2013
end_year <- 2023

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
  paste0("Number of publications on Scopus for keywords ",
         paste(keywords, collapse = " AND "), " ", year_range, ": ", count)
})

################################################################################
#            PLOT FOR DATA THAT INCLUDE TERMS FETCHED IN ALL FIELDS            # 
################################################################################
# generate a data frame within the years range
if (!is.null(start_year)) {
  years <- start_year:end_year
} else {
  # if start_year is NULL, assume we want from a default start year to end_year
  default_start_year <- 2000
  years <- default_start_year:end_year
}

# vector to store publication counts
publication_counts <- numeric(length(years))

# fetch publication counts for each year (takes a little while)
for (i in seq_along(years)) {
  year <- years[i]
  publication_counts[i] <- get_scopus_count(keywords, api_key,
                                            start_year = year,
                                            end_year = year)
}

# data frame
print(
  data <- data.frame(
    YEAR = years,
    PUBLICATIONS = publication_counts
  ))

# plot
ggplot(data, aes(x = YEAR, y = PUBLICATIONS)) +
  geom_line(color = "red") +
  geom_point() +
  scale_x_continuous(breaks = seq(min(years), max(years), 1)) +
  scale_y_continuous(breaks = seq(min(publication_counts),
                              max(publication_counts), 535)) +
  labs(                                             # ^ watch out for the increment of the sequence
    x = "Ano",
    y = "Número de publicações") +
  theme_minimal() +
  theme(
    panel.grid.major.y = element_line(color = "grey75"),
    panel.grid.minor.y = element_line(color = "grey80"),
    panel.grid.major.x = element_blank(),
    panel.grid.minor.x = element_blank(),
    axis.text.x = element_text(angle = 90, hjust = 0, margin = margin(t = -10)),
    axis.title.x = element_text(margin = margin(t = 10)),
    axis.title.y = element_text(margin = margin(r = 10)))

################################################################################
#   PLOT AND EXPONENTIAL TREND LINE FOR DATA FILTERED BY THE "TITLE-ABS-KEY"   #
################################################################################
# transform the data for exponential regression
data$log_publications <- log(data$PUBLICATIONS + 1)  # Adding 1 to avoid log(0)

# fit an exponential model (linear model on log-transformed data)
exp_model <- lm(log_publications ~ YEAR, data = data)

# extract coefficients and calculate R²
coefficients <- coef(exp_model)
r_squared <- summary(exp_model)$r.squared

# create the exponential equation text
intercept <- gsub("\\.", ",", round(coefficients[1], 5))
slope <- gsub("\\.", ",", round(coefficients[2], 5))

# construct the equation with proper formatting
exp_eq <- bquote(italic(y) == italic(e)^{.(intercept) + (.(slope) * italic(x))} - 1)

# format R² value
r_squared_formatted <- gsub("\\.", ",", format(round(r_squared, 2)))
r_squared_text <- bquote(italic(R)^2 == .(r_squared_formatted))

# convert expressions to character strings
exp_eq_str <- as.character(as.expression(exp_eq))
r_squared_text_str <- as.character(as.expression(r_squared_text))

# predict the fitted values on the original scale
data$fit <- exp(predict(exp_model)) - 1 # subtract 1 to reverse the log transformation

# plot with annotations
ggplot(data, aes(x = YEAR, y = PUBLICATIONS)) +
  #geom_line(color = "darkred", size = 1.25) +
  geom_point(size = 2.25, color = "darkred") +
  #geom_line(aes(y = fit), color = "darkorange", linetype = 9, linewidth = 1.25) +  # exponential trend line
  geom_line(aes(y = fit), color = "darkorange", linetype = 9, linewidth = 1.25) +
  scale_x_continuous(breaks = seq(min(data$YEAR), max(data$YEAR), 1)) +
  scale_y_continuous(breaks = seq(0, max(data$PUBLICATIONS) + 5, 5)) +
  labs(
    x = "Ano",
    y = "Número de publicações"
  ) +
  theme_minimal() +
  theme(
    axis.title.x = element_text(margin = margin(t = 10)),
    axis.title.y = element_text(margin = margin(r = 10)),
    axis.text.x = element_text(angle = 90, hjust = 0, margin = margin(t = -10)),
    panel.grid.major.y = element_line(color = "grey75"),
    panel.grid.minor.y = element_blank(),
    panel.grid.major.x = element_blank(),
    panel.grid.minor.x = element_blank(),
  ) +
  annotate("text", x = max(data$YEAR) - 4.5, y = max(data$PUBLICATIONS) - 12.2, 
           label = exp_eq_str, color = "black", size = 3.7 , parse = TRUE) +
  annotate("text", x = max(data$YEAR) - 4.1, y = max(data$PUBLICATIONS) - 13.8, 
           label = r_squared_text_str, color = "black", size = 3.7, parse = TRUE)
