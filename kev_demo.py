# /// script
# requires-python = ">=3.10"
# dependencies = [
#     "requests",
# ]
# ///

import requests

HOST = "http://localhost:8009"

def choose():
    url = f"{HOST}/v1/systemone"
    data = {
        "state": "Shoes arrived two weeks late and in the wrong size. Also I see two charges on my card.",
        "model": "kev-latest",
        "questions": {
            "department":  {"type": "choice", "instructions": "Which team should handle this?",
                            "criteria": {"returns": "Exchanges, refunds, wrong or damaged items",
                                         "shipping": "Delivery status, delays, lost packages",
                                         "billing": "Charges, invoices, payment problems"}},
            "escalate":    {"type": "noul",  "instructions": "Does this need urgent human attention?"},
            "frustration": {"type": "score", "instructions": "How frustrated is the customer?",
                            "criteria": ["Calm", "Frustrated", "Very angry"]}
        }
    }
    response = requests.post(
        url,
        json=data,
    )
    return response.json()


response = choose()
print(response)
