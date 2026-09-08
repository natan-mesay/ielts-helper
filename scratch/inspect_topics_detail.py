import json

with open('scratch/generic_by_topic.json', 'r') as f:
    data = json.load(f)

for top in sorted(data.keys()):
    terms = [t[1] for t in data[top]]
    print(f"'{top}': {len(terms)} words")
