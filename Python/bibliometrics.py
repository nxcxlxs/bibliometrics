import requests
import pandas as pd
import time
import matplotlib.pyplot as plt
from tqdm import tqdm
import sys
import re
import datetime


def main():
    # user input
    keywords_input = input("Enter keywords (e.g., fertility AND soil): ")
    api_key = input("Enter your Scopus API key: ")
    countries_input = input("Enter affiliation countries (comma-separated, optional): ")
    start_year = input("Enter start year (optional): ") or "1788"  # temporal coverage informed in Scopus Wikipedia page
    end_year = input("Enter end year (optional): ") or str(datetime.datetime.now().year)

    try:
        start_year = int(start_year)
        end_year = int(end_year)
    except ValueError:
        print("Years must be integers.")
        return

    countries = [country.strip() for country in countries_input.split(",")] if countries_input else []

    # build query string
    query_string = build_query_string(keywords_input, countries, start_year, end_year)

    # clear query string for filenames
    clean_query = re.sub(r'[<>:"/\\|?*]', '_', query_string)

    # fetch publication details
    publications = fetch_publication_details(keywords_input, api_key, countries, start_year, end_year)

    # save data to Excel with query string as filename
    output_excel = f"{clean_query}.xlsx"
    df = pd.DataFrame(publications, columns=["Author", "Title", "DOI", "Date", "Affiliation Countries"])
    df.to_excel(output_excel, index=False, engine='openpyxl')
    print(f"Data saved to {output_excel}")

    # save plot with query string as filename
    output_plot = f"{clean_query}.png"
    years = [int(pub[3].split("-")[0]) if pub[3] != "N/A" else None for pub in publications]
    years = [year for year in years if year is not None]  # remove None values

    # count publications per year
    publication_counts = pd.Series(years).value_counts().sort_index()

    # plot the data
    plt.figure(figsize=(10, 6))
    plt.bar(publication_counts.index, publication_counts.values, color='skyblue')
    plt.xticks(publication_counts.index, rotation=45, fontsize=10)
    plt.xlabel("Year", fontsize=12)
    plt.ylabel("Publication Count", fontsize=12)
    plt.title("Publications Over Time", fontsize=14)
    plt.grid(axis="y", linestyle="--", alpha=0.7)
    plt.tight_layout()

    # save plot
    plt.savefig(output_plot, dpi=300)
    print(f"Plot saved as {output_plot}")

    sys.exit()


# function to build the query string
def build_query_string(keywords, countries, start_year, end_year):
    query = f"TITLE-ABS-KEY({keywords})"
    if countries:
        query += f" AND AFFILCOUNTRY({' OR '.join(countries)})"
    if start_year:
        query += f" AND PUBYEAR AFT {start_year - 1}"
    if end_year:
        query += f" AND PUBYEAR BEF {end_year + 1}"
    return query


# function to fetch publication details from Scopus
def fetch_publication_details(keywords, api_key, countries, start_year, end_year):
    url = "https://api.elsevier.com/content/search/scopus"
    query_string = build_query_string(keywords, countries, start_year, end_year)
    headers = {"X-ELS-APIKey": api_key, "Accept": "application/json"}
    publications = []

    start = 0
    count = 25  # number of entries per API request
    total_results = None

    print("Fetching publication data from Scopus...")
    while True:
        # fetch the first batch to determine the total number of results
        params = {"query": query_string, "start": start, "count": count}
        response = requests.get(url, headers=headers, params=params)
        if response.status_code != 200:
            raise Exception(f"API request failed with status code {response.status_code}.\n{response.text}")

        json_data = response.json()
        if total_results is None:
            total_results = int(json_data["search-results"]["opensearch:totalResults"])
            print(f"Total publications found: {total_results}")
            progress_bar = tqdm(total=total_results, desc="Fetching publications", unit=" entries")

        entries = json_data["search-results"].get("entry", [])
        for entry in entries:
            publications.append(extract_fields(entry))
            progress_bar.update(1)  # update progress bar for each entry

        # break the loop if all results are processed
        start += count
        if start >= total_results:
            break

        # sleep to avoid hitting rate limits
        time.sleep(0.5)

    progress_bar.close()  # close the progress bar when done
    return publications


# function to extract required fields from a single entry
def extract_fields(entry):
    author = entry.get("dc:creator", "N/A")
    title = entry.get("dc:title", "N/A")
    doi = entry.get("prism:doi", "N/A")
    date = entry.get("prism:coverDate", "N/A")

    # extract affiliation countries
    affiliations = entry.get("affiliation", [])
    affiliation_countries = ", ".join(
        aff.get("affiliation-country", "N/A") if aff.get("affiliation-country") else "N/A"
        for aff in affiliations
    )
    return author, title, doi, date, affiliation_countries


if __name__ == "__main__":
    main()
