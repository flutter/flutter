import 'package:source_helper/source_helper.dart';
import 'package:test/test.dart';

const _kebabItems = {
  'simple': 'simple',
  'twoWords': 'two-words',
  'FirstBig': 'first-big'
};

const _pascalItems = {
  'simple': 'Simple',
  'twoWords': 'TwoWords',
  'FirstBig': 'FirstBig'
};

const _snakeItems = {
  'simple': 'simple',
  'twoWords': 'two_words',
  'FirstBig': 'first_big',
};

void main() {
  group('kebab', () {
    for (final entry in _kebabItems.entries) {
      test('"${entry.key}"', () {
        expect(entry.key.kebab, entry.value);
      });
    }
  });

  group('pascal', () {
    for (final entry in _pascalItems.entries) {
      test('"${entry.key}"', () {
        expect(entry.key.pascal, entry.value);
      });
    }
  });

  group('snake', () {
    for (final entry in _snakeItems.entries) {
      test('"${entry.key}"', () {
        expect(entry.key.snake, entry.value);
      });
    }
  });

  group('nonPrivateName', () {
    test('removes leading underscores', () {
      expect('__hello__world__'.nonPrivate, equals('hello__world__'));
    });
    test('does not changes public names', () {
      expect('HelloWorld'.nonPrivate, equals('HelloWorld'));
    });
  });
}
