import 'package:petitparser/parser.dart';
import 'package:petitparser/reflection.dart';
import 'package:test/test.dart';

/// Shared invariants for all parsers.
void expectParserInvariants<T>(Parser<T> parser) {
  test('copy', () {
    final copy = parser.copy();
    expect(copy, isNot(same(parser)));
    expect(copy.toString(), parser.toString());
    expect(copy.runtimeType, parser.runtimeType);
    expect(copy.children,
        pairwiseCompare(parser.children, identical, 'same children'));
  });
  test('transform', () {
    final copy = transformParser(parser, <T>(parser) => parser);
    expect(copy, isNot(same(parser)));
    expect(copy.toString(), parser.toString());
    expect(copy.runtimeType, parser.runtimeType);
    expect(
        copy.children,
        pairwiseCompare(parser.children, (parser, copy) {
          expect(copy, isNot(same(parser)));
          expect(copy.toString(), parser.toString());
          expect(copy.runtimeType, parser.runtimeType);
          return true;
        }, 'same children'));
  });
  test('isEqualTo', () {
    final copy = parser.copy();
    expect(copy.isEqualTo(copy), isTrue);
    expect(parser.isEqualTo(parser), isTrue);
    expect(copy.isEqualTo(parser), isTrue);
    expect(parser.isEqualTo(copy), isTrue);
  });
  test('replace', () {
    final copy = parser.copy();
    final replaced = <Parser>[];
    for (var i = 0; i < copy.children.length; i++) {
      final source = copy.children[i];
      final target = source.copy();
      expect(source, isNot(same(target)));
      copy.replace(source, target);
      expect(copy.children[i], same(target));
      replaced.add(target);
    }
    expect(copy.children,
        pairwiseCompare(replaced, identical, 'replaced children'));
  });
  test('toString', () {
    expect(parser.toString(),
        stringContainsInOrder([parser.runtimeType.toString()]));
  });
}
