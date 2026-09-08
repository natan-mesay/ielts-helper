import json

with open('assets/data/ielts_vocabulary.json', 'r') as f:
    data = json.load(f)

# Collect all terms that need authentic sentences
generic_terms = [d for d in data if 'In formal IELTS essays, understanding the role of' in d.get('example', '')]

topics = {}
for g in generic_terms:
    top = g.get('topic', 'Other')
    if top not in topics:
        topics[top] = []
    topics[top].append(g)

print(f"Generic terms to replace: {len(generic_terms)} across {len(topics)} topics")
