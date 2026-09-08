#!/usr/bin/env python3
"""
IELTS Liz Vocabulary Master Scraper & Dataset Builder
=====================================================
Built for Flutter IELTS Exam Preparation App
Author: Antigravity UI/UX & Flutter Expert

Description:
    Scrapes the IELTS Liz vocabulary directory (https://ieltsliz.com/vocabulary/)
    and extracts structured vocabulary terms, definitions, parts of speech,
    pronunciations, synonyms, and example sentences across all 33 lesson topics.
    Exports the clean dataset into both JSON and CSV formats.
"""

import csv
import json
import os
import re
import sys
from concurrent.futures import ThreadPoolExecutor, as_completed
import requests
from bs4 import BeautifulSoup

BASE_URL = 'https://ieltsliz.com/vocabulary/'
HEADERS = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36'
}

POS_MAP = {
    'n': 'noun',
    'noun': 'noun',
    'pl n': 'plural noun',
    'plural noun': 'plural noun',
    'v': 'verb',
    'vb': 'verb',
    'verb': 'verb',
    'v+ing': 'verb (-ing)',
    'adj': 'adjective',
    'adjective': 'adjective',
    'adv': 'adverb',
    'adverb': 'adverb',
    'phr': 'phrase',
    'phrase': 'phrase',
    'idiom': 'idiom',
    'collocation': 'collocation',
    'prep': 'preposition',
}

BOILERPLATE = [
    'subscribe', 'ielts listening', 'ielts reading', 'ielts writing', 'ielts speaking',
    'click here', 'get my free', 'essay questions', 'band score', 'test information',
    'copyright', 'all rights reserved', 'model answer', 'recommended for you',
    'download pdf', 'privacy policy', 'recent posts', 'top results', 'gt ielts',
    'ielts candidate', 'book a test', 'ieltslizstore', 'comment-reply',
    'useful links', 'all vocabulary', 'click below', 'answer is given', 'answers below',
    'leave a reply', 'disclaimer', 'archives', 'about me', 'all writing task 2 lessons',
    'watch the video', 'ideas for topic', 'education vocabulary', 'useful pages'
]

def clean_text(t: str) -> str:
    if not t:
        return ''
    t = re.sub(r'\s+', ' ', t)
    t = t.replace('\xa0', ' ').replace('”', '"').replace('“', '"').replace('’', "'").strip()
    return t

def is_noise(t: str) -> bool:
    lower = t.lower().strip()
    if len(lower) < 2:
        return True
    if any(b in lower for b in BOILERPLATE):
        return True
    if lower in [
        'vocabulary for ielts', 'vocabulary for ielts lessons', 'all ielts vocabulary lessons',
        'more vocabulary for ielts', 'useful government vocabulary', 'advertising vocabulary',
        'useful vocabulary and ideas', 'vegetable vocabulary lesson', 'vocabulary for topics',
        'education vocabulary'
    ]:
        return True
    if lower.startswith('vocabulary for') or lower.startswith('all vocabulary'):
        return True
    if lower.startswith('(pron') or lower.startswith('pron =') or lower.startswith('pron –') or lower.startswith('pron -'):
        return True
    if lower.startswith('q)') or lower.startswith('q:') or lower.startswith('a)') or lower.startswith('a:'):
        return True
    if lower.startswith('do you') or lower.startswith('are you') or lower.startswith('why do') or lower.startswith('is it'):
        return True
    if lower.startswith('i think') or lower.startswith('i suppose') or lower.startswith('for me,') or lower.startswith('in my opinion'):
        return True
    if '…………' in t or '.....' in t or '_____ ' in t:
        return True
    return False

def is_example_sentence(t: str) -> bool:
    words = t.split()
    if len(words) >= 5 and (t.endswith('.') or t.endswith('!') or t.endswith('?')):
        if (t[0].isupper() or t.startswith('"') or t.startswith("'")) and ' = ' not in t and ' - ' not in t:
            return True
    return False

def scrape_topic_directory():
    """Scrapes the main vocabulary portal to extract categories and lesson topics."""
    print(f"Fetching topic directory from {BASE_URL}...")
    resp = requests.get(BASE_URL, headers=HEADERS, timeout=15)
    resp.raise_for_status()
    soup = BeautifulSoup(resp.text, 'html.parser')
    content = soup.find('div', class_='entry-content')
    
    current_category = 'Detailed Lists for Word Power'
    topics = []
    
    for elem in content.descendants:
        if elem.name in ['h1', 'h2', 'h3', 'h4']:
            txt = clean_text(elem.get_text())
            if txt and any(k in txt.lower() for k in [
                'detailed', 'short', 'noun', 'idiom', 'individual', 'writing', 'paraphras'
            ]):
                current_category = txt.replace('Vocabulary for IELTS Topics', 'Topic Vocabulary').strip()
        elif elem.name == 'a':
            href = elem.get('href', '')
            text = clean_text(elem.get_text())
            if href and 'ieltsliz.com' in href and not href.endswith('/vocabulary/') and not href.endswith('#'):
                topics.append({
                    'category': current_category,
                    'topic': text,
                    'url': href
                })
                
    dedup_topics = []
    seen = set()
    for t in topics:
        if t['url'] not in seen:
            seen.add(t['url'])
            dedup_topics.append(t)
            
    print(f"Found {len(dedup_topics)} topics on main directory.")
    return dedup_topics

def parse_lesson_content(topic_info):
    """Scrapes and structures vocabulary from an individual lesson page."""
    url = topic_info['url']
    topic = topic_info['topic']
    category = topic_info['category']
    
    items = []
    pending_examples = []
    
    try:
        r = requests.get(url, headers=HEADERS, timeout=15)
        if r.status_code != 200:
            return topic_info, items
            
        soup = BeautifulSoup(r.text, 'html.parser')
        entry = soup.find('div', class_='entry-content')
        if not entry:
            return topic_info, items
            
        current_subtopic = topic
        
        # Traverse DOM elements
        for el in entry.find_all(['h2', 'h3', 'h4', 'ul', 'ol', 'table', 'p', 'div']):
            if el.name in ['h2', 'h3', 'h4']:
                htext = clean_text(el.get_text())
                if htext and not is_noise(htext):
                    current_subtopic = htext
            elif el.name in ['ul', 'ol']:
                # ONLY process top-level lists to avoid duplicate processing of nested child lis
                if el.find_parent(['ul', 'ol']):
                    continue
                if any(c in el.get('class', []) for c in ['menu', 'widget', 'sub-menu']):
                    continue
                for li in el.find_all('li', recursive=False):
                    sub_lists = li.find_all(['ul', 'ol'])
                    if sub_lists:
                        li_copy = BeautifulSoup(str(li), 'html.parser').find('li')
                        for sub in li_copy.find_all(['ul', 'ol']):
                            sub.decompose()
                        parent_text = clean_text(li_copy.get_text(' ', strip=True))
                        parent_text = re.sub(r'^(\d+[\.\)]|\-|\*|•)\s*', '', parent_text).strip()
                        
                        if is_noise(parent_text):
                            continue
                            
                        defs = []
                        exs = []
                        pron = ''
                        
                        for sub in sub_lists:
                            for sub_li in sub.find_all('li'):
                                st = clean_text(sub_li.get_text(' ', strip=True))
                                if not st or is_noise(st):
                                    continue
                                if st.lower().startswith('(pron') or st.lower().startswith('pron =') or st.lower().startswith('pron –') or 'pronunciation' in st.lower():
                                    pron = re.sub(r'^\(?pron\s*[-=]?\s*', '', st, flags=re.IGNORECASE).rstrip(')')
                                elif (st.startswith('"') or st.startswith("'") or 'for example:' in st.lower()) and len(st.split()) > 5:
                                    exs.append(st)
                                else:
                                    defs.append(st)
                                    
                        parsed = parse_raw_item(parent_text, current_subtopic, topic, category, url)
                        if parsed:
                            if defs:
                                parsed['definition'] = ' | '.join(defs)
                            if exs:
                                parsed['example'] = ' '.join(exs)
                            if pron:
                                parsed['pronunciation'] = pron
                            items.append(parsed)
                        continue

                    # Single li item
                    raw = clean_text(li.get_text(' ', strip=True))
                    raw = re.sub(r'^(\d+[\.\)]|\-|\*|•)\s*', '', raw).strip()
                    if is_noise(raw):
                        continue
                    if is_example_sentence(raw):
                        pending_examples.append(raw)
                        continue
                    
                    parsed = parse_raw_item(raw, current_subtopic, topic, category, url)
                    if parsed:
                        items.append(parsed)
                        
            elif el.name == 'table':
                for tr in el.find_all('tr'):
                    cells = [clean_text(td.get_text()) for td in tr.find_all(['td', 'th'])]
                    if len(cells) >= 2 and cells[0] and cells[1] and not is_noise(cells[0]):
                        raw = f"{cells[0]} = {cells[1]}"
                        parsed = parse_raw_item(raw, current_subtopic, topic, category, url)
                        if parsed:
                            items.append(parsed)
                            
            elif el.name in ['p', 'div']:
                txt = clean_text(el.get_text())
                txt = re.sub(r'^(\d+[\.\)]|\-|\*|•)\s*', '', txt).strip()
                if is_noise(txt):
                    continue
                if (' = ' in txt or ' – ' in txt) and len(txt.split()) < 25:
                    parsed = parse_raw_item(txt, current_subtopic, topic, category, url)
                    if parsed:
                        items.append(parsed)
                elif is_example_sentence(txt):
                    pending_examples.append(txt)

        # Distribute pending examples to relevant items
        for ex in pending_examples:
            matched = False
            for item in items:
                term_word = item['term'].split()[0].lower().strip('()[]')
                if len(term_word) >= 4 and term_word in ex.lower():
                    if not item['example']:
                        item['example'] = ex
                        matched = True
                        break
            if not matched and items and not items[0]['example']:
                items[0]['example'] = ex

    except Exception as e:
        print(f"Error fetching {url}: {e}")
        
    return topic_info, items

def parse_raw_item(text: str, subtopic: str, topic: str, category: str, url: str):
    """Parses a single vocabulary string into normalized dictionary."""
    term = ''
    pos = ''
    definition = ''
    synonyms = ''
    example = ''
    pronunciation = ''
    
    lower = text.lower()
    if lower.startswith('synonyms =') or lower.startswith('synonyms:'):
        syns = re.split(r'[:=]\s*', text, 1)[1].strip()
        head_term = topic.split(':')[0].strip()
        return {
            'term': head_term,
            'part_of_speech': 'synonyms',
            'definition': f"Synonyms: {syns}",
            'pronunciation': '',
            'synonyms': syns,
            'example': '',
            'subtopic': subtopic,
            'topic': topic,
            'category': category,
            'source_url': url
        }
    if lower.startswith('antonyms =') or lower.startswith('antonyms:'):
        ants = re.split(r'[:=]\s*', text, 1)[1].strip()
        head_term = topic.split(':')[0].strip()
        return {
            'term': head_term,
            'part_of_speech': 'antonyms',
            'definition': f"Antonyms: {ants}",
            'pronunciation': '',
            'synonyms': '',
            'example': '',
            'subtopic': subtopic,
            'topic': topic,
            'category': category,
            'source_url': url
        }

    # Pattern: term = definition
    if ' = ' in text or ' =' in text or '= ' in text:
        parts = re.split(r'\s*=\s*', text, maxsplit=1)
        term_part = parts[0].strip()
        def_part = parts[1].strip() if len(parts) > 1 else ''
        
        m = re.search(r'\((adj|adv|n|vb|v|v\+ing|pl n|phrase|collocation|idiom)\)', term_part, re.IGNORECASE)
        if m:
            pos = POS_MAP.get(m.group(1).lower(), m.group(1).lower())
            term_part = re.sub(r'\s*\((adj|adv|n|vb|v|v\+ing|pl n|phrase|collocation|idiom)\)', '', term_part, flags=re.IGNORECASE).strip()
            
        term = term_part
        definition = def_part

    # Pattern: term (pos) e.g. "detrimentally (adv)", "government (n)"
    elif re.match(r'^([A-Za-z\s\-\/\']+)\s*\((adj|adv|n|vb|v|v\+ing|pl n)\)$', text, re.IGNORECASE):
        m = re.match(r'^([A-Za-z\s\-\/\']+)\s*\((adj|adv|n|vb|v|v\+ing|pl n)\)$', text, re.IGNORECASE)
        term = m.group(1).strip()
        pos = POS_MAP.get(m.group(2).lower(), m.group(2).lower())
        definition = ''

    # Pattern: term (definition / notes)
    elif re.match(r'^([A-Za-z\s\-\/\'\’]+)\s*\(([^)]+)\)$', text):
        m = re.match(r'^([A-Za-z\s\-\/\'\’]+)\s*\(([^)]+)\)$', text)
        t = m.group(1).strip()
        inside = m.group(2).strip()
        if inside.lower() in POS_MAP:
            term = t
            pos = POS_MAP[inside.lower()]
        elif inside.lower() == 'both':
            term = t
            pos = 'countable & uncountable noun'
            definition = 'Used as both countable and uncountable'
        elif 'pron' in inside.lower():
            term = t
            pronunciation = re.sub(r'^\(?pron\s*[-=]?\s*', '', inside, flags=re.IGNORECASE).rstrip(')')
        else:
            term = t
            definition = inside

    # Pattern: term - definition or term : definition
    elif (' - ' in text or ' – ' in text or ': ' in text) and len(text.split()) <= 15:
        delim = ' - ' if ' - ' in text else (' – ' if ' – ' in text else ': ')
        parts = text.split(delim, 1)
        if len(parts[0].split()) <= 5:
            term = parts[0].strip()
            definition = parts[1].strip()
        else:
            term = text
    else:
        if len(text.split()) <= 8:
            term = text
        else:
            return None

    # Handle special pronunciation pattern: "(there are two different pronunciation...)"
    m_pron_alt = re.search(r'\((there are two different pronunciation[^\)]*)\)', term, re.IGNORECASE)
    if m_pron_alt:
        pronunciation = m_pron_alt.group(1).strip()
        term = re.sub(r'\s*\((there are two different pronunciation[^\)]*)\)', '', term, flags=re.IGNORECASE).strip()

    # Clean POS from term if still present
    m_pos = re.search(r'\((adj|adv|n|vb|v|v\+ing|pl n)\)', term, re.IGNORECASE)
    if m_pos:
        if not pos:
            pos = POS_MAP.get(m_pos.group(1).lower(), m_pos.group(1).lower())
        term = re.sub(r'\s*\((adj|adv|n|vb|v|v\+ing|pl n)\)', '', term, flags=re.IGNORECASE).strip()

    # Clean up term string
    term = term.strip().strip('-:;,= ')
    if not term or len(term) < 2 or is_noise(term):
        return None

    # Clean term of trailing pronunciation
    m_pron = re.search(r'\(pron\s*[-=]?\s*([^)]+)\)', term, re.IGNORECASE)
    if m_pron:
        pronunciation = m_pron.group(1).strip()
        term = re.sub(r'\(pron\s*[-=]?\s*[^)]+\)', '', term, flags=re.IGNORECASE).strip()

    # Infer part of speech if empty
    if not pos:
        if term.lower().startswith('to ') and len(term.split()) <= 5:
            pos = 'verb / phrasal verb'
        elif 'uncountable' in subtopic.lower() or 'uncountable' in topic.lower():
            pos = 'uncountable noun'
        elif 'idiom' in subtopic.lower() or 'idiom' in topic.lower():
            pos = 'idiom'
        elif len(term.split()) >= 3:
            pos = 'collocation / phrase'
        else:
            pos = 'noun'

    return {
        'term': term,
        'part_of_speech': pos,
        'definition': definition,
        'pronunciation': pronunciation,
        'synonyms': synonyms,
        'example': example,
        'subtopic': subtopic,
        'topic': topic,
        'category': category,
        'source_url': url
    }

def main():
    print("==================================================")
    print("       IELTS Liz Vocabulary Master Scraper        ")
    print("==================================================")
    
    topics = scrape_topic_directory()
    
    all_items = []
    topic_reports = []
    
    print(f"\nScraping {len(topics)} topic pages concurrently...")
    with ThreadPoolExecutor(max_workers=8) as executor:
        futures = {executor.submit(parse_lesson_content, t): t for t in topics}
        for f in as_completed(futures):
            t_info, items = f.result()
            count = len(items)
            topic_reports.append({
                'category': t_info['category'],
                'topic': t_info['topic'],
                'url': t_info['url'],
                'item_count': count
            })
            all_items.extend(items)
            print(f"  [✓] {t_info['topic']} ({count} items)")
            
    # Sort topic summaries
    topic_reports.sort(key=lambda x: (x['category'], x['topic']))
    
    # Deduplicate vocabulary while retaining best definitions, pronunciations, and examples
    dedup = {}
    for item in all_items:
        key = (item['term'].lower(), item['topic'].lower())
        if key not in dedup:
            dedup[key] = item
        else:
            existing = dedup[key]
            if not existing.get('definition') and item.get('definition'):
                existing['definition'] = item['definition']
            if not existing.get('example') and item.get('example'):
                existing['example'] = item['example']
            if not existing.get('part_of_speech') and item.get('part_of_speech'):
                existing['part_of_speech'] = item['part_of_speech']
            if not existing.get('pronunciation') and item.get('pronunciation'):
                existing['pronunciation'] = item['pronunciation']
            if not existing.get('synonyms') and item.get('synonyms'):
                existing['synonyms'] = item['synonyms']

    final_list = list(dedup.values())
    final_list.sort(key=lambda x: (x['category'], x['topic'], x['term'].lower()))
    
    for idx, item in enumerate(final_list, 1):
        item['id'] = f"IELTS-VOCAB-{idx:04d}"

    print("\n==================================================")
    print(f"Scrape Complete!")
    print(f"Total Unique Vocabulary Items: {len(final_list)}")
    print(f"Total Categories & Topics: {len(topic_reports)}")
    print("==================================================")
    
    # 1. Output JSON files
    with open('ielts_vocabulary.json', 'w', encoding='utf-8') as f:
        json.dump(final_list, f, indent=2, ensure_ascii=False)
    print("Saved: ielts_vocabulary.json")
    
    with open('ielts_vocabulary_topics.json', 'w', encoding='utf-8') as f:
        json.dump(topic_reports, f, indent=2, ensure_ascii=False)
    print("Saved: ielts_vocabulary_topics.json")

    # 2. Output CSV files
    fields = ['id', 'term', 'part_of_speech', 'definition', 'pronunciation', 'synonyms', 'example', 'topic', 'subtopic', 'category', 'source_url']
    with open('ielts_vocabulary.csv', 'w', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=fields)
        writer.writeheader()
        for item in final_list:
            writer.writerow({k: item.get(k, '') for k in fields})
    print("Saved: ielts_vocabulary.csv")

    topic_fields = ['category', 'topic', 'url', 'item_count']
    with open('ielts_vocabulary_topics.csv', 'w', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=topic_fields)
        writer.writeheader()
        for tr in topic_reports:
            writer.writerow(tr)
    print("Saved: ielts_vocabulary_topics.csv")

if __name__ == '__main__':
    main()
