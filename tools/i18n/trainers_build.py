# Builds assets/learn/trainers_de.json and trainers_en.json from trainers.json (Russian):
# every Russian string is replaced by its translation (trainers_small.TR / trainers_big.BIG).
# In German, prompts that would give away the German answer are replaced (DE_CUE) or emptied.
import json, os, re, sys
sys.path.insert(0, os.path.dirname(__file__))
from trainers_small import TR
from trainers_big import BIG

A = os.path.join(os.path.dirname(__file__), '..', '..', 'assets', 'learn')
t = json.load(open(os.path.join(A, 'trainers.json')))
cyr = re.compile('[а-яё]', re.I)
BIGK = ('CEXP', 'SHEET', 'AJT', 'ORDW', 'VDESC')

SRC, seen = [], set()
def collect(v):
    if isinstance(v, str):
        if cyr.search(v) and v not in seen:
            seen.add(v); SRC.append(v)
    elif isinstance(v, list):
        for x in v: collect(x)
    elif isinstance(v, dict):
        for x in v.values(): collect(x)
for k, v in t.items():
    if k not in BIGK: collect(v)
assert len(SRC) == len(TR), (len(SRC), len(TR))

DE_CUE = {
 31:'der Park — wo?',32:'der Park — wohin?',33:'das Kino — wohin?',34:'das Kino — wo?',35:'der Arzt — wohin?',36:'der Arzt — wo?',
 37:'die Arbeit — wohin?',38:'die Arbeit — wo?',39:'die Arbeit — woher?',40:'Haus — wohin? (feste Wendung)',42:'Haus — wo? (feste Wendung)',
 44:'der Bus — womit?',45:'der Zug — womit?',46:'das Wochenende — wann?',48:'der Montag — wann?',50:'der Sommer — wann?',52:'die Stadt — wo?',
 53:'die Stadt — wohin?',55:'der Markt — wo?',56:'der Markt — wohin?',57:'der Bahnhof — woher?',58:'der Bahnhof — wohin?',59:'die Schule — wohin?',
 60:'die Schule — wo?',61:'das Bett — wohin?',62:'das Bett — wo?',63:'das Haus — woher? (heraus)',64:'ich — mit wem?',65:'du — für wen?',
 66:'ich — ohne wen?',67:'ich — wo? (bei …)',68:'ich — wohin? (zu …)',69:'das Meer — wohin?',70:'das Meer — wo?',71:'ein Jahr — seit wann?',
 72:'der Kurs — wann? (danach)',73:'der Supermarkt — wo?',74:'die Post — wohin?',75:'die Haltestelle — wo?',76:'das Fahrrad — womit?',
 77:'der Bahnhof — wo?',78:'das Büro — wo?',79:'der September — wann?',81:'der Samstag — wann?',83:'der Geburtstag — Anlass',
 84:'die Hochzeit — wohin? (Feier)',85:'der Urlaub — träumen …',86:'acht Uhr — genau wann?',88:'acht Uhr — ab wann?',90:'die Kinder — mit wem?',
 264:'acht Uhr — Beginn',266:'neun Uhr — genau',268:'8 Uhr — Beginn der Öffnungszeit',271:'der Juni — wann?',273:'der Urlaub — träumen …',
 245:'der Sohn',246:'die Mama',247:'das Kind',248:'die Eltern',249:'der Bruder',250:'die Freundin',
 251:'der Teddybär',253:'die Tasche',254:'das Buch',255:'der Kuchen',256:'die Uhr',257:'das Fahrrad',258:'der Schal',
 259:'du',260:'ihr (Freunde)',261:'Sie (höflich)',262:'er',263:'sie (eine Frau)',
 202:'Sag: Über Politik sprichst du nicht gern.',215:'Frag höflich einen Fremden nach dem Bahnhof.',
 274:'Lade mehrere Freunde ein (kommen).',276:'Frag deine Freunde, ob sie kommen können.',278:'Frag höflich, ob du die Wohnung sehen darfst.',
 280:'Frag, ob morgen 14 Uhr passt.',282:'Du bist Dmytro und meldest dich am Telefon.',284:'Verabschiede dich am Telefon.',
 135:'sich ärgern',140:'sich bewerben',145:'denken',150:'sich informieren',154:'sich interessieren',159:'sprechen (Thema)',161:'warten',
 168:'sich freuen (es kommt noch)',171:'sich freuen (schon da)',176:'teilnehmen',177:'telefonieren',182:'sprechen (mit einer Person)',187:'träumen',190:'sich treffen',
 286:'Gratuliere einem Freund zum Geburtstag.',288:'Beginne einen Brief an Marie.',291:'Lade Freunde für Samstag ab acht zu dir ein.',
}
# German sentences that are the answer itself: no prompt in German.
for i in list(range(199, 223)) + [226, 228, 230, 233, 235, 237, 240, 242, 243, 244] + list(range(294, 304)) + [304, 306, 308, 310, 312, 314]:
    DE_CUE.setdefault(i, '')

def build(li):
    m = {s: (DE_CUE[i] if li == 0 and i in DE_CUE else TR[i][li]) for i, s in enumerate(SRC)}
    def sub(v):
        if isinstance(v, str): return m.get(v, v)
        if isinstance(v, list): return [sub(x) for x in v]
        if isinstance(v, dict): return {k: sub(x) for k, x in v.items()}
        return v
    out = {}
    for k, v in t.items():
        if k in BIG:
            out[k] = {kk: (BIG[k][kk][li] if kk in BIG[k] else (m.get(vv, vv) if isinstance(vv, str) else vv)) for kk, vv in v.items()}
        elif k == 'AJT':
            out[k] = {kk: vv.replace('мн.', 'Pl.' if li == 0 else 'pl.') for kk, vv in v.items()}
        else:
            out[k] = sub(v)
    left = []
    def chk(v, p):
        if isinstance(v, str):
            if cyr.search(v): left.append(p)
        elif isinstance(v, list):
            for i, x in enumerate(v): chk(x, f'{p}[{i}]')
        elif isinstance(v, dict):
            for kk, x in v.items(): chk(x, f'{p}.{kk}')
    chk(out, '')
    return out, left

for li, lang in enumerate(('de', 'en')):
    out, left = build(li)
    json.dump(out, open(os.path.join(A, f'trainers_{lang}.json'), 'w'), ensure_ascii=False, separators=(',', ':'))
    print(lang, 'left Russian:', left)
