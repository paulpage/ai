# /// script
# requires-python = ">=3.10"
# dependencies = [
#     "requests",
# ]
# ///

import requests

url = "http://localhost:8080"

def token_count(s: str):
    body = {
        "content": s,
    }
    response = requests.post(f"{url}/tokenize", json=body)
    data = response.json()
    token_count = len(data["tokens"])
    return token_count


f = "token_request.py"
with open(f, "r") as f:
    data = f.read()

print(f"Token count: {token_count(data)}")
