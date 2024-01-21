# import modules
import csv
#from nltk.stem import PorterStemmer
from nltk.stem import SnowballStemmer

with open('Study2_wordCounts_cleaned_neg.csv', 'r', encoding='utf-8-sig') as fr, open('Study2_stems_neg.csv', 'w', encoding='utf-8-sig', newline='') as fw:
    reader = csv.reader(fr)
    writer = csv.writer(fw)
    #stemmer = PorterStemmer()
    stemmer = SnowballStemmer("english")

    next(fr)

    for row in reader:
        word = row[0]
        stem = stemmer.stem(word)
        writer.writerow([word, stem])