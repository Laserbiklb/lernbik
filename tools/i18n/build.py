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
