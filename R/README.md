# **IMPORTANT NOTICE:**

**This script is designed to fetch publication data from the Scopus® API, a service provided by Elsevier.**
**The Scopus® API allows researchers and developers to query a vast database of academic publications programmatically.**

**An API, or Application Programming Interface, is a set of rules and protocols that allows software applications to communicate with each other. APIs define how requests are made, what data format to use and how responses are returned. They are commonly used to access data or services provided by external platforms, enabling developers to integrate external functionalities into their own applications.**

***THIS SCRIPT REQUIRES A VALID SCOPUS API KEY TO FUNCTION!***

**An API key is a unique identifier provided by Elsevier to access their API services.**
**You must have an active Scopus account and request a key to use this script.**

**Visit [Elsevier Developer Portal](https://dev.elsevier.com/sc_apis.html) for more information.**

#

*The code fetches scientific publication details based on user-defined search parameters, processes the data, and outputs the results to a spreadsheet and a bar chart. This project is based on an R script written to help bibliometric studies from Sengis (Federal University of Santa Catarina Laboratory of Sensing, Innovation, and Geoprocessing) and is available in [my personal GitHub](https://github.com/nxcxlxs/bibliometrics/tree/main/R)*

**Information about data structure, query construction method, API description, root-endpoint, and response formats were acquired from Elsevier's Scopus guides and documentation:**

• [Scopus LibGuide](https://elsevier.libguides.com/Scopus/topical-search)

• [Elsevier Scopus APIs: Getting Started Guide](https://dev.elsevier.com/guides/Scopus%20API%20Guide_V1_20230907.pdf)

## LIBRARIES:
• `httr`: Handles HTTP requests to the Scopus API.

• `jsonlite`: Processes JSON data returned by the Scopus API.

• `ggplot2`: Creates visualizations of publication trends over time.

• `openxlsx`: Processes and organizes data into a DataFrame for saving to Excel.

## FUNCTIONS:
• `get_scopus_count(keywords, api_key, start_year, end_year, countries)`: Constructs the search query string for the Scopus API and retrieves the count of publications.

• `get_scopus_publications(keywords, api_key, start_year, end_year, start_index, count, countries)`: Retrieves publications data from the Scopus API. Handles large results using `start` and `count` parameters to fetch in batches, uses `Sys.sleep()` to delay between requests.

• `main()`: Collects user inputs for search parameters, fetches publication data, saves the data to a spreadsheet (.xlsx), and creates a bar chart (.png) for the annual count of publications.

# **HOW TO USE**

First of all, ensure you have R and the necessary packages installed. You can install the required packages using the following commands:


`install.packages("httr")`
`install.packages("jsonlite")
`install.packages("ggplot2")`
`install.packages("openxlsx")`


# **HOW TO USE**

0. Keywords: Enter terms for querying publications (e.g., "microplastic AND soil").

1. Scopus API Key: Provide the key to access the API.

2. Countries (comma-separated, optional): Specify countries to filter results by affiliations.

3. Start Year (integer, optional): Define the starting year for publication filtering.

4. End Year (integer, optional): Define the ending year for publication filtering.
