from bibliometrics import build_query_string, extract_fields, fetch_publication_details

def test_build_query_string():
    assert build_query_string("soil", ["brazil"], 2013, 2014) == "TITLE-ABS-KEY(soil) AND AFFILCOUNTRY(brazil) AND PUBYEAR AFT 2012 AND PUBYEAR BEF 2015"
    assert build_query_string("fertility", [], None, None) == "TITLE-ABS-KEY(fertility)"
    assert build_query_string("nitrogen", ["usa"], None, None) == "TITLE-ABS-KEY(nitrogen) AND AFFILCOUNTRY(usa)"
    assert build_query_string("phosphate", [], 2020, None) == "TITLE-ABS-KEY(phosphate) AND PUBYEAR AFT 2019"
    assert build_query_string("potassium", [], None, 2024) == "TITLE-ABS-KEY(potassium) AND PUBYEAR BEF 2025"


def test_extract_fields():
    assert extract_fields(
        {"dc:creator": "Mastalygina E.",
         "dc:title": "Biodegradation in Soil of Commercial Plastic Bags Labelled as “Biodegradable”",
         "prism:doi": "10.1590/1980-5373-MR-2022-0164",
         "prism:coverDate": "2023-01-01",
         "affiliation": [{"affiliation-country": "Russian Federation"},
                         {"affiliation-country": "Russian Federation"}]
         }
    ) == ("Mastalygina E.", "Biodegradation in Soil of Commercial Plastic Bags Labelled as “Biodegradable”",
         "10.1590/1980-5373-MR-2022-0164", "2023-01-01", "Russian Federation, Russian Federation")
    assert extract_fields(
        {"dc:creator": "Mastalygina E.",
         "dc:title": "Biodegradation in Soil of Commercial Plastic Bags Labelled as “Biodegradable”",
         "prism:doi": "10.1590/1980-5373-MR-2022-0164",
         "prism:coverDate": "2023-01-01",
         "affiliation": [{"affiliation-country": None}]
         }
    ) == ("Mastalygina E.", "Biodegradation in Soil of Commercial Plastic Bags Labelled as “Biodegradable”",
         "10.1590/1980-5373-MR-2022-0164", "2023-01-01", "N/A")


def test_fetch_publication_details(mocker):
    response = mocker.Mock()
    response.status_code = 200
    response.json.return_value = {
        "search-results": {
            "opensearch:totalResults": 2,
            "entry": [
                {"dc:creator": "De Bernardi A.",
                 "dc:title": "Integrated assessment of the chemical, microbiological and ecotoxicological effects of a bio-packaging end-of-life in compost",
                 "prism:doi": "10.1016/j.scitotenv.2024.175403",
                 "prism:coverDate": "2024-11-15",
                 "affiliation": [{"affiliation-country": "Italy"}]},
                {"dc:creator": "Carpanez T.G.",
                 "dc:title": "Potential for nutrients reuse, carbon sequestration, and CO<inf>2</inf> emissions reduction in the practice of domestic and industrial wastewater recycling into agricultural soils: A review",
                 "prism:doi": "10.1016/j.jenvman.2024.122443",
                 "prism:coverDate": "2024-11-01",
                 "affiliation": [{"affiliation-country": "Brazil"}]}
            ]
        }
    }
    mocker.patch("project.requests.get", return_value = response)

    keywords = "(microplastic* OR microplástico* ) AND (soil OR land OR terrestr*)"
    api_key = "1a2b3c4d5e6f7g8h9i0j"  # mock key
    countries = ["Brazil"]
    start_year = 2013
    end_year = 2024  # that's a real query

    result = fetch_publication_details(keywords, api_key, countries, start_year, end_year)

    assert len(result) == 2
    assert result[0] == extract_fields(response.json()["search-results"]["entry"][0])
    assert result[1] == extract_fields(response.json()["search-results"]["entry"][1])
