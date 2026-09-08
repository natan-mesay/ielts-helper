import json, re

with open('assets/data/ielts_vocabulary.json', 'r') as f:
    data = json.load(f)

# Collect all generic items and clean them
generic_items = [d for d in data if 'In formal IELTS essays, understanding the role of' in d.get('example', '')]
print(f"Total generic items: {len(generic_items)}")

# Let's inspect terms by topic
topics = set(d.get('topic') for d in generic_items)
print(f"Unique topics: {len(topics)}")
