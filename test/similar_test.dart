import 'package:flutter_test/flutter_test.dart';
import 'package:lernbik/learn/data.dart';

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
}
