# import modules
import csv
import string
import nltk
from nltk.tokenize import word_tokenize
from nltk.corpus import stopwords
from nltk.stem import WordNetLemmatizer
from nltk.corpus import wordnet
#from nltk.stem import PorterStemmer
from nltk.stem import SnowballStemmer

# initialize algorithms
lemmatizer = WordNetLemmatizer()
#stemmer = PorterStemmer()
stemmer = SnowballStemmer("english")

# define custom functions
def get_wordnet_pos(word):
    tag = nltk.pos_tag([word])[0][1][0].upper()
    tag_dict = {"J": wordnet.ADJ,
                "N": wordnet.NOUN,
                "V": wordnet.VERB,
                "R": wordnet.ADV}
    return tag_dict.get(tag, wordnet.NOUN)


# define stop words
stop_words = stopwords.words('english')
new_stopwords = ["'m", "feel", "feeling", "little", "bit", "less", "more", "slightly", "lot", "abit", "im", "isnt", "itll", "ive", "haha", "jaja",
                 "kinda", "kind", "might", "maybe", "moment", "much", "really", "pretty", "sort", "still", "super", "though", "tho",
                 "also", "actually", "didnt", "dont", "couldnt", "could", "bc", "couldve", "even", "extremely", "extra", "somewhat",
                 "get", "got", "havent", "hmm", "hmmm", "however", "right", "now", "rn", "slight", "wasnt", "wont", "today"]
stop_words.extend(new_stopwords)

# import list(s) of words and create dictionar(ies) with words to count
file = open('Study2_stems_neg.csv', 'r', encoding='utf-8-sig')
negative_emotions = list(csv.reader(file, delimiter=","))
file.close()
negative_emotions = [row[0] for row in negative_emotions]

file = open('Study2_stems_pos.csv', 'r', encoding='utf-8-sig')
positive_emotions = list(csv.reader(file, delimiter=","))
file.close()
positive_emotions = [row[0] for row in positive_emotions]


with open('Study2_PromptData_Cleaned_withInferredValence_20230718.csv', 'r', encoding='utf-8-sig') as fr, open('Study2_PromptData_Cleaned_withInferredValence_withWordCounts_20230718.csv', 'w', encoding='utf-8-sig', newline='') as fw:
    reader = csv.reader(fr)
    writer = csv.writer(fw)

    next(fr)
    header = ['PPID', 'Beep', 'Text', 'Stems', 'Length', 'CountNeg', 'PropNeg', 'CountPos', 'PropPos', 'Count', 'Prop']
    header.extend(negative_emotions)
    header.extend(positive_emotions)
    writer.writerow(header)

    for row in reader:
        PPID = row[0]
        beep = row[4] # Study1 2, Study2 4
        text = row[11] # Study1 16, Study2 11
        text = text.translate(str.maketrans('', '', string.punctuation))
        words = [token for token in word_tokenize(text) if not token.lower() in stop_words]
        length = len(words)
        # lemmatized = ' '.join([lemmatizer.lemmatize(word, get_wordnet_pos(word)) for word in words])
        stemmed = ' '.join([stemmer.stem(word) for word in words])
        negative_emotions_dictionary = dict.fromkeys(negative_emotions, 0)
        positive_emotions_dictionary = dict.fromkeys(positive_emotions, 0)
        for word in words:
            # lemma = lemmatizer.lemmatize(word, get_wordnet_pos(word))
            stem = stemmer.stem(word)
            if stem.lower() in negative_emotions_dictionary:
                negative_emotions_dictionary[stem.lower()] += 1
            elif stem.lower() in positive_emotions_dictionary:
                positive_emotions_dictionary[stem.lower()] += 1
        negative_emotion_counts = list(negative_emotions_dictionary.values())
        positive_emotion_counts = list(positive_emotions_dictionary.values())
        negative_count = sum(negative_emotion_counts)
        positive_count = sum(positive_emotion_counts)
        count = negative_count + positive_count
        if length > 0:
            negative_prop = negative_count/length
            positive_prop = positive_count/length
            prop = count/length
        else:
            negative_prop = 0
            positive_prop = 0
            prop = 0
        to_write = [PPID, beep, text, stemmed, length, negative_count, negative_prop, positive_count, positive_prop, count, prop]
        to_write.extend(negative_emotion_counts)
        to_write.extend(positive_emotion_counts)
        writer.writerow(to_write)