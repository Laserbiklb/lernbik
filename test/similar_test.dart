import 'package:flutter_test/flutter_test.dart';
import 'package:lernbik/learn/data.dart';
import 'package:lernbik/learn/progress.dart';

Word w(String a, String d, String ru, [String? en]) => Word(a, d, ru, 'A1 · 1', en: en);

void main() {
  test('similar words', () {
    expect(similarWords(w('der', 'Lehrer', 'учитель'), w('die', 'Lehrerin', 'учительница')), isTrue);
    expect(similarWords(w('die', 'Tasche', 'сумка'), w('die', 'Tasse', 'чашка')), isTrue);
    expect(similarWords(w('der', 'Kindergarten', 'детский сад'), w('das', 'Kinderzimmer', 'детская')), isTrue);
    expect(similarWords(w('das', 'Haus', 'дом'), w('die', 'Hausaufgabe', 'домашнее задание')), isTrue);
    expect(similarWords(w('der', 'Kugelschreiber', 'ручка', 'pen'), w('der', 'Kuli', 'ручка', 'pen')), isTrue);
    expect(similarWords(w('der', 'Tisch', 'стол'), w('der', 'Stuhl', 'стул')), isFalse);
    expect(similarWords(w('der', 'Apfel', 'яблоко'), w('die', 'Banane', 'банан')), isFalse);
    expect(similarWords(w('', 'gehen', 'идти'), w('', 'sehen', 'видеть')), isTrue); // one letter apart
    expect(similarWords(w('', 'kaufen', 'покупать'), w('', 'laufen', 'бегать')), isTrue);
    expect(similarWords(w('', 'essen', 'есть'), w('', 'trinken', 'пить')), isFalse);
    expect(similarWords(w('der', 'Heimwerkerkurs', 'курс ремонта'), w('der', 'Schauspielkurs', 'курс актёров')), isTrue);
    expect(similarWords(w('der', 'Erste-Hilfe-Kurs', 'курс первой помощи'), w('der', 'Tanzkurs', 'курс танцев')), isTrue);
    expect(similarWords(w('das', 'Kinderzimmer', 'детская'), w('das', 'Wohnzimmer', 'гостиная')), isTrue);
    expect(similarWords(w('die', 'Rechnung', 'счёт'), w('die', 'Wohnung', 'квартира')), isFalse);
    expect(similarWords(w('die', 'Zeitung', 'газета'), w('die', 'Rechnung', 'счёт')), isFalse);
  });

  test('round: look-alikes apart, but always full', () {
    final p = Progress();
    final kurse = [for (final x in ['Tanz', 'Koch', 'Nähkurs', 'Sprach', 'Yoga', 'Schwimm']) w('der', x.endsWith('kurs') ? x : '${x}kurs', 'курс $x')];
    final other = [for (final x in ['Tisch', 'Lampe', 'Brot', 'Apfel', 'Garten', 'Fenster', 'Milch', 'Hund']) w('der', x, 'слово $x')];
    // Plenty of other words: one -kurs per round.
    final r1 = p.pickBatch([...kurse, ...other], 8, 'new');
    expect(r1.length, 8);
    expect(r1.where((x) => x.d.endsWith('kurs')).length, 1);
    // Only look-alikes left: the round is still full.
    final r2 = p.pickBatch(kurse, 6, 'new');
    expect(r2.length, 6);
  });
}
