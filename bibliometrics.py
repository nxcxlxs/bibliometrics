import requests
import pandas as pd
import matplotlib.pyplot as plt
import time
import re


# function to get the number of publications from Scopus
def get_scopus_count(keywords, api_key, countries, start_year=None, end_year=None):
    url = "https://api.elsevier.com/content/search/scopus"
    query_string = f"TITLE-ABS-KEY({keywords})"

    if countries:
        query_string = f"{query_string} AND AFFILCOUNTRY({' OR '.join(countries)})"

    if start_year and end_year:
        query_string = f"{query_string} AND PUBYEAR AFT {start_year - 1} AND PUBYEAR BEF {end_year + 1}"
    elif start_year:
        query_string = f"{query_string} AND PUBYEAR AFT {start_year - 1}"
    elif end_year:
        query_string = f"{query_string} AND PUBYEAR BEF {end_year + 1}"

    query = {
        "query": query_string,
        "apiKey": api_key,
        "httpAccept": "application/json"
    }

    response = requests.get(url, params=query)

    if response.status_code != 200:
        raise Exception("Failed to fetch data from Scopus API. Please check your API key and query.")

    json_data = response.json()
    count = int(json_data["search-results"]["opensearch:totalResults"])
    return count


# function to get publication details from Scopus
def get_scopus_publications(keywords, api_key, countries,
                            start_year=None, end_year=None,
                            start_index=0, count=200):
    url = "https://api.elsevier.com/content/search/scopus"
    query_string = f"TITLE-ABS-KEY({keywords})"

    if countries:
        query_string = f"{query_string} AND AFFILCOUNTRY({' OR '.join(countries)})"

    if start_year and end_year:
        query_string = f"{query_string} AND PUBYEAR AFT {start_year - 1} AND PUBYEAR BEF {end_year + 1}"
    elif start_year:
        query_string = f"{query_string} AND PUBYEAR AFT {start_year - 1}"
    elif end_year:
        query_string = f"{query_string} AND PUBYEAR BEF {end_year + 1}"

    headers = {
        "X-ELS-APIKey": api_key,
        "Accept": "application/json"
    }

    params = {
        "query": query_string,
        "start": start_index,
        "count": count
    }

    response = requests.get(url, headers=headers, params=params)

    if response.status_code != 200:
        raise Exception("Failed to fetch data from Scopus API. Please check your API key and query.")

    json_data = response.json()
    return json_data


def main():
    # get user input
    keywords_input = input("Enter keywords: ")
    api_key = input("Enter your Scopus API key: ")
    countries_input = input("Enter affiliation countries: ")
    start_year_input = input("Enter start year: ")
    end_year_input = input("Enter end year: ")

    countries = countries_input.split() if countries_input else []
    start_year = int(start_year_input) if start_year_input else None
    end_year = int(end_year_input) if end_year_input else None

    # Determine if the input is a simple space-separated or a complex query
    if 'OR' in keywords_input or 'AND' in keywords_input or '*' in keywords_input:
        keywords = keywords_input
    else:
        keywords = " AND ".join(keywords_input.split())

    # construct the query string
    query_string = f"TITLE-ABS-KEY({keywords})"
    if countries:
        query_string = f"{query_string} AND AFFILCOUNTRY({' OR '.join(countries)})"
    if start_year and end_year:
        query_string = f"{query_string} AND PUBYEAR AFT {start_year - 1} AND PUBYEAR BEF {end_year + 1}"
    elif start_year:
        query_string = f"{query_string} AND PUBYEAR AFT {start_year - 1}"
    elif end_year:
        query_string = f"{query_string} AND PUBYEAR BEF {end_year + 1}"

    # construct the filename based on the query string
    clean_query_string = re.sub(r'[():"\s]|(?:AND|OR)', lambda m:
        '_AND_' if m.group(0) == 'AND' else
        '_OR_' if m.group(0) == 'OR' else
        '_' if m.group(0).isspace() else
        '', query_string)

    filename = f"scopus_articles_{clean_query_string}.xlsx"

    # get the total number of publications
    total_results = get_scopus_count(keywords, api_key, countries, start_year, end_year)
    print(f"Total publications: {total_results}")

    # Fetch publication counts for each year
    if start_year and end_year:
        years = list(range(start_year, end_year + 1))
    elif start_year:
        years = list(range(start_year, time.localtime().tm_year + 1))
    elif end_year:
        years = list(range(1900, end_year + 1))
    else:
        years = list(range(1900, time.localtime().tm_year + 1))

    publication_counts = []

    for year in years:
        count = get_scopus_count(keywords, api_key, countries, start_year=year, end_year=year)
        publication_counts.append(count)

    # create a data frame
    data = pd.DataFrame({
        "YEAR": years,
        "PUBLICATIONS": publication_counts
    })

    # plot the data
    plt.figure(figsize=(10, 6))
    plt.plot(data["YEAR"], data["PUBLICATIONS"], marker='o', color='red')
    plt.xlabel("Year")
    plt.ylabel("Number of Publications")
    plt.title("Number of Publications Over Years")
    plt.grid(True)
    plt.xticks(years)
    plt.yticks(range(0, max(publication_counts) + 5, 5))
    plt.show()

    # fetch detailed publication data
    batch_size = 200
    all_articles = []

    for start_index in range(0, total_results, batch_size):
        json_data = get_scopus_publications(keywords, api_key, countries, start_year, end_year, start_index, batch_size)
        entries = json_data["search-results"]["entry"]

        for entry in entries:
            authors = entry.get("dc:creator", "")
            title = entry.get("dc:title", "")
            doi = entry.get("prism:doi", "")
            date = entry.get("prism:coverDate", "")
            affiliation_countries = ", ".join([aff["affiliation-country"] for aff in entry.get("affiliation", [])])

            all_articles.append({
                "Authors": authors,
                "Title": title,
                "Date": date,
                "DOI": doi,
                "AffiliationCountry": affiliation_countries
            })

        time.sleep(1)  # delay to avoid hitting API limits

    # create a data frame for all articles
    df_articles = pd.DataFrame(all_articles)
    print(f"Total articles fetched: {len(df_articles)}")

    # write to Excel
    df_articles.to_excel(filename, index=False)


if __name__ == "__main__":
    main()
