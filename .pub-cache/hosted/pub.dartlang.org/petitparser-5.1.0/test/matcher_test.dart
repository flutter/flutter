import 'package:petitparser/petitparser.dart';
import 'package:test/test.dart';

void main() {
  test('parse()', () {
    final parser = char('a');
    expect(parser.parse('a').isSuccess, isTrue);
    expect(parser.parse('b').isSuccess, isFalse);
  });
  test('accept()', () {
    final parser = char('a');
    expect(parser.accept('a'), isTrue);
    expect(parser.accept('b'), isFalse);
  });
  group('matches', () {
    const input = 'a123b456';
    final parser = digit().repeat(2, 2).flatten();
    test('matches()', () {
      // ignore: deprecated_member_use_from_same_package
      expect(parser.matches(input), ['12', '23', '45', '56']);
    });
    test('matchesSkipping()', () {
      // ignore: deprecated_member_use_from_same_package
      expect(parser.matchesSkipping(input), ['12', '45']);
    });
    group('allMatches', () {
      final parser = digit().seq(digit()).flatten();
      test('allMatches()', () {
        expect(parser.allMatches(input), ['12', '45']);
      });
      test('allMatches(start: 3)', () {
        expect(parser.allMatches(input, start: 3), ['45']);
      });
      test('allMatches(overlapping: true)', () {
        expect(parser.allMatches(input, overlapping: true),
            ['12', '23', '45', '56']);
      });
      test('allMatches(start: 3, overlapping: true)', () {
        expect(parser.allMatches(input, start: 3, overlapping: true),
            ['45', '56']);
      });
    });
  });
  group('pattern', () {
    const input = 'a123b45';
    final pattern = digit().seq(digit()).toPattern();
    test('allMatches()', () {
      final matches = pattern.allMatches(input);
      expect(matches.map((matcher) => matcher.pattern), [pattern, pattern]);
      expect(matches.map((matcher) => matcher.input), [input, input]);
      expect(matches.map((matcher) => matcher.start), [1, 5]);
      expect(matches.map((matcher) => matcher.end), [3, 7]);
      expect(matches.map((matcher) => matcher.groupCount), [0, 0]);
      expect(matches.map((matcher) => matcher[0]), ['12', '45']);
      expect(matches.map((matcher) => matcher.group(0)), ['12', '45']);
      expect(matches.map((matcher) => matcher.groups([0, 1])), [
        ['12', null],
        ['45', null],
      ]);
    });
    test('allMatches() (empty match)', () {
      final pattern = digit().star().toPattern();
      final matches = pattern.allMatches(input);
      expect(matches.map((matcher) => matcher[0]), ['', '123', '', '45', '']);
    });
    test('matchAsPrefix()', () {
      final match1 = pattern.matchAsPrefix(input);
      expect(match1, isNull);
      final match2 = pattern.matchAsPrefix(input, 2)!;
      expect(match2.pattern, pattern);
      expect(match2.input, input);
      expect(match2.start, 2);
      expect(match2.end, 4);
      expect(match2.groupCount, 0);
      expect(match2[0], '23');
      expect(match2.group(0), '23');
      expect(match2.groups([0, 1]), ['23', null]);
    });
    test('startsWith()', () {
      expect(input.startsWith(pattern), isFalse);
      expect(input.startsWith(pattern, 1), isTrue);
      expect(input.startsWith(pattern, 2), isTrue);
      expect(input.startsWith(pattern, 3), isFalse);
    });
    test('indexOf()', () {
      expect(input.indexOf(pattern), 1);
      expect(input.indexOf(pattern), 1);
      expect(input.indexOf(pattern, 1), 1);
      expect(input.indexOf(pattern, 2), 2);
      expect(input.indexOf(pattern, 3), 5);
    });
    test('lastIndexOf()', () {
      expect(input.lastIndexOf(pattern), 5);
      expect(input.lastIndexOf(pattern, 0), -1);
      expect(input.lastIndexOf(pattern, 1), 1);
      expect(input.lastIndexOf(pattern, 2), 2);
      expect(input.lastIndexOf(pattern, 3), 2);
    });
    test('contains()', () {
      expect(input.contains(pattern), isTrue);
    });
    test('replaceFirst()', () {
      expect(input.replaceFirst(pattern, '!'), 'a!3b45');
    });
    test('replaceFirstMapped()', () {
      expect(input.replaceFirstMapped(pattern, (match) => '!${match[0]}!'),
          'a!12!3b45');
    });
    test('replaceAll()', () {
      expect(input.replaceAll(pattern, '!'), 'a!3b!');
    }, onPlatform: {
      'js': const Skip('String.replaceAll(Pattern) UNIMPLEMENTED')
    });
    test('replaceAllMapped()', () {
      expect(input.replaceAllMapped(pattern, (match) => '!${match[0]}!'),
          'a!12!3b!45!');
    });
    test('split()', () {
      expect(input.split(pattern), ['a', '3b', '']);
    });
    test('splitMapJoin()', () {
      expect(
          input.splitMapJoin(pattern,
              onMatch: (match) => '!${match[0]}!',
              onNonMatch: (nonMatch) => '?$nonMatch?'),
          '?a?!12!?3b?!45!??');
    });
  });
}
