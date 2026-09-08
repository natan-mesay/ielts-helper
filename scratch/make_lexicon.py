import json, re

# Load dataset
with open('assets/data/ielts_vocabulary.json', 'r') as f:
    data = json.load(f)

print(f"Total entries loaded: {len(data)}")
