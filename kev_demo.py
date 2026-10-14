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
        "state": "just had lunch",
        "model": "kev-latest",

        "questions": {
            "tool": {
                "type": "choice",
                "instructions": "Which tool call should handle this request?",
                "criteria": {
                    "food_log": "Tracks macros for food eaten throughout the day.",
                    "gas_log": "Tracks gasoline consumption and expenditure",
                    "finance_log": "Tracks spending",
                    "web_search": "Miscellaneous web queries for information retrieval not available elsewhere",
                    "filesystem": "Requests for specific files stored locally on the user's computer",
                }
            }
        }

        # "questions": {
        #     "department":  {"type": "choice", "instructions": "Which team should handle this?",
        #                     "criteria": {"returns": "Exchanges, refunds, wrong or damaged items",
        #                                  "shipping": "Delivery status, delays, lost packages",
        #                                  "billing": "Charges, invoices, payment problems"}},
        #     "escalate":    {"type": "noul",  "instructions": "Does this need urgent human attention?"},
        #     "frustration": {"type": "score", "instructions": "How frustrated is the customer?",
        #                     "criteria": ["Calm", "Frustrated", "Very angry"]}
        # }
    }
    response = requests.post(
        url,
        json=data,
    )
    return response.json()


response = choose()
print(response)
