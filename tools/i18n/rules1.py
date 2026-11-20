# Rule titles and explanations in German and English (A1, chapters 1-7).
T = {}
def r(id, de_t, de_b, en_t, en_b):
    T[id] = {'de': {'t': de_t, 'b': de_b}, 'en': {'t': en_t, 'b': en_b}}

TB = lambda rows, head=None: '<table>' + ('<tr>' + ''.join(f'<th>{h}</th>' for h in head) + '</tr>' if head else '') + ''.join('<tr>' + ''.join(f'<td>{c}</td>' for c in row) + '</tr>' for row in rows) + '</table>'
EX = lambda *xs: '<ul>' + ''.join(f'<li>{x}</li>' for x in xs) + '</ul>'

r('A1.1.0', 'Alphabet',
  '<p>Deutsche Buchstaben klingen fast immer gleich. Besonders: <b>ä, ö, ü, ß</b>. Verbindungen: <b>ei</b> klingt wie „ai“, <b>ie</b> ist ein langes i, <b>eu/äu</b> klingt wie „oi“, <b>sch</b>, <b>ch</b> nach a/o/u ist rau (Bach), <b>z</b> = „ts“, <b>v</b> meist wie f, <b>w</b> wie ein weiches w.</p>' + EX('Wie schreibt man das? — M-ü-l-l-e-r.', 'mein, Brief, neu, Schule, Zug'),
  'Alphabet',
  '<p>German letters almost always sound the same. Special ones: <b>ä, ö, ü, ß</b>. Combinations: <b>ei</b> sounds like “eye”, <b>ie</b> is a long “ee”, <b>eu/äu</b> like “oy” in boy, <b>sch</b> = “sh”, <b>ch</b> after a/o/u is rough like Scottish “loch”, <b>z</b> = “ts”, <b>v</b> usually = “f”, <b>w</b> = “v”.</p>' + EX('Wie schreibt man das? — M-ü-l-l-e-r.', 'mein, Brief, neu, Schule, Zug'))
r('A1.1.1', 'Aussagesätze: Verb auf Platz 2',
  '<p>Im normalen Satz steht das konjugierte Verb immer auf <b>Platz 2</b>. Auf Platz 1 kann das Subjekt, eine Zeit oder ein Ort stehen.</p>' + EX('<b>Ich</b> wohne in Lüneburg.', '<b>Hier</b> wohne ich schon lange.'),
  'Statements: verb in 2nd place',
  '<p>In a normal sentence the conjugated verb is always in <b>2nd place</b>. First can be the subject, a time or a place.</p>' + EX('<b>Ich</b> wohne in Lüneburg.', '<b>Hier</b> wohne ich schon lange.'))
r('A1.1.2', 'Fragen: Wer? Wie? Woher? Was?',
  '<p>Das Fragewort steht vorne, das Verb auf <b>Platz 2</b>, dann das Subjekt.</p>' + TB([['Wer?', 'Person', 'Wer ist das?'], ['Wie?', 'Art und Weise', 'Wie heißen Sie?'], ['Woher?', 'Herkunft', 'Woher kommst du?'], ['Wo?', 'Ort', 'Wo wohnen Sie?'], ['Was?', 'Sache', 'Was machst du?']]),
  'Questions: Wer? Wie? Woher? Was?',
  '<p>The question word comes first, the verb in <b>2nd place</b>, then the subject.</p>' + TB([['Wer?', 'who?', 'Wer ist das?'], ['Wie?', 'how?', 'Wie heißen Sie?'], ['Woher?', 'where from?', 'Woher kommst du?'], ['Wo?', 'where?', 'Wo wohnen Sie?'], ['Was?', 'what?', 'Was machst du?']]))
r('A1.1.3', 'Präsens: ich, du, wir, ihr, Sie',
  TB([['ich', '-e', 'komme'], ['du', '-st', 'kommst'], ['er/sie/es', '-t', 'kommt'], ['wir', '-en', 'kommen'], ['ihr', '-t', 'kommt'], ['sie / Sie', '-en', 'kommen']], ['', 'Endung', 'kommen']) + '<p><b>sein</b>: bin, bist, ist, sind, seid, sind.</p>',
  'Present tense: ich, du, wir, ihr, Sie',
  TB([['ich', '-e', 'komme'], ['du', '-st', 'kommst'], ['er/sie/es', '-t', 'kommt'], ['wir', '-en', 'kommen'], ['ihr', '-t', 'kommt'], ['sie / Sie', '-en', 'kommen']], ['', 'ending', 'kommen']) + '<p><b>sein</b>: bin, bist, ist, sind, seid, sind.</p>')
r('A1.1.4', 'du oder Sie',
  '<p><b>du</b> – für Freunde, Kinder, Familie, oft auch im Kurs. <b>Sie</b> (groß geschrieben) – für Fremde, auf dem Amt, bei der Arbeit. Das Verb bei Sie wie bei „sie“ (Plural): Sie komm<b>en</b>.</p>',
  'du or Sie',
  '<p><b>du</b> – for friends, children, family, often in class. <b>Sie</b> (capital S) – for strangers, offices, at work. The verb with Sie is like “they”: Sie komm<b>en</b>.</p>')
r('A1.2.0', 'Präsens: er, sie, es, sie',
  '<p>er/sie/es → <b>-t</b>; sie (Plural) → <b>-en</b>. Endet der Stamm auf -t/-d, kommt ein -e- dazu: er arbeit<b>e</b>t. Manche Verben ändern den Vokal: sprechen → er spr<b>i</b>cht.</p>' + EX('Sie kommt aus Syrien.', 'Er arbeitet in Hamburg.', 'Sie sprechen Arabisch.'),
  'Present tense: er, sie, es, sie',
  '<p>er/sie/es → <b>-t</b>; sie (they) → <b>-en</b>. If the stem ends in -t/-d, add -e-: er arbeit<b>e</b>t. Some verbs change the vowel: sprechen → er spr<b>i</b>cht.</p>' + EX('Sie kommt aus Syrien.', 'Er arbeitet in Hamburg.', 'Sie sprechen Arabisch.'))
r('A1.2.1', 'Artikel: der, die, das / ein, eine',
  TB([['der', 'ein', 'Tisch'], ['die', 'eine', 'Lampe'], ['das', 'ein', 'Buch'], ['die (Plural)', '—', 'Bücher']], ['bestimmt', 'unbestimmt', '']) + '<p><b>ein/eine</b> – wenn wir etwas zum ersten Mal nennen. <b>der/die/das</b> – wenn schon klar ist, was gemeint ist.</p>',
  'Articles: der, die, das / ein, eine',
  TB([['der', 'ein', 'Tisch'], ['die', 'eine', 'Lampe'], ['das', 'ein', 'Buch'], ['die (plural)', '—', 'Bücher']], ['definite', 'indefinite', '']) + '<p><b>ein/eine</b> – “a”, when you mention something for the first time. <b>der/die/das</b> – “the”, when it is already clear what you mean.</p>')
r('A1.2.2', 'Plural',
  '<p>Im Plural ist der Artikel immer <b>die</b>. Die Endung lernst du mit dem Wort (im Wörterbuch steht sie daneben: <i>-e, ¨-er, -n, -s</i>).</p>' + TB([['-e', 'der Tisch → die Tisch<b>e</b>'], ['¨-e', 'der Stuhl → die St<b>ü</b>hl<b>e</b>'], ['-n / -en', 'die Lampe → die Lampe<b>n</b>'], ['¨-er', 'das Buch → die B<b>ü</b>ch<b>er</b>'], ['-s', 'das Handy → die Handy<b>s</b>'], ['–', 'der Schlüssel → die Schlüssel']]),
  'Plural',
  '<p>In the plural the article is always <b>die</b>. Learn the ending with the word (the dictionary shows it: <i>-e, ¨-er, -n, -s</i>).</p>' + TB([['-e', 'der Tisch → die Tisch<b>e</b>'], ['¨-e', 'der Stuhl → die St<b>ü</b>hl<b>e</b>'], ['-n / -en', 'die Lampe → die Lampe<b>n</b>'], ['¨-er', 'das Buch → die B<b>ü</b>ch<b>er</b>'], ['-s', 'das Handy → die Handy<b>s</b>'], ['–', 'der Schlüssel → die Schlüssel']]))
r('A1.2.3', 'W-Fragen',
  '<p>W-Frage: Fragewort + Verb + Rest. Die Antwort ist ein ganzer Satz oder kurz.</p>' + EX('Was kostet der Laptop? — 300 Euro.', 'Wo liegt Damaskus? — In Syrien.'),
  'W-questions',
  '<p>W-question: question word + verb + the rest. Answer with a full sentence or briefly.</p>' + EX('Was kostet der Laptop? — 300 Euro.', 'Wo liegt Damaskus? — In Syrien.'))
r('A1.3.0', 'Ja/Nein-Fragen',
  '<p>Frage ohne Fragewort: das Verb steht <b>vorne</b>.</p>' + EX('<b>Ist</b> die Wohnung groß? — Ja, sie ist groß.', '<b>Hat</b> die Wohnung einen Balkon? — Nein.'),
  'Yes/no questions',
  '<p>A question without a question word: the verb comes <b>first</b>.</p>' + EX('<b>Ist</b> die Wohnung groß? — Ja, sie ist groß.', '<b>Hat</b> die Wohnung einen Balkon? — Nein.'))
r('A1.3.1', 'Akkusativ: den / einen',
  '<p>Nach <i>haben, brauchen, kaufen, suchen, sehen</i> kommt der Akkusativ (wen? was?). Es ändert sich <b>nur das Maskulinum</b>: der → <b>den</b>, ein → <b>einen</b>.</p>' + TB([['Nom', 'der / ein', 'die / eine', 'das / ein'], ['Akk', '<b>den / einen</b>', 'die / eine', 'das / ein']], ['', 'm', 'f', 'n']),
  'Accusative: den / einen',
  '<p>After <i>haben, brauchen, kaufen, suchen, sehen</i> comes the accusative (whom? what?). <b>Only the masculine</b> changes: der → <b>den</b>, ein → <b>einen</b>.</p>' + TB([['Nom', 'der / ein', 'die / eine', 'das / ein'], ['Acc', '<b>den / einen</b>', 'die / eine', 'das / ein']], ['', 'm', 'f', 'n']))
r('A1.3.2', 'Verneinung mit kein',
  '<p><b>kein</b> = „nicht ein“, vor einem Nomen. Es geht wie ein: kein, keine, kein; Akkusativ m – <b>keinen</b>; Plural – <b>keine</b>. <b>nicht</b> – vor Adjektiven und Verben.</p>' + EX('Das ist kein Stuhl.', 'Wir haben keinen Fernseher.', 'Die Wohnung ist nicht teuer.'),
  'Negation with kein',
  '<p><b>kein</b> = “no, not a” before a noun. It works like ein: kein, keine, kein; accusative m – <b>keinen</b>; plural – <b>keine</b>. <b>nicht</b> – before adjectives and verbs.</p>' + EX('Das ist kein Stuhl.', 'Wir haben keinen Fernseher.', 'Die Wohnung ist nicht teuer.'))
r('A1.3.3', 'der → er, die → sie, das → es',
  '<p>Das Pronomen folgt dem Genus des Wortes, nicht „Person oder Sache“: der Tisch → <b>er</b>, die Lampe → <b>sie</b>, das Bett → <b>es</b>, Plural → <b>sie</b>.</p>' + EX('Wie findest du die Küche? — <b>Sie</b> ist toll.'),
  'der → er, die → sie, das → es',
  '<p>The pronoun follows the gender of the word, even for things: der Tisch → <b>er</b> (it), die Lampe → <b>sie</b>, das Bett → <b>es</b>, plural → <b>sie</b>.</p>' + EX('Wie findest du die Küche? — <b>Sie</b> ist toll.'))
r('A1.4.0', 'Possessivartikel: mein, dein, sein …',
  TB([['ich', 'mein'], ['du', 'dein'], ['er / es', 'sein'], ['sie', 'ihr'], ['wir', 'unser'], ['ihr', 'euer'], ['sie / Sie', 'ihr / Ihr']], ['wer', 'wessen']) + '<p>Die Endung wie bei <b>ein</b>: mein Vater, mein<b>e</b> Mutter, mein Kind, mein<b>e</b> Eltern; Akk m: mein<b>en</b> Bruder.</p>',
  'Possessives: mein, dein, sein …',
  TB([['ich', 'mein (my)'], ['du', 'dein (your)'], ['er / es', 'sein (his)'], ['sie', 'ihr (her)'], ['wir', 'unser (our)'], ['ihr', 'euer (your)'], ['sie / Sie', 'ihr / Ihr (their / your)']], ['who', 'whose']) + '<p>Endings like <b>ein</b>: mein Vater, mein<b>e</b> Mutter, mein Kind, mein<b>e</b> Eltern; acc. m: mein<b>en</b> Bruder.</p>')
r('A1.4.1', 'Reihenfolge: zuerst, dann, danach',
  '<p>Beginnt der Satz mit <b>zuerst, dann, danach, am Montag</b>, bleibt das Verb auf Platz 2 und das Subjekt kommt <b>nach</b> dem Verb.</p>' + EX('Zuerst <b>kaufen</b> wir ein.', 'Danach <b>gehen</b> wir ins Kino.'),
  'Sequence: zuerst, dann, danach',
  '<p>If the sentence starts with <b>zuerst, dann, danach, am Montag</b>, the verb stays in 2nd place and the subject comes <b>after</b> the verb.</p>' + EX('Zuerst <b>kaufen</b> wir ein.', 'Danach <b>gehen</b> wir ins Kino.'))
r('A1.4.2', 'Verben mit Vokalwechsel',
  '<p>Der Vokal ändert sich nur bei <b>du</b> und <b>er/sie/es</b>.</p>' + TB([['e → i', 'sprechen, essen, nehmen', 'du sprichst, er isst, er nimmt'], ['e → ie', 'lesen, sehen', 'du liest, er sieht'], ['a → ä', 'fahren, schlafen', 'du fährst, er schläft']]),
  'Verbs with a vowel change',
  '<p>The vowel changes only with <b>du</b> and <b>er/sie/es</b>.</p>' + TB([['e → i', 'sprechen, essen, nehmen', 'du sprichst, er isst, er nimmt'], ['e → ie', 'lesen, sehen', 'du liest, er sieht'], ['a → ä', 'fahren, schlafen', 'du fährst, er schläft']]))
PRT = TB([['ich', 'war', 'hatte'], ['du', 'warst', 'hattest'], ['er/sie', 'war', 'hatte'], ['wir', 'waren', 'hatten'], ['ihr', 'wart', 'hattet'], ['sie/Sie', 'waren', 'hatten']], ['', 'sein', 'haben'])
r('A1.4.3', 'Präteritum: war, hatte', '<p>Bei <b>sein</b> und <b>haben</b> spricht man über die Vergangenheit meist so:</p>' + PRT,
  'Simple past: war, hatte', '<p>For <b>sein</b> and <b>haben</b> people usually talk about the past like this:</p>' + PRT)
r('A1.5.0', 'Trennbare Verben',
  '<p>Die Vorsilbe (<i>auf, an, ein, mit, fern …</i>) trennt sich ab und geht ans <b>Ende</b> des Satzes.</p>' + EX('Ich <b>stehe</b> um sieben <b>auf</b>.', '<b>Rufst</b> du mich <b>an</b>?'),
  'Separable verbs',
  '<p>The prefix (<i>auf, an, ein, mit, fern …</i>) splits off and goes to the <b>end</b> of the sentence.</p>' + EX('Ich <b>stehe</b> um sieben <b>auf</b>.', '<b>Rufst</b> du mich <b>an</b>?'))
r('A1.5.1', 'gehen + Infinitiv',
  '<p><b>gehen</b> wird konjugiert, das zweite Verb steht unverändert am Ende.</p>' + EX('Ich gehe heute schwimmen.', 'Gehst du mit spazieren?'),
  'gehen + infinitive',
  '<p><b>gehen</b> is conjugated, the second verb stays unchanged at the end.</p>' + EX('Ich gehe heute schwimmen.', 'Gehst du mit spazieren?'))
r('A1.5.2', 'Zeit im Satz',
  '<p>Die Zeit kann vorne stehen – das Verb bleibt auf Platz 2. In der Mitte gilt: <b>wann → wie → wohin</b>.</p>' + EX('Ich gehe am Montag zum Arzt.', 'Am Montag gehe ich zum Arzt.'),
  'Time in the sentence',
  '<p>The time can come first – the verb stays in 2nd place. In the middle the order is <b>when → how → where to</b>.</p>' + EX('Ich gehe am Montag zum Arzt.', 'Am Montag gehe ich zum Arzt.'))
r('A1.5.3', 'um, am, von … bis',
  TB([['um', 'genaue Uhrzeit', 'um halb acht'], ['am', 'Tag, Tageszeit', 'am Freitag, am Abend'], ['von … bis', 'Zeitraum', 'von 9 bis 12 Uhr'], ['ab', 'ab diesem Zeitpunkt', 'ab 8 Uhr']]),
  'um, am, von … bis',
  TB([['um', 'exact time', 'um halb acht'], ['am', 'day, part of the day', 'am Freitag, am Abend'], ['von … bis', 'from … to', 'von 9 bis 12 Uhr'], ['ab', 'from … on', 'ab 8 Uhr']]))
r('A1.6.0', 'Imperativ',
  TB([['du', 'Komm! Nimm! Lies!'], ['ihr', 'Kommt! Nehmt!'], ['Sie', 'Kommen Sie! Nehmen Sie!']]) + '<p>Bei <b>du</b> fallen -st und „du“ weg: du nimmst → <b>Nimm!</b> Höflich mit <i>bitte</i>.</p>',
  'Imperative',
  TB([['du', 'Komm! Nimm! Lies!'], ['ihr', 'Kommt! Nehmt!'], ['Sie', 'Kommen Sie! Nehmen Sie!']]) + '<p>With <b>du</b>, drop -st and “du”: du nimmst → <b>Nimm!</b> Add <i>bitte</i> to be polite.</p>')
MM = TB([['ich', 'möchte', 'mag'], ['du', 'möchtest', 'magst'], ['er/sie', 'möchte', 'mag'], ['wir', 'möchten', 'mögen']], ['', 'möchten', 'mögen'])
r('A1.6.1', 'möchten und mögen', '<p><b>möchten</b> – ich will jetzt etwas (höflich). <b>mögen</b> – ich habe etwas allgemein gern.</p>' + MM,
  'möchten and mögen', '<p><b>möchten</b> – I would like something now (polite). <b>mögen</b> – I like something in general.</p>' + MM)
r('A1.6.2', 'gern / nicht gern / lieber',
  '<p><b>gern</b> steht nach dem Verb: „das mache ich gern“. Wenn nicht – <b>nicht gern</b>. Mehr als etwas anderes – <b>lieber</b>.</p>' + EX('Ich trinke gern Tee.', 'Er isst nicht gern Fleisch.'),
  'gern / nicht gern / lieber',
  '<p><b>gern</b> goes after the verb: “I like doing it”. If not – <b>nicht gern</b>. More than something else – <b>lieber</b>.</p>' + EX('Ich trinke gern Tee.', 'Er isst nicht gern Fleisch.'))
r('A1.6.3', 'man',
  '<p><b>man</b> = „die Leute, alle“. Das Verb wie bei er: man isst, man trinkt.</p>',
  'man',
  '<p><b>man</b> = “people, one, you in general”. The verb is like er: man isst, man trinkt.</p>')
MD = TB([['ich', 'kann', 'muss', 'will'], ['du', 'kannst', 'musst', 'willst'], ['er/sie', 'kann', 'muss', 'will'], ['wir', 'können', 'müssen', 'wollen']], ['', 'können', 'müssen', 'wollen'])
r('A1.7.0', 'Modalverben: können, müssen, wollen',
  '<p>Das Modalverb steht auf Platz 2, das zweite Verb im Infinitiv <b>am Ende</b> (Satzklammer).</p>' + MD + EX('Ich <b>kann</b> gut Deutsch <b>sprechen</b>.'),
  'Modal verbs: können, müssen, wollen',
  '<p>The modal verb is in 2nd place, the second verb goes <b>to the end</b> as an infinitive.</p>' + MD + EX('Ich <b>kann</b> gut Deutsch <b>sprechen</b>.'))
DT = '<table><tr><th></th><th>m</th><th>f</th><th>n</th><th>Pl.</th></tr><tr><td>Nom</td><td>der / ein</td><td>die / eine</td><td>das / ein</td><td>die</td></tr><tr><td>Dat</td><td><b>dem / einem</b></td><td><b>der / einer</b></td><td><b>dem / einem</b></td><td><b>den</b> + -n</td></tr></table>'
r('A1.7.1', 'Dativ: Artikel', DT, 'Dative: articles', DT)
r('A1.7.2', 'Präpositionen mit Dativ: aus, bei, mit, nach, von, zu',
  '<p><b>aus · bei · mit · nach · seit · von · zu</b> → immer Dativ.</p><p>Ich fahre mit <b>dem</b> Bus. · Ich gehe zu<b>m</b> Arzt.<br>Ich komme von <b>der</b> Arbeit. · Ich wohne bei <b>dir</b>.</p><p>Merksatz: aus-bei-mit-nach-seit-von-zu.</p>',
  'Prepositions with dative: aus, bei, mit, nach, von, zu',
  '<p><b>aus · bei · mit · nach · seit · von · zu</b> → always dative.</p><p>Ich fahre mit <b>dem</b> Bus. · Ich gehe zu<b>m</b> Arzt.<br>Ich komme von <b>der</b> Arbeit. · Ich wohne bei <b>dir</b>.</p><p>Remember the chant: aus-bei-mit-nach-seit-von-zu.</p>')
