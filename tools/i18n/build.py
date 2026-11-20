# Merges the rule translations into assets/learn/book.json (t/b per language).
import json, os, sys
sys.path.insert(0, os.path.dirname(__file__))
import rules1, rules2, rules3  # noqa: F401  (they fill rules1.T)
from rules1 import T
p = os.path.join(os.path.dirname(__file__), '..', '..', 'assets', 'learn', 'book.json')
book = json.load(open(p))
missing = []
for lv in book:
    for c in book[lv]:
        for r in c['r']:
            tr = T.get(r['id'])
            if not tr:
                missing.append(r['id']); continue
            for lang in ('de', 'en'):
                r['t'][lang] = tr[lang]['t']
                r['b'][lang] = tr[lang]['b']
            if r['id'] in rules3.RU:
                r['b']['ru'] = rules3.RU[r['id']]
json.dump(book, open(p, 'w'), ensure_ascii=False, separators=(',', ':'))
print('translated', len(T), 'missing', missing)

# English word translations → assets/learn/words_en.json ({"der Tisch": "table", …}).
import glob
en = {}
for f in sorted(glob.glob(os.path.join(os.path.dirname(__file__), 'words', 'en*.tsv'))):
    for line in open(f, encoding='utf-8'):
        line = line.rstrip('\n')
        if line:
            k, v = line.split('\t')
            en[k] = v
wp = os.path.join(os.path.dirname(p), 'words.json')
keys = [(x[0] + ' ' + x[1]).strip() for x in json.load(open(wp))]
print('words en', sum(k in en for k in keys), 'of', len(keys))
json.dump({k: en[k] for k in keys if k in en}, open(os.path.join(os.path.dirname(p), 'words_en.json'), 'w'), ensure_ascii=False, separators=(',', ':'))
