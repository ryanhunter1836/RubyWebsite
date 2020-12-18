import csv
import requests
import argparse
from bs4 import BeautifulSoup

def decode(input):
    #Split the string on each value
    nodes = input.split('</option>')
    finalList = []
    for node in nodes:
        try:
            index = node.index('>')
            #Parse the name from the string
            finalList.append(node[(node.index('>') + 1):len(node)])
        except:
            #do nothing
            pass

    #Remove the first node
    del finalList[0]
    return finalList

def parse(input, year, make, model):
    #Create an html document
    doc = BeautifulSoup(input, 'lxml')
    sizes = doc.article.find_all('tr')
    #Index 1 is driver, 2 is passenger
    try:
        driver = sizes[1].find_all('td')[1].text
        passenger = sizes[2].find_all('td')[1].text
        save(year, make, model, driver, passenger)
        print(make + " " + model + " " + str(year))
    except:
         #Make a seperate file of the exceptions
        saveException(make, model, year)
        print(make + " " + model + " " + str(year))

def save(year, make, model, driver, passenger):
    csvRow = [make, model, year, str(driver), str(passenger)]
    with open('wipersizes.csv', 'a', newline='') as csvfile:
        filewriter = csv.writer(csvfile, delimiter=',', quotechar='|', quoting=csv.QUOTE_MINIMAL)
        filewriter.writerow(csvRow)

def saveException(make, model, year):
    csvRow = [make, model, year]
    with open('exceptions.csv', 'a', newline='') as csvfile:
        filewriter = csv.writer(csvfile, delimiter=',', quotechar='|', quoting=csv.QUOTE_MINIMAL)
        filewriter.writerow(csvRow)

URL = "https://www.rainx.com/wp-admin/admin-ajax.php"
HEADERS = {
    "Accept": "*/*",
    "Accept-Encoding": "gzip, deflate, br",
    "Accept-Language": "en-US,en;q=0.9",
    "Connection": "keep-alive",
    "Content-Length": "41",
    "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8",
    "DNT": "1",
    "Host": "www.rainx.com",
    "Origin": "https://www.rainx.com",
    "Referer": "https://www.rainx.com/blade-size-finder/",
    "User-agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/72.0.3626.121 Safari/537.36",
    "X-Requested-With": "XMLHttpRequest"
}

HEADERS2 = {
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8",
    "Accept-Encoding": "gzip, deflate, br",
    "Accept-Language": "en-US,en;q=0.9",
    "Cache-Control": "max-age=0",
    "Connection": "keep-alive",
    "Content-Length": "48",
    "Content-Type": "application/x-www-form-urlencoded",
    "DNT": "1",
    "Host": "www.rainx.com",
    "Origin": "https://www.rainx.com",
    "Referer": "https://www.rainx.com/blade-size-finder/",
    "Upgrade-Insecure-Requests": "1",
    "User-agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/72.0.3626.121 Safari/537.36",
}

parser = argparse.ArgumentParser(description='Script to scrape wiper sizes')
parser.add_argument('start', type=int, help='Year to start scraping from (inclusive)')
parser.add_argument('end', type=int, help='Year to end scraping (inclusive)')
args = parser.parse_args()

#Iterate through all the years
for year in range(args.start, args.end):
    DATA = { "action" : "bf_ajax_hook", "type" : "make", "c_year" : str(year) }
    r = requests.post(URL, data=DATA, headers=HEADERS)
    makes = decode(str(r.content))
    #Iterate through all the makes for the current year
    for make in makes:
        DATA = { "action" : "bf_ajax_hook", "type" : "model", "c_year" : str(year), "c_make" : str(make) }
        r = requests.post(URL, data=DATA, headers=HEADERS, timeout=30)
        models = decode(str(r.content))
        #Iterate through all the models for the current make and year
        for model in models:
            DATA = "bf-year=" + str(year) + "&bf-make=" + str(make) + "&bf-model=" + str(model)
            r = requests.post("https://www.rainx.com/blade-size-finder/", data=DATA, headers=HEADERS2)
            #Parse and save the sizes
            parse(str(r.content), year, make, model)