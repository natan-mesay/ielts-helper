import json

with open('assets/data/ielts_vocabulary.json', 'r') as f:
    data = json.load(f)

generic = [d for d in data if 'In formal IELTS essays, understanding the role of' in d.get('example', '')]

by_topic = {}
for g in generic:
    top = g.get('topic', 'Other')
    if top not in by_topic:
        by_topic[top] = []
    by_topic[top].append((g['id'], g['term'], g.get('part_of_speech', ''), g.get('definition', '')))

with open('scratch/generic_by_topic.json', 'w') as out:
    json.dump(by_topic, out, indent=2)

print(f"Extracted {len(generic)} terms across {len(by_topic)} topics to scratch/generic_by_topic.json")
