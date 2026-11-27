/// Cuts a German word or phrase into pieces of about three letters, along syllables where possible
/// ("Kran·ken·haus"). Each word's last piece keeps the space after it, so joining the pieces gives
/// the phrase back exactly.
List<String> pieces(String phrase) {
  final words = phrase.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
  final out = <String>[];
  for (var i = 0; i < words.length; i++) {
    final ps = _wordPieces(words[i]);
    if (i < words.length - 1) ps[ps.length - 1] = '${ps.last} ';
    out.addAll(ps);
  }
  return out;
}

const _vowels = 'aeiouyäöüAEIOUYÄÖÜ';
bool _isV(String c) => _vowels.contains(c);

// Letter groups that are never split.
const _keep = ['sch', 'ch', 'ck', 'ph', 'th', 'qu'];
// Two vowels read as one sound.
const _diph = ['ei', 'ie', 'au', 'eu', 'äu', 'ai', 'aa', 'ee', 'oo'];

List<String> _wordPieces(String w) {
  // Hyphenated words and punctuation: cut there first.
  final m = RegExp(r'^(.*?[-/])(.+)$').firstMatch(w);
  if (m != null && m.group(1)!.length > 1) return [..._wordPieces(m.group(1)!), ..._wordPieces(m.group(2)!)];
  final syl = _syllables(w);
  // Glue tiny bits to a neighbour, cut long one-syllable bits before the vowel.
  final merged = <String>[];
  for (final s in syl) {
    if (merged.isNotEmpty && (_letters(s) <= 1 || _letters(merged.last) <= 1)) {
      merged[merged.length - 1] += s;
    } else {
      merged.add(s);
    }
  }
  final out = <String>[];
  for (final s in merged) {
    out.addAll(_letters(s) >= 5 ? _splitLong(s) : [s]);
  }
  return out;
}

int _letters(String s) => s.replaceAll(RegExp(r'[^A-Za-zÄÖÜäöüß]'), '').length;

/// "Schrank" → "Schr", "ank"; "Bahnhof" stays split by syllables before this.
List<String> _splitLong(String s) {
  final i = s.split('').indexWhere(_isV);
  if (i >= 2 && s.length - i >= 3) return [s.substring(0, i), s.substring(i)];
  // Vowel at the start or no good place: cut after about three letters.
  if (s.length >= 6) return [s.substring(0, 3), ..._splitLong(s.substring(3))];
  return [s];
}

List<String> _syllables(String w) {
  final lower = w.toLowerCase();
  // Vowel groups (nuclei): [start, end) indices.
  final nuc = <(int, int)>[];
  var i = 0;
  while (i < w.length) {
    if (_isV(w[i])) {
      var j = i + 1;
      if (j < w.length && _diph.contains(lower.substring(i, j + 1))) j++;
      nuc.add((i, j));
      i = j;
    } else {
      i++;
    }
  }
  if (nuc.length < 2) return [w];
  final cuts = <int>[];
  for (var k = 0; k < nuc.length - 1; k++) {
    final a = nuc[k].$2, b = nuc[k + 1].$1; // consonants between: [a, b)
    final cons = lower.substring(a, b);
    if (cons.isEmpty) {
      cuts.add(a);
      continue;
    }
    // The last consonant (or unsplittable group) starts the next syllable; "sch" always does.
    var start = b - 1;
    final sch = cons.indexOf('sch');
    if (sch >= 0) {
      cuts.add(a + sch);
      continue;
    }
    for (final g in _keep) {
      if (cons.endsWith(g) && cons.length >= g.length) {
        start = b - g.length;
        break;
      }
    }
    if (cons.length == 1) start = a;
    cuts.add(start);
  }
  final out = <String>[];
  var from = 0;
  for (final c in cuts) {
    if (c > from) {
      out.add(w.substring(from, c));
      from = c;
    }
  }
  out.add(w.substring(from));
  return out;
}
