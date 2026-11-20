# A1 chapters 8-14, A2 chapters 1-4.
from rules1 import r, TB, EX

r('A1.8.0', 'Modalverb sollen',
  '<p><b>sollen</b> – „ich muss, weil jemand das sagt“ (Arzt, Chef). ich soll, du sollst, er soll, wir sollen.</p>' + EX('Der Arzt sagt, ich <b>soll</b> im Bett <b>bleiben</b>.'),
  'Modal verb sollen',
  '<p><b>sollen</b> – “I should, because someone said so” (doctor, boss). ich soll, du sollst, er soll, wir sollen.</p>' + EX('Der Arzt sagt, ich <b>soll</b> im Bett <b>bleiben</b>.'))
AP = TB([['ich', 'mich'], ['du', 'dich'], ['er', 'ihn'], ['sie', 'sie'], ['es', 'es'], ['wir', 'uns'], ['ihr', 'euch'], ['sie / Sie', 'sie / Sie']], ['Nom', 'Akk'])
r('A1.8.1', 'Pronomen im Akkusativ', AP, 'Pronouns in the accusative', AP)
r('A1.9.0', 'mit + Dativ: Verkehrsmittel',
  '<p>Womit fahren wir? – <b>mit + Dativ</b>. Ohne Fahrzeug – <b>zu Fuß</b>.</p>' + EX('Ich fahre mit dem Fahrrad.', 'Sie fährt mit der Straßenbahn.'),
  'mit + dative: transport',
  '<p>How do you travel? – <b>mit + dative</b>. On foot – <b>zu Fuß</b>.</p>' + EX('Ich fahre mit dem Fahrrad.', 'Sie fährt mit der Straßenbahn.'))
WW_DE = TB([['Wo?', 'Ort, keine Bewegung', 'Dativ', 'Ich bin <b>im</b> Park.'], ['Wohin?', 'Bewegung zu einem Ziel', 'Akkusativ', 'Ich gehe <b>in den</b> Park.']], ['Frage', 'Was', 'Fall', 'Beispiel']) + '<p>So funktionieren in, an, auf (und über, unter, vor, hinter, neben, zwischen). sein, liegen, sitzen – wo; gehen, legen, setzen – wohin.</p>'
WW_EN = TB([['Wo? where?', 'place, no movement', 'dative', 'Ich bin <b>im</b> Park.'], ['Wohin? where to?', 'movement to a goal', 'accusative', 'Ich gehe <b>in den</b> Park.']], ['Question', 'What', 'Case', 'Example']) + '<p>This is how in, an, auf work (also über, unter, vor, hinter, neben, zwischen). sein, liegen, sitzen – where; gehen, legen, setzen – where to.</p>'
r('A1.9.1', 'Wo? → Dativ: in, an, auf, über, unter …', WW_DE, 'Wo? → dative: in, an, auf, über, unter …', WW_EN)
r('A1.9.2', 'Modalverb dürfen',
  '<p><b>dürfen</b> – „es ist erlaubt“. <b>nicht dürfen</b> – „es ist verboten“. ich darf, du darfst, er darf, wir dürfen.</p>',
  'Modal verb dürfen',
  '<p><b>dürfen</b> – “may, it is allowed”. <b>nicht dürfen</b> – “must not”. ich darf, du darfst, er darf, wir dürfen.</p>')
r('A1.10.0', 'Perfekt: haben oder sein',
  '<p>Perfekt = <b>haben/sein</b> (Platz 2) + <b>Partizip II</b> (am Ende). <b>sein</b> – bei Bewegung (fahren, gehen, kommen), bei Veränderung (aufwachen, einschlafen) und bei bleiben, sein. Alle anderen – <b>haben</b>.</p>' + EX('Ich <b>habe</b> gestern Pizza <b>gegessen</b>.', 'Wir <b>sind</b> nach Hamburg <b>gefahren</b>.'),
  'Perfect tense: haben or sein',
  '<p>Perfect = <b>haben/sein</b> (2nd place) + <b>past participle</b> (at the end). <b>sein</b> – with movement (fahren, gehen, kommen), change of state (aufwachen, einschlafen) and with bleiben, sein. All others – <b>haben</b>.</p>' + EX('Ich <b>habe</b> gestern Pizza <b>gegessen</b>.', 'Wir <b>sind</b> nach Hamburg <b>gefahren</b>.'))
r('A1.10.1', 'Partizip II: ge-…-t / ge-…-en',
  TB([['regelmäßig', 'ge- … -t', 'machen → <b>ge</b>mach<b>t</b>'], ['unregelmäßig', 'ge- … -en', 'sehen → <b>ge</b>seh<b>en</b>'], ['trennbar', 'ge in der Mitte', 'einkaufen → ein<b>ge</b>kauft']]),
  'Past participle: ge-…-t / ge-…-en',
  TB([['regular', 'ge- … -t', 'machen → <b>ge</b>mach<b>t</b>'], ['irregular', 'ge- … -en', 'sehen → <b>ge</b>seh<b>en</b>'], ['separable', 'ge in the middle', 'einkaufen → ein<b>ge</b>kauft']]))
r('A1.10.2', 'seit + Dativ',
  '<p><b>seit</b> – „schon (und es dauert noch an)“. Das Verb steht im Präsens!</p>' + EX('Ich wohne <b>seit</b> einem Jahr hier.', 'Er lernt <b>seit</b> zwei Monaten Deutsch.'),
  'seit + dative',
  '<p><b>seit</b> – “for / since (and still going on)”. The verb is in the present tense!</p>' + EX('Ich wohne <b>seit</b> einem Jahr hier.', 'Er lernt <b>seit</b> zwei Monaten Deutsch.'))
DP = TB([['ich', 'mich', 'mir'], ['du', 'dich', 'dir'], ['er', 'ihn', 'ihm'], ['sie', 'sie', 'ihr'], ['wir', 'uns', 'uns'], ['ihr', 'euch', 'euch'], ['sie / Sie', 'sie / Sie', 'ihnen / Ihnen']], ['Nom', 'Akk', 'Dat'])
r('A1.11.0', 'Pronomen im Dativ', DP + '<p>Dativ nach <b>helfen, danken, gehören, gefallen</b>: Das gehört <b>mir</b>.</p>',
  'Pronouns in the dative', DP + '<p>Dative after <b>helfen, danken, gehören, gefallen</b>: Das gehört <b>mir</b>.</p>')
r('A1.11.1', 'Datum: der erste, am ersten',
  '<p>Ordnungszahlen: 1–19 → <b>-te</b> (zwei<b>te</b>), ab 20 → <b>-ste</b> (zwanzig<b>ste</b>). Ausnahmen: <b>erste, dritte, siebte</b>.</p>' + EX('Heute ist der zweit<b>e</b> Juni.', 'Ich habe <b>am</b> zweit<b>en</b> Juni Geburtstag.'),
  'Dates: der erste, am ersten',
  '<p>Ordinal numbers: 1–19 → <b>-te</b> (zwei<b>te</b>), from 20 → <b>-ste</b> (zwanzig<b>ste</b>). Exceptions: <b>erste, dritte, siebte</b>.</p>' + EX('Heute ist der zweit<b>e</b> Juni.', 'Ich habe <b>am</b> zweit<b>en</b> Juni Geburtstag.'))
r('A1.11.2', 'für + Akkusativ',
  '<p>Nach <b>für</b> kommt immer der Akkusativ.</p>' + EX('Das Formular ist für meinen Mann.', 'Ist das für mich?'),
  'für + accusative',
  '<p><b>für</b> is always followed by the accusative.</p>' + EX('Das Formular ist für meinen Mann.', 'Ist das für mich?'))
ADJ = '<table><tr><th></th><th>m</th><th>f</th><th>n</th><th>Pl.</th></tr><tr><td>Nom</td><td>der blau<b>e</b> Mantel</td><td>die rot<b>e</b> Jacke</td><td>das neu<b>e</b> Hemd</td><td>die schwarz<b>en</b> Schuhe</td></tr><tr><td>Akk</td><td>den blau<b>en</b> Mantel</td><td>die rot<b>e</b> Jacke</td><td>das neu<b>e</b> Hemd</td><td>die schwarz<b>en</b> Schuhe</td></tr></table>'
r('A1.12.0', 'Adjektiv: nach dem Verb und vor dem Nomen',
  '<p>Nach <b>sein</b> hat das Adjektiv keine Endung. Vor einem Nomen hat es eine Endung. Nach <b>der/die/das</b> fast immer <b>-e</b>, im Akk m und im Plural <b>-en</b>.</p>' + ADJ,
  'Adjectives: after the verb and before a noun',
  '<p>After <b>sein</b> the adjective has no ending. Before a noun it has one. After <b>der/die/das</b> it is almost always <b>-e</b>, in acc. m and in the plural <b>-en</b>.</p>' + ADJ)
r('A1.12.1', 'welch-?',
  '<p><b>welcher, welche, welches</b> – „welcher von diesen?“. Die Endung wie bei der/die/das.</p>' + EX('Welche Jacke nimmst du?', 'Welchen Pullover möchten Sie?'),
  'welch-?',
  '<p><b>welcher, welche, welches</b> – “which (of these)?”. Endings like der/die/das.</p>' + EX('Welche Jacke nimmst du?', 'Welchen Pullover möchten Sie?'))
r('A1.12.2', 'Komposita',
  '<p>Ein zusammengesetztes Wort nimmt den Artikel vom <b>letzten</b> Teil: die Hand + <b>die</b> Tasche = <b>die</b> Handtasche; die Kinder + <b>der</b> Garten = <b>der</b> Kindergarten.</p>',
  'Compound nouns',
  '<p>A compound noun takes the article of its <b>last</b> part: die Hand + <b>die</b> Tasche = <b>die</b> Handtasche; die Kinder + <b>der</b> Garten = <b>der</b> Kindergarten.</p>')
r('A1.13.0', 'es: es regnet, es gibt',
  '<p>Ein „leeres“ <b>es</b> braucht man beim Wetter, bei der Uhrzeit und in <b>es gibt</b> (+ Akk) „da ist, da sind“.</p>' + EX('Es schneit.', 'Es ist acht Uhr.', 'Hier gibt es einen Bahnhof.'),
  'es: es regnet, es gibt',
  '<p>An “empty” <b>es</b> is needed for weather, time and in <b>es gibt</b> (+ acc.) “there is, there are”.</p>' + EX('Es schneit.', 'Es ist acht Uhr.', 'Hier gibt es einen Bahnhof.'))
r('A1.13.1', 'für, um, durch',
  '<p><b>für · ohne · durch · gegen · um</b> → immer Akkusativ.</p><p>Das ist für <b>den</b> Chef. · Ich gehe ohne <b>dich</b>.<br>Wir sprechen über <b>den</b> Film. · Ich warte auf <b>den</b> Bus.</p><p>Auch Verben mit Präposition: sprechen über, warten auf, sich freuen auf – Akkusativ.</p>',
  'für, um, durch',
  '<p><b>für · ohne · durch · gegen · um</b> → always accusative.</p><p>Das ist für <b>den</b> Chef. · Ich gehe ohne <b>dich</b>.<br>Wir sprechen über <b>den</b> Film. · Ich warte auf <b>den</b> Bus.</p><p>Verbs with a preposition too: sprechen über, warten auf, sich freuen auf – accusative.</p>')
CMP = TB([['groß', 'größer'], ['alt', 'älter'], ['gut', '<b>besser</b>'], ['viel', '<b>mehr</b>'], ['gern', '<b>lieber</b>']])
r('A1.13.2', 'Komparativ: größer als, so … wie',
  '<p>Vergleich: Adjektiv + <b>-er</b> + <b>als</b>. Gleich: <b>genauso … wie</b>. Kurze Adjektive oft mit Umlaut.</p>' + CMP + EX('Der Zug ist schneller <b>als</b> der Bus.', 'Heute ist es genauso warm <b>wie</b> gestern.'),
  'Comparative: größer als, so … wie',
  '<p>Comparing: adjective + <b>-er</b> + <b>als</b> (than). The same: <b>genauso … wie</b> (as … as). Short adjectives often get an umlaut.</p>' + CMP + EX('Der Zug ist schneller <b>als</b> der Bus.', 'Heute ist es genauso warm <b>wie</b> gestern.'))
r('A1.14.0', 'aber, denn, und, oder',
  '<p>Diese Konjunktionen <b>ändern die Wortstellung nicht</b>: danach steht das Verb wie immer auf Platz 2. Anders bei <b>weil</b>: da geht das Verb ans Ende (A2, Kap. 2).</p>' + EX('Ich komme, <b>aber</b> ich habe wenig Zeit.', 'Ich bleibe zu Hause, <b>denn</b> es regnet.'),
  'aber, denn, und, oder',
  '<p>These conjunctions <b>do not change the word order</b>: the verb stays in 2nd place. Different with <b>weil</b>: it sends the verb to the end (A2, ch. 2).</p>' + EX('Ich komme, <b>aber</b> ich habe wenig Zeit.', 'Ich bleibe zu Hause, <b>denn</b> es regnet.'))
r('A2.1.0', 'Perfekt (Wiederholung)',
  '<p>haben/sein auf Platz 2 + Partizip II am Ende. sein – Bewegung und Veränderung. Ausführlich: A1, Kap. 10.</p>' + EX('Ich <b>habe</b> in Kiew <b>studiert</b>.', 'Ich <b>bin</b> nach Deutschland <b>gekommen</b>.'),
  'Perfect tense (review)',
  '<p>haben/sein in 2nd place + past participle at the end. sein – movement and change. More in A1, ch. 10.</p>' + EX('Ich <b>habe</b> in Kiew <b>studiert</b>.', 'Ich <b>bin</b> nach Deutschland <b>gekommen</b>.'))
r('A2.1.1', 'Partizip ohne ge-',
  '<p>Ohne <b>ge-</b>: Verben auf <b>-ieren</b> und mit untrennbaren Vorsilben <b>be-, ver-, er-, ent-, ge-, emp-, zer-</b>.</p>' + EX('Ich habe Deutsch <b>studiert</b>.', 'Er hat sein Land <b>verlassen</b>.', 'Ich habe viel <b>erlebt</b>.'),
  'Participles without ge-',
  '<p>No <b>ge-</b>: verbs ending in <b>-ieren</b> and verbs with the inseparable prefixes <b>be-, ver-, er-, ent-, ge-, emp-, zer-</b>.</p>' + EX('Ich habe Deutsch <b>studiert</b>.', 'Er hat sein Land <b>verlassen</b>.', 'Ich habe viel <b>erlebt</b>.'))
r('A2.1.2', 'Possessivartikel (Wiederholung)',
  '<p>Endungen wie bei <b>ein</b>: Akk m – mein<b>en</b>, Dat – mein<b>em</b> / mein<b>er</b>, Plural Dat – mein<b>en</b> + -n.</p>' + EX('Ich wohne bei mein<b>er</b> Tante.', 'Ich spreche mit mein<b>em</b> Bruder.'),
  'Possessives (review)',
  '<p>Endings like <b>ein</b>: acc. m – mein<b>en</b>, dat. – mein<b>em</b> / mein<b>er</b>, plural dat. – mein<b>en</b> + -n.</p>' + EX('Ich wohne bei mein<b>er</b> Tante.', 'Ich spreche mit mein<b>em</b> Bruder.'))
r('A2.2.0', 'Nebensätze mit weil',
  '<p><b>weil</b> gibt einen Grund an. Im Nebensatz geht das konjugierte Verb <b>ans Ende</b>. Vor weil steht ein Komma.</p>' + EX('Ich lese E-Books, <b>weil</b> sie leicht <b>sind</b>.', 'Warum chattest du? — <b>Weil</b> es schnell <b>geht</b>.'),
  'Clauses with weil',
  '<p><b>weil</b> = “because”. In the clause the conjugated verb goes <b>to the end</b>. There is a comma before weil.</p>' + EX('Ich lese E-Books, <b>weil</b> sie leicht <b>sind</b>.', 'Warum chattest du? — <b>Weil</b> es schnell <b>geht</b>.'))
r('A2.2.1', 'Nebensätze mit dass',
  '<p><b>dass</b> nach <i>ich finde, ich denke, ich glaube, es ist wichtig</i>. Das Verb geht <b>ans Ende</b>.</p>' + EX('Ich denke, <b>dass</b> das Internet nützlich <b>ist</b>.'),
  'Clauses with dass',
  '<p><b>dass</b> = “that” after <i>ich finde, ich denke, ich glaube, es ist wichtig</i>. The verb goes <b>to the end</b>.</p>' + EX('Ich denke, <b>dass</b> das Internet nützlich <b>ist</b>.'))
r('A2.3.0', 'Wechselpräpositionen: Wo? / Wohin?', WW_DE, 'Two-way prepositions: Wo? / Wohin?', WW_EN)
r('A2.3.1', 'ja, nein, doch',
  '<p>Auf eine Frage mit <b>nicht/kein</b> sagt man „doch“, wenn die Antwort positiv ist.</p>' + TB([['Hast du Zeit?', 'Ja. / Nein.'], ['Hast du keine Zeit?', '<b>Doch</b>, ich habe Zeit. / Nein, keine.']]),
  'ja, nein, doch',
  '<p>To a question with <b>nicht/kein</b>, a positive answer is <b>doch</b> (“yes, I do”).</p>' + TB([['Hast du Zeit?', 'Ja. / Nein.'], ['Hast du keine Zeit?', '<b>Doch</b>, ich habe Zeit. / Nein, keine.']]))
r('A2.4.0', 'Nebensätze mit wenn',
  '<p><b>wenn</b> = „immer wenn, falls“. Das Verb im Nebensatz geht ans Ende. Steht der Nebensatz vorne, beginnt der Hauptsatz <b>mit dem Verb</b>.</p>' + EX('<b>Wenn</b> es regnet, <b>bleiben</b> wir zu Hause.', 'Ich lerne, <b>wenn</b> die Kinder schlafen.'),
  'Clauses with wenn',
  '<p><b>wenn</b> = “when(ever), if”. The verb in the clause goes to the end. If the clause comes first, the main clause starts <b>with the verb</b>.</p>' + EX('<b>Wenn</b> es regnet, <b>bleiben</b> wir zu Hause.', 'Ich lerne, <b>wenn</b> die Kinder schlafen.'))
MP = TB([['können', 'konnte'], ['müssen', 'musste'], ['wollen', 'wollte'], ['dürfen', 'durfte'], ['sollen', 'sollte']])
r('A2.4.1', 'Modalverben im Präteritum',
  '<p>Über die Vergangenheit spricht man mit Modalverben meist im Präteritum: ohne Umlaut + <b>-te</b>.</p>' + MP + EX('Früher <b>musste</b> ich eine Uniform tragen.'),
  'Modal verbs in the simple past',
  '<p>For the past, modal verbs are usually in the simple past: no umlaut + <b>-te</b>.</p>' + MP + EX('Früher <b>musste</b> ich eine Uniform tragen.'))
