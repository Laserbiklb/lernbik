# German and English for the long Russian texts of trainers.json (explanations, sheets).
# BIG[field][key] = (de, en)
BIG = {}
BIG['ORDW'] = {
'v2': ('Im normalen Satz steht das konjugierte Verb auf <b>Position 2</b>: Steht morgen / vielleicht vorne, folgt das Verb, dann das Subjekt.', 'In a normal sentence the conjugated verb is in <b>second position</b>: if morgen / vielleicht comes first, the verb follows, then the subject.'),
'wq': ('Frage mit Fragewort: <b>Fragewort → Verb → wer</b>.', 'Question with a question word: <b>question word → verb → who</b>.'),
'yn': ('Ja/Nein-Frage: <b>das Verb steht vorne</b>.', 'Yes/no question: <b>the verb comes first</b>.'),
'mod': ('Mit Modalverb: das Modalverb auf Position 2, <b>der Infinitiv am Ende</b>.', 'With a modal verb: the modal in second position, <b>the infinitive at the end</b>.'),
'sub': ('Nach <b>weil / dass</b> geht das konjugierte Verb ans Ende des Satzteils.', 'After <b>weil / dass</b> the conjugated verb goes to the end of the clause.'),
'ind': ('Indirekte Frage: nach dem Fragewort steht <b>das Verb am Ende</b>.', 'Indirect question: after the question word <b>the verb goes to the end</b>.'),
'sep': ('Die trennbare Vorsilbe geht <b>ans Ende</b>: Ich nehme am Kurs teil.', 'The separable prefix goes <b>to the end</b>: Ich nehme am Kurs teil.'),
'pf': ('Perfekt: <b>haben + Partizip II</b>, das Partizip am Ende; sich bleibt.', 'Perfekt: <b>haben + Partizip II</b>, participle at the end; sich stays.'),
}
BIG['VDESC'] = {
'zweck': ('Zwei Arten von „damit“: um … zu — wenn dieselbe Person handelt, damit — geht immer.', 'Two ways to say "so that": um … zu — when the same person acts, damit — always possible.'),
'refl': ('Wann man sich braucht und welche Form: ich → mich, wir → uns.', 'When you need sich and which form: ich → mich, wir → uns.'),
'prep': ('Welche Präposition zum Verb gehört: warten auf, träumen von.', 'Which preposition goes with the verb: warten auf, träumen von.'),
'art': ('Der Artikel nach der Präposition: auf den Bus, mit dem Bus.', 'The article after the preposition: auf den Bus, mit dem Bus.'),
'fu': ('freuen auf — was noch kommt; freuen über — was schon da ist.', 'freuen auf — something ahead; freuen über — something you already have.'),
'q': ('Wie man fragt: Worauf wartest du? Auf wen wartest du?', 'How to ask: Worauf wartest du? Auf wen wartest du?'),
'da': ('Kurze Antwort: Ja, ich denke daran / an ihn.', 'Short answer: Ja, ich denke daran / an ihn.'),
'ord': ('Satz bauen: Verb auf Position 2, nach weil am Ende.', 'Build the sentence: verb in position 2, at the end after weil.'),
'sep': ('Ich nehme am Kurs teil · ich habe teilgenommen.', 'Ich nehme am Kurs teil · ich habe teilgenommen.'),
'gift': ('Wem? → Dativ, was? → Akkusativ: meinem Sohn einen Ball.', 'To whom? → Dativ, what? → Akkusativ: meinem Sohn einen Ball.'),
'time': ('am Samstag, im Juni, zum Arzt, um acht / ab acht.', 'am Samstag, im Juni, zum Arzt, um acht / ab acht.'),
'pol': ('Kommt!, Könnte ich …?, Hier spricht …, Auf Wiederhören.', 'Kommt!, Könnte ich …?, Hier spricht …, Auf Wiederhören.'),
}
BIG['TOPV'] = {
'prep': ('Verb + Präposition', 'Verb + preposition'),
'q': ('Fragen: worauf, auf wen', 'Questions: worauf, auf wen'),
'ord': ('Wortstellung', 'Word order'),
'sep': ('Trennbare Verben · Perfekt', 'Separable verbs · Perfekt'),
'gift': ('Geschenke: wem? was?', 'Presents: to whom? what?'),
'pol': ('Einladungen und Bitten', 'Invitations and requests'),
}
BIG['CEXP'] = {
'role': (
'<p>Frag <b>vom Verb aus</b>:</p><div class="msheet"><div class="ms ms-nom"><b>Nominativ</b><span>🙋 Wer tut es?</span><small>Der Mann kauft Brot.</small></div><div class="ms ms-akk"><b>Akkusativ</b><span>🎯 Wen? Was?</span><small>Ich sehe den Mann.</small></div><div class="ms ms-dat"><b>Dativ</b><span>🎁 Wem?</span><small>Ich helfe dem Mann.</small></div></div><p class="muted">Das Subjekt steht immer im Nominativ. Nach den meisten Verben kommt der Akkusativ. Dativ bekommt, wem man etwas gibt, sagt oder hilft.</p>',
'<p>Ask a question <b>from the verb</b>:</p><div class="msheet"><div class="ms ms-nom"><b>Nominativ</b><span>🙋 Who does it?</span><small>Der Mann kauft Brot.</small></div><div class="ms ms-akk"><b>Akkusativ</b><span>🎯 Whom? What?</span><small>Ich sehe den Mann.</small></div><div class="ms ms-dat"><b>Dativ</b><span>🎁 To whom?</span><small>Ich helfe dem Mann.</small></div></div><p class="muted">The subject is always Nominativ. After most verbs comes the Akkusativ. The Dativ is for the person you give, tell or help.</p>'),
'akk': (
'<div class="tw"><table><tr><th>Nom</th><th>Akk</th><th>Nom</th><th>Akk</th></tr><tr><td>der</td><td><b>den</b></td><td>ein</td><td><b>einen</b></td></tr><tr><td>die</td><td>die</td><td>eine</td><td>eine</td></tr><tr><td>das</td><td>das</td><td>ein</td><td>ein</td></tr></table></div><p>Ich kaufe <b>den</b> Tisch. · Ich brauche <b>einen</b> Stuhl.<br>Ich kaufe <b>die</b> Lampe. · Ich nehme <b>das</b> Buch.</p><p class="muted">Nur das Maskulinum ändert sich. Feminin und Neutrum bleiben wie im Wörterbuch.</p>',
'<div class="tw"><table><tr><th>Nom</th><th>Akk</th><th>Nom</th><th>Akk</th></tr><tr><td>der</td><td><b>den</b></td><td>ein</td><td><b>einen</b></td></tr><tr><td>die</td><td>die</td><td>eine</td><td>eine</td></tr><tr><td>das</td><td>das</td><td>ein</td><td>ein</td></tr></table></div><p>Ich kaufe <b>den</b> Tisch. · Ich brauche <b>einen</b> Stuhl.<br>Ich kaufe <b>die</b> Lampe. · Ich nehme <b>das</b> Buch.</p><p class="muted">Only the masculine changes. Feminine and neuter stay as in the dictionary.</p>'),
'dat': (
'<div class="tw"><table><tr><th>Nom</th><th>Dat</th><th>ein-</th></tr><tr><td>der</td><td><b>dem</b></td><td><b>einem</b></td></tr><tr><td>die</td><td><b>der</b></td><td><b>einer</b></td></tr><tr><td>das</td><td><b>dem</b></td><td><b>einem</b></td></tr><tr><td>die (Pl.)</td><td><b>den</b> …-n</td><td></td></tr></table></div><p>Ich helfe <b>dem</b> Mann. · Ich spreche mit <b>der</b> Frau.<br>Ich fahre mit <b>dem</b> Auto. · Ich spiele mit <b>den</b> Kinder<b>n</b>.</p><p class="muted">Tipp: m und n → <b>-m</b>, f → <b>-r</b>.</p>',
'<div class="tw"><table><tr><th>Nom</th><th>Dat</th><th>ein-</th></tr><tr><td>der</td><td><b>dem</b></td><td><b>einem</b></td></tr><tr><td>die</td><td><b>der</b></td><td><b>einer</b></td></tr><tr><td>das</td><td><b>dem</b></td><td><b>einem</b></td></tr><tr><td>die (pl.)</td><td><b>den</b> …-n</td><td></td></tr></table></div><p>Ich helfe <b>dem</b> Mann. · Ich spreche mit <b>der</b> Frau.<br>Ich fahre mit <b>dem</b> Auto. · Ich spiele mit <b>den</b> Kinder<b>n</b>.</p><p class="muted">Tip: m and n → <b>-m</b>, f → <b>-r</b>.</p>'),
'pron': (
'<div class="tw"><table><tr><th>Wer</th><th>Akk: wen?</th><th>Dat: wem?</th></tr><tr><td>ich</td><td>mich</td><td>mir</td></tr><tr><td>du</td><td>dich</td><td>dir</td></tr><tr><td>er</td><td>ihn</td><td>ihm</td></tr><tr><td>sie (Frau)</td><td>sie</td><td>ihr</td></tr><tr><td>wir</td><td>uns</td><td>uns</td></tr><tr><td>ihr</td><td>euch</td><td>euch</td></tr><tr><td>sie / Sie</td><td>sie / Sie</td><td>ihnen / Ihnen</td></tr></table></div><p>Ich sehe <b>dich</b>. (wen?) · Ich helfe <b>dir</b>. (wem?)</p><p class="muted">Die Buchstaben wie bei den Artikeln: de<b>n</b> → ih<b>n</b>, de<b>m</b> → ih<b>m</b>.</p>',
'<div class="tw"><table><tr><th>Who</th><th>Akk: whom?</th><th>Dat: to whom?</th></tr><tr><td>ich</td><td>mich</td><td>mir</td></tr><tr><td>du</td><td>dich</td><td>dir</td></tr><tr><td>er</td><td>ihn</td><td>ihm</td></tr><tr><td>sie (she)</td><td>sie</td><td>ihr</td></tr><tr><td>wir</td><td>uns</td><td>uns</td></tr><tr><td>ihr</td><td>euch</td><td>euch</td></tr><tr><td>sie / Sie</td><td>sie / Sie</td><td>ihnen / Ihnen</td></tr></table></div><p>Ich sehe <b>dich</b>. (whom?) · Ich helfe <b>dir</b>. (to whom?)</p><p class="muted">Same letters as the articles: de<b>n</b> → ih<b>n</b>, de<b>m</b> → ih<b>m</b>.</p>'),
'pakk': (
'<p><b>für · ohne · durch · gegen · um</b> → immer Akkusativ.</p><p>Das ist für <b>den</b> Chef. · Ich gehe ohne <b>dich</b>.<br>Wir sprechen über <b>den</b> Film. · Ich warte auf <b>den</b> Bus.</p><p class="muted">Auch Verben mit Präposition: sprechen über, warten auf, sich freuen auf — Akkusativ.</p>',
'<p><b>für · ohne · durch · gegen · um</b> → always Akkusativ.</p><p>Das ist für <b>den</b> Chef. · Ich gehe ohne <b>dich</b>.<br>Wir sprechen über <b>den</b> Film. · Ich warte auf <b>den</b> Bus.</p><p class="muted">Verbs with a preposition too: sprechen über, warten auf, sich freuen auf — Akkusativ.</p>'),
'pdat': (
'<p><b>aus · bei · mit · nach · seit · von · zu</b> → immer Dativ.</p><p>Ich fahre mit <b>dem</b> Bus. · Ich gehe zu<b>m</b> Arzt.<br>Ich komme von <b>der</b> Arbeit. · Ich wohne bei <b>dir</b>.</p><p class="muted">Merk dir die Reihe: aus-bei-mit-nach-seit-von-zu.</p>',
'<p><b>aus · bei · mit · nach · seit · von · zu</b> → always Dativ.</p><p>Ich fahre mit <b>dem</b> Bus. · Ich gehe zu<b>m</b> Arzt.<br>Ich komme von <b>der</b> Arbeit. · Ich wohne bei <b>dir</b>.</p><p class="muted">Learn them as a chant: aus-bei-mit-nach-seit-von-zu.</p>'),
'wowo': (
'<div class="tw"><table><tr><th>Frage</th><th>Was</th><th>Fall</th><th>Beispiel</th></tr><tr><td>Wo?</td><td>Ort, keine Bewegung</td><td>Dativ</td><td>Ich bin <b>im</b> Park.</td></tr><tr><td>Wohin?</td><td>Bewegung zum Ziel</td><td>Akkusativ</td><td>Ich gehe <b>in den</b> Park.</td></tr></table></div><p class="muted">So funktionieren in, an, auf (und über, unter, vor, hinter, neben, zwischen). sein, liegen, sitzen — wo; gehen, legen, setzen — wohin.</p>',
'<div class="tw"><table><tr><th>Question</th><th>Meaning</th><th>Case</th><th>Example</th></tr><tr><td>Wo? where?</td><td>place, no movement</td><td>Dativ</td><td>Ich bin <b>im</b> Park.</td></tr><tr><td>Wohin? where to?</td><td>movement to a goal</td><td>Akkusativ</td><td>Ich gehe <b>in den</b> Park.</td></tr></table></div><p class="muted">This is how in, an, auf work (and über, unter, vor, hinter, neben, zwischen). Like English "in the park" (where?) vs "into the park" (where to?). sein, liegen, sitzen — where; gehen, legen, setzen — where to.</p>'),
'zus': (
'<div class="tw"><table><tr><th>Verschmelzung</th><th>=</th><th>Beispiel</th></tr><tr><td>im</td><td>in + dem</td><td>im Park</td></tr><tr><td>ins</td><td>in + das</td><td>ins Kino</td></tr><tr><td>am</td><td>an + dem</td><td>am Fenster</td></tr><tr><td>ans</td><td>an + das</td><td>ans Meer</td></tr><tr><td>zum</td><td>zu + dem</td><td>zum Arzt</td></tr><tr><td>zur</td><td>zu + der</td><td>zur Schule</td></tr><tr><td>beim</td><td>bei + dem</td><td>beim Arzt</td></tr><tr><td>vom</td><td>von + dem</td><td>vom Bahnhof</td></tr></table></div><p class="muted">Feminin verschmilzt nicht: in der Küche. Ausnahme — zu + der = zur.</p>',
'<div class="tw"><table><tr><th>Contraction</th><th>=</th><th>Example</th></tr><tr><td>im</td><td>in + dem</td><td>im Park</td></tr><tr><td>ins</td><td>in + das</td><td>ins Kino</td></tr><tr><td>am</td><td>an + dem</td><td>am Fenster</td></tr><tr><td>ans</td><td>an + das</td><td>ans Meer</td></tr><tr><td>zum</td><td>zu + dem</td><td>zum Arzt</td></tr><tr><td>zur</td><td>zu + der</td><td>zur Schule</td></tr><tr><td>beim</td><td>bei + dem</td><td>beim Arzt</td></tr><tr><td>vom</td><td>von + dem</td><td>vom Bahnhof</td></tr></table></div><p class="muted">The feminine does not contract: in der Küche. Exception — zu + der = zur.</p>'),
'chunk': ('<p>Diese Verbindungen lernt man am besten am Stück, wie ein Wort: <b>im Park, zum Arzt, mit dem Bus, nach Hause</b>.</p>', '<p>These phrases are easiest to learn as a whole, like one word: <b>im Park, zum Arzt, mit dem Bus, nach Hause</b>.</p>'),
'mix': ('<p>In jeder Aufgabe: <b>1)</b> welcher Fall — nach Verb, Präposition oder Frage wo/wohin; <b>2)</b> welche Form.</p>', '<p>In every task: <b>1)</b> which case — from the verb, preposition or the question where/where to; <b>2)</b> which form.</p>'),
}
_PREP = [('sich ärgern über','Akk','sich aufregen wegen','to be annoyed about'),('sich bewerben um','Akk','eine Stelle haben wollen','to apply for'),('denken an','Akk','im Kopf haben','to think of'),('sich informieren über','Akk','Infos suchen zu','to find out about'),('sich interessieren für','Akk','Interesse haben an','to be interested in'),('sprechen über','Akk','ein Thema besprechen','to talk about'),('warten auf','Akk','warten, bis etwas kommt','to wait for'),('sich freuen auf','Akk','Freude auf Kommendes','to look forward to'),('sich freuen über','Akk','Freude über Erhaltenes','to be happy about'),('teilnehmen an','Dat','mitmachen bei','to take part in'),('telefonieren mit','Dat','am Telefon sprechen mit','to phone'),('sprechen mit','Dat','reden mit','to talk to'),('träumen von','Dat','sich wünschen','to dream of'),('sich treffen mit','Dat','verabredet sein mit','to meet')]
def _prep(h1, h2, h3, col):
    rows = ''.join(f'<tr><td><b>{a}</b></td><td>{c}</td><td>{x[col]}</td></tr>' for x in _PREP for a, c in [(x[0], x[1])])
    return f'<div class="sheet"><div class="tw"><table><tr><th>{h1}</th><th>{h2}</th><th>{h3}</th></tr>{rows}</table></div></div>'
def _q(h1, h2, h3, note):
    ps = ['auf', 'über', 'an', 'um', 'für', 'von', 'mit']
    wo = {'auf': 'worauf', 'über': 'worüber', 'an': 'woran', 'um': 'worum', 'für': 'wofür', 'von': 'wovon', 'mit': 'womit'}
    rows = ''.join(f'<tr><td>{p}</td><td><b>{wo[p]}</b></td><td>{p.capitalize()} wen / wem?</td></tr>' for p in ps)
    return f'<div class="sheet"><div class="tw"><table><tr><th>{h1}</th><th>{h2}</th><th>{h3}</th></tr>{rows}</table></div><p class="muted">{note}</p></div>'
def _da(h1, h2, h3):
    ps = ['auf', 'über', 'an', 'um', 'für', 'von', 'mit']
    da = {'auf': 'darauf', 'über': 'darüber', 'an': 'daran', 'um': 'darum', 'für': 'dafür', 'von': 'davon', 'mit': 'damit'}
    rows = ''.join(f'<tr><td>{p}</td><td><b>{da[p]}</b></td><td>{p} ihm / ihr / ihn / sie</td></tr>' for p in ps)
    return f'<div class="sheet"><div class="tw"><table><tr><th>{h1}</th><th>{h2}</th><th>{h3}</th></tr>{rows}</table></div></div>'
def _ord(rows):
    ex = ['Morgen treffe ich mich mit Anna.', 'Wann treffen wir uns?', 'Interessierst du dich für Musik?', 'Ich muss mit Kunden telefonieren.', '…, weil ich krank bin.', '…, wo der Bahnhof ist?']
    return '<div class="sheet"><div class="tw"><table>' + ''.join(f'<tr><td>{a}</td><td>{b}</td><td>{e}</td></tr>' for (a, b), e in zip(rows, ex)) + '</table></div></div>'
BIG['SHEET'] = {
'refl': (
'<div class="sheet"><div class="tw"><table><tr><th>Wer</th><th>Form</th></tr><tr><td>ich</td><td>mich</td></tr><tr><td>du</td><td>dich</td></tr><tr><td>er / sie / es</td><td>sich</td></tr><tr><td>wir</td><td>uns</td></tr><tr><td>ihr</td><td>euch</td></tr><tr><td>sie / Sie</td><td>sich</td></tr></table></div><p class="muted">Ob man sich braucht, steht im Wörterbuch: <b>sich</b> interessieren für, aber warten auf — ohne sich.</p></div>',
'<div class="sheet"><div class="tw"><table><tr><th>Who</th><th>Form</th></tr><tr><td>ich</td><td>mich</td></tr><tr><td>du</td><td>dich</td></tr><tr><td>er / sie / es</td><td>sich</td></tr><tr><td>wir</td><td>uns</td></tr><tr><td>ihr</td><td>euch</td></tr><tr><td>sie / Sie</td><td>sich</td></tr></table></div><p class="muted">The dictionary shows whether you need sich: <b>sich</b> interessieren für, but warten auf — no sich.</p></div>'),
'prep': (_prep('Verbindung', 'Fall', 'Bedeutung', 2), _prep('Phrase', 'Case', 'Meaning', 3)),
'art': (
'<div class="sheet"><div class="tw"><table><tr><th></th><th>m</th><th>f</th><th>n</th><th>Pl.</th></tr><tr><td>Akk</td><td>den</td><td>die</td><td>das</td><td>die</td></tr><tr><td>Dat</td><td>dem</td><td>der</td><td>dem</td><td>den …-n</td></tr></table></div><div class="tw"><table><tr><th></th><th>m</th><th>f</th><th>n</th></tr><tr><td>Akk</td><td>einen</td><td>eine</td><td>ein</td></tr><tr><td>Dat</td><td>einem</td><td>einer</td><td>einem</td></tr></table></div><p class="muted">Pronomen: Akk mich, dich, ihn, sie, uns, euch · Dat mir, dir, ihm, ihr, uns, euch.</p></div>',
'<div class="sheet"><div class="tw"><table><tr><th></th><th>m</th><th>f</th><th>n</th><th>pl.</th></tr><tr><td>Akk</td><td>den</td><td>die</td><td>das</td><td>die</td></tr><tr><td>Dat</td><td>dem</td><td>der</td><td>dem</td><td>den …-n</td></tr></table></div><div class="tw"><table><tr><th></th><th>m</th><th>f</th><th>n</th></tr><tr><td>Akk</td><td>einen</td><td>eine</td><td>ein</td></tr><tr><td>Dat</td><td>einem</td><td>einer</td><td>einem</td></tr></table></div><p class="muted">Pronouns: Akk mich, dich, ihn, sie, uns, euch · Dat mir, dir, ihm, ihr, uns, euch.</p></div>'),
'fu': (
'<div class="sheet"><p>Ich freue mich <b>auf</b> das Geschenk — es kommt noch.<br>Ich freue mich <b>über</b> das Geschenk — ich habe es schon.</p></div>',
'<div class="sheet"><p>Ich freue mich <b>auf</b> das Geschenk — I look forward to it (still ahead).<br>Ich freue mich <b>über</b> das Geschenk — I\'m happy with it (already have it).</p></div>'),
'q': (_q('Präposition', 'Sache', 'Person', 'Vor Vokal +r: wo<b>r</b>auf. worum (um was?) ≠ warum (aus welchem Grund?). Ort — Wo?'),
      _q('Preposition', 'About a thing', 'About a person', 'Before a vowel +r: wo<b>r</b>auf. worum (about what?) ≠ warum (why?). Place — Wo?')),
'da': (_da('Präposition', 'Sache schon genannt', 'Person'), _da('Preposition', 'Thing already named', 'Person')),
'ord': (
_ord([('Aussage', 'Verb auf Position 2'), ('W-Frage', 'W-Wort → Verb → wer'), ('Ja / Nein', 'Verb vorne'), ('Modalverb', 'Infinitiv am Ende'), ('weil / dass', 'Verb am Ende'), ('Indirekte Frage', 'Verb am Ende')]),
_ord([('Statement', 'verb in position 2'), ('W-question', 'W-word → verb → who'), ('Yes / no', 'verb first'), ('Modal verb', 'infinitive at the end'), ('weil / dass', 'verb at the end'), ('Indirect question', 'verb at the end')])),
'zweck': (
'<div class="sheet"><div class="tw"><table><tr><th>Konstruktion</th><th>Beispiel</th></tr><tr><td><b>damit</b> + Subjekt … Verb am Ende</td><td>Ich lerne Deutsch, damit ich in Deutschland arbeiten kann.</td></tr><tr><td><b>um</b> … <b>zu</b> + Infinitiv</td><td>Ich lerne Deutsch, um in Deutschland arbeiten zu können.</td></tr></table></div><p>Dieselbe Person (ich lerne — ich arbeite) → beides geht. Verschiedene Personen → nur <b>damit</b>: Ich gebe dir Geld, damit <b>du</b> Essen kaufen kannst.</p><p class="muted">Bei derselben Person sagt man meistens um … zu. Bei trennbaren Verben steht zu in der Mitte: um früh auf<b>zu</b>stehen.</p></div>',
'<div class="sheet"><div class="tw"><table><tr><th>Structure</th><th>Example</th></tr><tr><td><b>damit</b> + subject … verb at the end</td><td>Ich lerne Deutsch, damit ich in Deutschland arbeiten kann.</td></tr><tr><td><b>um</b> … <b>zu</b> + infinitive</td><td>Ich lerne Deutsch, um in Deutschland arbeiten zu können.</td></tr></table></div><p>Same person (I learn — I work) → both work. Different people → only <b>damit</b>: Ich gebe dir Geld, damit <b>du</b> Essen kaufen kannst.</p><p class="muted">With the same person Germans mostly say um … zu. With separable verbs zu goes in the middle: um früh auf<b>zu</b>stehen.</p></div>'),
'sep': (
'<div class="sheet"><div class="tw"><table><tr><th>Verb</th><th>Jetzt</th><th>Perfekt</th></tr><tr><td>teilnehmen</td><td>Ich nehme am Kurs teil.</td><td>teilgenommen</td></tr><tr><td>abholen</td><td>Ich hole ihn ab.</td><td>abgeholt</td></tr><tr><td>mitbringen</td><td>Ich bringe einen Kuchen mit.</td><td>mitgebracht</td></tr><tr><td>stattfinden</td><td>Das Fest findet im Juni statt.</td><td>stattgefunden</td></tr></table></div><p class="muted">Mit Modalverb — am Ende und zusammen: Ich möchte am Kurs teilnehmen.</p></div>',
'<div class="sheet"><div class="tw"><table><tr><th>Verb</th><th>Now</th><th>Perfekt</th></tr><tr><td>teilnehmen</td><td>Ich nehme am Kurs teil.</td><td>teilgenommen</td></tr><tr><td>abholen</td><td>Ich hole ihn ab.</td><td>abgeholt</td></tr><tr><td>mitbringen</td><td>Ich bringe einen Kuchen mit.</td><td>mitgebracht</td></tr><tr><td>stattfinden</td><td>Das Fest findet im Juni statt.</td><td>stattgefunden</td></tr></table></div><p class="muted">With a modal verb — at the end, in one word: Ich möchte am Kurs teilnehmen.</p></div>'),
'gift': (
'<div class="sheet"><p>Ich schenke <b>meinem Sohn</b> (wem → Dat) <b>einen Teddybären</b> (was → Akk).<br>Ich wünsche <b>dir / euch / Ihnen</b> alles Gute.</p></div>',
'<div class="sheet"><p>Ich schenke <b>meinem Sohn</b> (to whom → Dat) <b>einen Teddybären</b> (what → Akk).<br>Ich wünsche <b>dir / euch / Ihnen</b> alles Gute.</p></div>'),
'time': (
'<div class="sheet"><p><b>um</b> acht — genau um acht · <b>ab</b> acht — von acht an<br><b>am</b> = an + dem · <b>im</b> = in + dem · <b>zum</b> = zu + dem · <b>zur</b> = zu + der · <b>vom</b> = von + dem</p></div>',
'<div class="sheet"><p><b>um</b> acht — at exactly eight · <b>ab</b> acht — from eight on<br><b>am</b> = an + dem · <b>im</b> = in + dem · <b>zum</b> = zu + dem · <b>zur</b> = zu + der · <b>vom</b> = von + dem</p></div>'),
'pol': (
'<div class="sheet"><p>Kommt! — zu Freunden · Könnte ich …? — höfliche Bitte · Hier spricht … / Auf Wiederhören — am Telefon · Liebe Marie, ich … — nach dem Komma klein.</p></div>',
'<div class="sheet"><p>Kommt! — to friends · Könnte ich …? — polite request · Hier spricht … / Auf Wiederhören — on the phone · Liebe Marie, ich … — lower case after the comma.</p></div>'),
}
