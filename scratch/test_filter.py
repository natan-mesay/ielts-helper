import json, re

with open('assets/data/ielts_vocabulary.json', 'r') as f:
    data = json.load(f)

junk_terms = {
    'home page', 'band 6', 'band 7', '30%', '70%', '8 billion',
    'speaking part 3 questions', 'what urban planning means',
    'adjectives', 'age', 'a lot of', 'are', 'abstract ideas',
    'nouns', 'countable', 'uncountable', 'all speaking lessons',
    'describe a piece', 'model map', 'map listening practice',
    'article "the"', 'a lot of much many'
}

clean_items = []
dropped = []
for it in data:
    t = it['term'].strip().lower()
    if t in junk_terms or re.match(r'^\d+(\.\d+)?%?$', t) or re.match(r'^\d+\s+(billion|million)$', t):
        dropped.append(it['term'])
    else:
        clean_items.append(it)

print(f"Total original: {len(data)}")
print(f"Dropped {len(dropped)} non-word entries: {dropped}")
print(f"Remaining high-quality vocabulary items: {len(clean_items)}")
