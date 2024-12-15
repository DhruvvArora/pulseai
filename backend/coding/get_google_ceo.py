# filename: get_google_ceo.py
import requests

def get_google_ceo():
    url = "https://en.wikipedia.org/wiki/Google"
    response = requests.get(url)
    return response.text

page_content = get_google_ceo()

with open("google_page.html", "w", encoding="utf-8") as file:
    file.write(page_content)

print("The content has been saved to google_page.html")