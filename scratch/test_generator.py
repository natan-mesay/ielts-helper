import json, re

# Load dataset
with open('assets/data/ielts_vocabulary.json', 'r') as f:
    data = json.load(f)

# Junk terms to remove
junk_terms = {
    'home page', 'band 6', 'band 7', '30%', '70%', '8 billion',
    'speaking part 3 questions', 'what urban planning means',
    'adjectives', 'age', 'a lot of', 'are', 'abstract ideas',
    'nouns', 'countable', 'uncountable', 'all speaking lessons',
    'describe a piece', 'model map', 'map listening practice',
    'article "the"', 'a lot of much many'
}

def clean_term_for_cloze(term):
    # Remove parentheses if they exist e.g. (tree) trunk -> tree trunk
    cleaned = re.sub(r'\(.*?\)', '', term).strip()
    # Normalize multiple spaces
    cleaned = re.sub(r'\s+', ' ', cleaned)
    return cleaned if cleaned else term

print("Test generator script ready.")
