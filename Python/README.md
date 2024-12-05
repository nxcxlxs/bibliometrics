# **DISCLAIMER:**

**This script is designed to fetch publication data from the Scopus® API, a service provided by Elsevier.**
**The Scopus® API allows researchers and developers to query a vast database of academic publications programmatically.**

**An API, or Application Programming Interface, is a set of rules and protocols that allows software applications to communicate with each other. APIs define how requests are made, what data format to use and how responses are returned. They are commonly used to access data or services provided by external plataforms, enabling developers to integrate external functionalitites into their own applications.**

***THIS SCRIPT REQUIRES A VALID SCOPUS API KEY TO FUNCTION!***

**An API key is a unique identifier provided by Elsevier to access their API services.**
**You must have an active Scopus account and request a key to use this script.**

**Visit [Elsevier Develop Portal](https://dev.elsevier.com/sc_apis.html) for more information.**

#

*The code fetches scientific publication details based on user-defined search parameters, processes the data, and outputs the results to a spreadsheet and a bar chart. This project is based in a R script written to help bibliometrics studies from Sengis (Federal University of Santa Catarina Laboratory of Sensing, Inovation and Geoprocessing) and is available in [my personal GitHub](https://github.com/nxcxlxs/bibliometrics.)*

**Information about data structure, query construction method, API description, root-endpoint and response formats where acquired in the Elsevier's Scopus guides and documentations:**

• [Scopus LibGuide](https://elsevier.libguides.com/Scopus/topical-search)

• [Elsevier Scopus APIs: Getting Started Guide](https://dev.elsevier.com/guides/Scopus%20API%20Guide_V1_20230907.pdf)


## LIBRARIES:
• `requests`: Handles HTTP requests to the Scopus API.

• `pandas`: Processes and organizes data into a DataFrame for saving to Excel.

• `time`: Introduces delays to avoid API rate limits.

• `matplotlib.pyplot`: Creates visualizations of publication trends over time.

• `tqdm`: Displays a progress bar during data fetching.

• `sys`: Handles system-level actions, such as exiting the script.

• `re`: Provides tools for working with regular expressions, used here to replace illegal characters before using it for the output files names.

• `datetime`: Facilitates date and time operations, such as obtaining the current year dynamically.

• `pytest`: Main framework for testing.

• `pytest-mock`: Plugin that extends `pytest` to help with mocking in tests.

## FUNCTIONS:
• `build_query_string(keywords, countries, start_year, end_year)`: Constructs the search query string for the Scopus API.

• `extract_fields(entry)`: Extracts author, title, DOI, date and affiliations countries details from the API response entry.

• `fetch_publication_details(keywords, api_key, countries, start_year, end_year)`: Retrieves publications data from Scopus API.<br>
Handle large results using `start` and `count` parameters to fetch in batches, uses `time.sleep()` to delay between requests and tracks the progress using `tqdm()`.

• `save_to_excel(data, filename)`: Creates a spreadsheet (.xlsx) using `pandas`

• `plot_publication_by_year(publications, output_file)`: Creates a bar chart (.png) for the annual count of publications.

• `main()`: Collects user inputs for search parameters, fetching, saving and plotting.<br>



# **HOW TO USE**

First of all, execute `python -m pip install -r requirements.txt` to install the packages needed.

By running `python project.py` the user will be prompted to:

0. Keywords: Enter terms for querying publications (*e.g.*, "fertility AND soil").

1. Scopus API Key: Provide key to access the API.

4. Countries (comma-separated, optional): Specify countries to filter results by affiliations.

5. Start Year (integer, optional): Define the starting year for publication filtering. Defaults to 1788 (temporal coverage as informed by [Scopus Wikipedia page](https://en.wikipedia.org/wiki/Scopus))

6. End Year (integer, optional): Define the ending year for publication filtering. Defaults to the current year.
