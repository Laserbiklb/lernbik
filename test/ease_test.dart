import 'package:flutter_test/flutter_test.dart';
import 'package:lernbik/learn/data.dart';

void main() {
  test('looks English', () {
    expect(looksEnglish('Hotel', 'hotel'), isTrue);
    expect(looksEnglish('Banane', 'banana'), isTrue);
    expect(looksEnglish('Tomate', 'tomato'), isTrue);
    expect(looksEnglish('Laptop', 'laptop'), isTrue);
    expect(looksEnglish('Tisch', 'table'), isFalse);
    expect(looksEnglish('Stuhl', 'chair'), isFalse);
    expect(looksEnglish('Haus', 'house, building'), isFalse); // short words need an exact match
  });
}
