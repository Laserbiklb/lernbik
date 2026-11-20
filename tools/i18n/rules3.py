# A2 chapters 5-14, plus corrected Russian tables for A2.13.0 / A2.14.0.
from rules1 import r, T, TB, EX

r('A2.5.0', 'Indirekte Fragen',
  '<p>Höflich: <i>Wissen Sie / Können Sie mir sagen</i> + W-Wort + … Verb <b>am Ende</b>.</p>' + EX('Wo ist das Büro? → Können Sie mir sagen, wo das Büro <b>ist</b>?'),
  'Indirect questions',
  '<p>Polite: <i>Wissen Sie / Können Sie mir sagen</i> + W-word + … verb <b>at the end</b>.</p>' + EX('Wo ist das Büro? → Können Sie mir sagen, wo das Büro <b>ist</b>?'))
WI = TB([['ich', 'weiß'], ['du', 'weißt'], ['er/sie', 'weiß'], ['wir', 'wissen'], ['ihr', 'wisst'], ['sie/Sie', 'wissen']])
r('A2.5.1', 'Das Verb wissen', WI + '<p><b>wissen</b> – eine Tatsache kennen. <b>kennen</b> – eine Person oder einen Ort kennen.</p>',
  'The verb wissen', WI + '<p><b>wissen</b> – to know a fact. <b>kennen</b> – to know a person or a place.</p>')
r('A2.5.2', 'Pronomen im Dativ (Wiederholung)',
  TB([['ich', 'mich', 'mir'], ['du', 'dich', 'dir'], ['er', 'ihn', 'ihm'], ['sie', 'sie', 'ihr'], ['wir', 'uns', 'uns'], ['ihr', 'euch', 'euch'], ['sie / Sie', 'sie / Sie', 'ihnen / Ihnen']], ['Wer', 'Akk: wen?', 'Dat: wem?']) + '<p>Ich sehe <b>dich</b>. (wen?) · Ich helfe <b>dir</b>. (wem?)</p><p>Die Buchstaben wie beim Artikel: de<b>n</b> → ih<b>n</b>, de<b>m</b> → ih<b>m</b>.</p>',
  'Pronouns in the dative (review)',
  TB([['ich', 'mich', 'mir'], ['du', 'dich', 'dir'], ['er', 'ihn', 'ihm'], ['sie', 'sie', 'ihr'], ['wir', 'uns', 'uns'], ['ihr', 'euch', 'euch'], ['sie / Sie', 'sie / Sie', 'ihnen / Ihnen']], ['Who', 'Acc: whom?', 'Dat: to whom?']) + '<p>Ich sehe <b>dich</b>. (whom?) · Ich helfe <b>dir</b>. (to whom?)</p><p>Same letters as the article: de<b>n</b> → ih<b>n</b>, de<b>m</b> → ih<b>m</b>.</p>')
r('A2.5.3', 'dies-',
  '<p><b>dieser, diese, dieses</b> zeigt auf etwas Bestimmtes. Endungen wie bei der/die/das: dies<b>en</b> Ordner (Akk m), mit dies<b>em</b> Gerät.</p>',
  'dies-',
  '<p><b>dieser, diese, dieses</b> = “this”. Endings like der/die/das: dies<b>en</b> Ordner (acc. m), mit dies<b>em</b> Gerät.</p>')
r('A2.5.4', 'Höfliche Bitten: Könnten Sie …?',
  '<p>Höflicher als <i>Können Sie</i>: <b>Könnten Sie / Könntest du</b> … + Infinitiv am Ende.</p>' + EX('Könnten Sie bitte das Fenster schließen?'),
  'Polite requests: Könnten Sie …?',
  '<p>More polite than <i>Können Sie</i>: <b>Könnten Sie / Könntest du</b> … + infinitive at the end.</p>' + EX('Könnten Sie bitte das Fenster schließen?'))
r('A2.6.0', 'Das Verb lassen',
  '<p><b>lassen</b> + Infinitiv = „jemand anderes macht es für mich“. ich lasse, du lässt, er lässt.</p>' + EX('Ich renoviere selbst. ↔ Ich <b>lasse</b> renovieren.'),
  'The verb lassen',
  '<p><b>lassen</b> + infinitive = “to have something done by someone else”. ich lasse, du lässt, er lässt.</p>' + EX('Ich renoviere selbst. ↔ Ich <b>lasse</b> renovieren.'))
RF = TB([['ich', 'mich'], ['du', 'dich'], ['er / sie / es', 'sich'], ['wir', 'uns'], ['ihr', 'euch'], ['sie / Sie', 'sich']], ['', 'sich'])
r('A2.6.1', 'Reflexive Verben', RF + '<p>Ob man sich braucht, steht im Wörterbuch: <b>sich</b> interessieren für, aber warten auf – ohne sich.</p>',
  'Reflexive verbs', RF + '<p>The dictionary shows whether you need sich: <b>sich</b> interessieren für, but warten auf – no sich.</p>')
r('A2.6.2', 'legen / liegen, stellen / stehen',
  TB([['legen', 'Wohin? + Akk', 'liegen', 'Wo? + Dat'], ['stellen', 'Wohin? + Akk', 'stehen', 'Wo? + Dat'], ['hängen', 'Wohin? + Akk', 'hängen', 'Wo? + Dat']], ['Handlung', '', 'Ergebnis', '']) + EX('Ich stelle die Lampe <b>in die</b> Ecke. → Sie steht <b>in der</b> Ecke.'),
  'legen / liegen, stellen / stehen',
  TB([['legen', 'Wohin? + Acc', 'liegen', 'Wo? + Dat'], ['stellen', 'Wohin? + Acc', 'stehen', 'Wo? + Dat'], ['hängen', 'Wohin? + Acc', 'hängen', 'Wo? + Dat']], ['action', '', 'result', '']) + EX('Ich stelle die Lampe <b>in die</b> Ecke. → Sie steht <b>in der</b> Ecke.'))
r('A2.7.0', 'Datum (Wiederholung)',
  '<p>am + Ordnungszahl auf <b>-ten / -sten</b>: am vierundzwanzig<b>sten</b> Dezember, am erst<b>en</b> Mai.</p>',
  'Dates (review)',
  '<p>am + ordinal ending in <b>-ten / -sten</b>: am vierundzwanzig<b>sten</b> Dezember, am erst<b>en</b> Mai.</p>')
AE = '<table><tr><th></th><th>m</th><th>f</th><th>n</th></tr><tr><td>Nom</td><td>ein schön<b>er</b> Tag</td><td>eine schön<b>e</b> Feier</td><td>ein schön<b>es</b> Fest</td></tr><tr><td>Akk</td><td>einen schön<b>en</b> Tag</td><td>eine schön<b>e</b> Feier</td><td>ein schön<b>es</b> Fest</td></tr><tr><td>Dat</td><td>einem schön<b>en</b> Tag</td><td>einer schön<b>en</b> Feier</td><td>einem schön<b>en</b> Fest</td></tr></table>'
r('A2.7.1', 'Adjektiv nach ein / kein',
  '<p>Nach ein/kein/mein zeigt die Endung des Adjektivs das Genus, wenn der Artikel es nicht zeigt.</p>' + AE + EX('Was für ein Kleid? — Ein lang<b>es</b> Kleid.'),
  'Adjectives after ein / kein',
  '<p>After ein/kein/mein the adjective ending shows the gender where the article does not.</p>' + AE + EX('Was für ein Kleid? — Ein lang<b>es</b> Kleid.'))
r('A2.7.2', 'Verben mit Dativ und Akkusativ',
  '<p>Ich schenke <b>meinem Sohn</b> (wem? → Dat) <b>einen Teddybären</b> (was? → Akk).<br>Ich wünsche <b>dir / euch / Ihnen</b> alles Gute.</p>',
  'Verbs with dative and accusative',
  '<p>Ich schenke <b>meinem Sohn</b> (to whom? → dat.) <b>einen Teddybären</b> (what? → acc.).<br>Ich wünsche <b>dir / euch / Ihnen</b> alles Gute.</p>')
r('A2.8.0', 'Nebensätze mit damit',
  TB([['<b>damit</b> + Subjekt … Verb am Ende', 'Ich lerne Deutsch, damit ich in Deutschland arbeiten kann.'], ['<b>um</b> … <b>zu</b> + Infinitiv', 'Ich lerne Deutsch, um in Deutschland arbeiten zu können.']], ['Form', 'Beispiel']) + '<p>Dieselbe Person (ich lerne – ich arbeite) → beides geht. Verschiedene Personen → nur <b>damit</b>: Ich gebe dir Geld, damit <b>du</b> Essen kaufen kannst.</p><p>Bei derselben Person sagt man meist um … zu. Bei trennbaren Verben steht zu in der Mitte: um früh auf<b>zu</b>stehen.</p>',
  'Clauses with damit',
  TB([['<b>damit</b> + subject … verb at the end', 'Ich lerne Deutsch, damit ich in Deutschland arbeiten kann.'], ['<b>um</b> … <b>zu</b> + infinitive', 'Ich lerne Deutsch, um in Deutschland arbeiten zu können.']], ['Form', 'Example']) + '<p>Same person (I learn – I work) → both work. Different people → only <b>damit</b>: Ich gebe dir Geld, damit <b>du</b> Essen kaufen kannst.</p><p>With the same person Germans usually say um … zu. With separable verbs zu goes in the middle: um früh auf<b>zu</b>stehen.</p>')
VPR = [('sich ärgern über', 'Akk', 'sich über etwas aufregen', 'be annoyed about'), ('sich bewerben um', 'Akk', 'sich für eine Stelle melden', 'apply for'), ('denken an', 'Akk', 'im Kopf haben', 'think of'),
       ('sich informieren über', 'Akk', 'Informationen suchen', 'find out about'), ('sich interessieren für', 'Akk', 'Interesse haben', 'be interested in'), ('sprechen über', 'Akk', 'reden über', 'talk about'),
       ('warten auf', 'Akk', 'warten, bis etwas kommt', 'wait for'), ('sich freuen auf', 'Akk', 'etwas kommt noch', 'look forward to'), ('sich freuen über', 'Akk', 'etwas ist schon da', 'be happy about'),
       ('teilnehmen an', 'Dat', 'mitmachen', 'take part in'), ('telefonieren mit', 'Dat', 'am Telefon sprechen', 'talk on the phone with'), ('sprechen mit', 'Dat', 'reden mit', 'talk to'),
       ('träumen von', 'Dat', 'sich etwas wünschen', 'dream of'), ('sich treffen mit', 'Dat', 'sich sehen', 'meet with')]
r('A2.8.1', 'Verben mit Präpositionen (1)', TB([[f'<b>{a}</b>', b, c] for a, b, c, d in VPR], ['Verb', 'Fall', 'Bedeutung']),
  'Verbs with prepositions (1)', TB([[f'<b>{a}</b>', b.replace('Akk', 'Acc'), d] for a, b, c, d in VPR], ['Verb', 'Case', 'Meaning']))
r('A2.9.0', 'Ratschläge: sollte + Infinitiv',
  '<p><b>sollte</b> = ein freundlicher Rat. ich sollte, du solltest, er sollte, wir sollten, Sie sollten.</p>' + EX('Sie <b>sollten</b> weniger Zucker <b>essen</b>.'),
  'Advice: sollte + infinitive',
  '<p><b>sollte</b> = “should”, friendly advice. ich sollte, du solltest, er sollte, wir sollten, Sie sollten.</p>' + EX('Sie <b>sollten</b> weniger Zucker <b>essen</b>.'))
r('A2.10.0', 'Wünsche: würde gern',
  '<p><b>würde gern</b> + Infinitiv am Ende = ein Wunsch. ich würde, du würdest, er würde, wir würden.</p>' + EX('Ich <b>würde gern</b> eine Ausbildung <b>machen</b>.'),
  'Wishes: würde gern',
  '<p><b>würde gern</b> + infinitive at the end = “I would like to”. ich würde, du würdest, er würde, wir würden.</p>' + EX('Ich <b>würde gern</b> eine Ausbildung <b>machen</b>.'))
r('A2.10.1', 'Indirekte Fragen mit ob',
  '<p>Frage ohne W-Wort → <b>ob</b>. Das Verb geht ans Ende.</p>' + EX('Ist die Stelle noch frei? → Können Sie mir sagen, <b>ob</b> die Stelle noch frei <b>ist</b>?'),
  'Indirect questions with ob',
  '<p>A question without a W-word → <b>ob</b> (“whether, if”). The verb goes to the end.</p>' + EX('Ist die Stelle noch frei? → Können Sie mir sagen, <b>ob</b> die Stelle noch frei <b>ist</b>?'))
RN = TB([['Nom', 'der', 'die', 'das', 'die'], ['Akk', '<b>den</b>', 'die', 'das', 'die']], ['', 'm', 'f', 'n', 'Pl.'])
r('A2.11.0', 'Relativsätze: Nominativ und Akkusativ',
  '<p>Relativsatz: das Pronomen sieht aus wie der Artikel, das Verb steht am Ende. Das Genus kommt vom Nomen, der Fall von der Rolle im Relativsatz.</p>' + RN + EX('Das ist der Zug, <b>der</b> nach Hamburg <b>fährt</b>.', 'Das ist der Zug, <b>den</b> ich jeden Tag <b>nehme</b>.'),
  'Relative clauses: nominative and accusative',
  '<p>Relative clause (“who / which”): the pronoun looks like the article, the verb is at the end. Gender comes from the noun, case from its role in the clause.</p>' + RN + EX('Das ist der Zug, <b>der</b> nach Hamburg <b>fährt</b>.', 'Das ist der Zug, <b>den</b> ich jeden Tag <b>nehme</b>.'))
RD = TB([['Dat', '<b>dem</b>', '<b>der</b>', '<b>dem</b>', '<b>denen</b>']], ['', 'm', 'f', 'n', 'Pl.'])
r('A2.12.0', 'Relativsätze: Dativ und mit Präposition',
  RD + '<p>Braucht das Verb eine Präposition, steht sie <b>vor</b> dem Pronomen.</p>' + EX('Das ist der Nachbar, <b>dem</b> ich oft helfe.', 'Der Verein, <b>in dem</b> ich bin, ist toll.', 'Die Leute, <b>mit denen</b> ich spiele, sind nett.'),
  'Relative clauses: dative and with a preposition',
  RD + '<p>If the verb needs a preposition, it goes <b>before</b> the pronoun.</p>' + EX('Das ist der Nachbar, <b>dem</b> ich oft helfe.', 'Der Verein, <b>in dem</b> ich bin, ist toll.', 'Die Leute, <b>mit denen</b> ich spiele, sind nett.'))
WQ = [('auf', 'worauf', 'Auf wen?'), ('über', 'worüber', 'Über wen?'), ('an', 'woran', 'An wen?'), ('um', 'worum', 'Um wen?'), ('für', 'wofür', 'Für wen?'), ('von', 'wovon', 'Von wem?'), ('mit', 'womit', 'Mit wem?')]
r('A2.13.0', 'Fragen: worauf? / auf wen?',
  TB([[a, f'<b>{b}</b>', c] for a, b, c in WQ], ['Präposition', 'Sache', 'Person']) + '<p>Vor einem Vokal +r: wo<b>r</b>auf. worum (um was?) ≠ warum (aus welchem Grund?). Ort – Wo?</p>',
  'Questions: worauf? / auf wen?',
  TB([[a, f'<b>{b}</b>', c] for a, b, c in WQ], ['Preposition', 'Thing', 'Person']) + '<p>Before a vowel add r: wo<b>r</b>auf. worum (about what?) ≠ warum (why?). Place – Wo?</p>')
r('A2.13.1', 'Komposita (Wiederholung)',
  '<p>Der Artikel kommt vom <b>letzten</b> Wort: das Konto + <b>die</b> Gebühr = <b>die</b> Kontogebühr.</p>',
  'Compound nouns (review)',
  '<p>The article comes from the <b>last</b> word: das Konto + <b>die</b> Gebühr = <b>die</b> Kontogebühr.</p>')
DQ = [('auf', 'darauf', 'auf ihn / sie'), ('über', 'darüber', 'über ihn / sie'), ('an', 'daran', 'an ihn / sie'), ('um', 'darum', 'um ihn / sie'), ('für', 'dafür', 'für ihn / sie'), ('von', 'davon', 'von ihm / ihr'), ('mit', 'damit', 'mit ihm / ihr')]
r('A2.14.0', 'darüber, damit, dafür …',
  TB([[a, f'<b>{b}</b>', c] for a, b, c in DQ], ['Präposition', 'Sache schon genannt', 'Person']),
  'darüber, damit, dafür …',
  TB([[a, f'<b>{b}</b>', c] for a, b, c in DQ], ['Preposition', 'Thing already named', 'Person']))

# Corrected Russian tables (the generated ones mixed up wen/wem).
RU = {
  'A2.13.0': TB([[a, f'<b>{b}</b>', c] for a, b, c in WQ], ['Предлог', 'О предмете', 'О человеке']) + '<p>Перед гласной +r: wo<b>r</b>auf. worum (на что?) ≠ warum (почему?). Место — Wo?</p>',
  'A2.14.0': TB([[a, f'<b>{b}</b>', c] for a, b, c in DQ], ['Предлог', 'Предмет назван', 'Человек']),
}
