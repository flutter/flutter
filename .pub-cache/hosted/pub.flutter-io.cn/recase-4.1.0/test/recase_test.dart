import 'package:test/test.dart';

import 'package:recase/recase.dart';

void main() {
  String mockText = 'This is-Some_sampleText. YouDig?';
  ReCase rcInput = ReCase(mockText);
  ReCase allCapsInput = ReCase('FOO_BAR');

  group('snake_case', () {
    test('from empty string.', () {
      expect(''.snakeCase, equals(''));
    });

    test('from "${rcInput.originalText}".', () {
      expect(rcInput.snakeCase, equals('this_is_some_sample_text_you_dig?'));
    });

    test('from "${allCapsInput.originalText}".', () {
      expect(allCapsInput.snakeCase, equals('foo_bar'));
    });

    test('from "${mockText}", using String extension.', () {
      expect(mockText.snakeCase, equals('this_is_some_sample_text_you_dig?'));
    });
  });

  group('dot.case', () {
    test('from empty string.', () {
      expect(''.dotCase, equals(''));
    });

    test('from "${rcInput.originalText}".', () {
      expect(rcInput.dotCase, equals('this.is.some.sample.text.you.dig?'));
    });

    test('from "${allCapsInput.originalText}".', () {
      expect(allCapsInput.dotCase, equals('foo.bar'));
    });

    test('from "${mockText}", using String extension.', () {
      expect(mockText.dotCase, equals('this.is.some.sample.text.you.dig?'));
    });
  });

  group('path/case', () {
    test('from empty string.', () {
      expect(''.pathCase, equals(''));
    });

    test('from "${rcInput.originalText}".', () {
      expect(rcInput.pathCase, equals('this/is/some/sample/text/you/dig?'));
    });

    test('from "${allCapsInput.originalText}".', () {
      expect(allCapsInput.pathCase, equals('foo/bar'));
    });

    test('from "${mockText}", using String extension.', () {
      expect(mockText.pathCase, equals('this/is/some/sample/text/you/dig?'));
    });
  });

  group('param-case', () {
    test('from empty string.', () {
      expect(''.paramCase, equals(''));
    });

    test('from "${rcInput.originalText}".', () {
      expect(rcInput.paramCase, equals('this-is-some-sample-text-you-dig?'));
    });

    test('from "${allCapsInput.originalText}".', () {
      expect(allCapsInput.paramCase, equals('foo-bar'));
    });

    test('from "${mockText}", using String extension.', () {
      expect(mockText.paramCase, equals('this-is-some-sample-text-you-dig?'));
    });
  });

  group('PascalCase', () {
    test('from empty string.', () {
      expect(''.pascalCase, equals(''));
    });

    test('from "${rcInput.originalText}".', () {
      expect(rcInput.pascalCase, equals('ThisIsSomeSampleTextYouDig?'));
    });

    test('from "${allCapsInput.originalText}".', () {
      expect(allCapsInput.pascalCase, equals('FooBar'));
    });

    test('from "${mockText}", using String extension.', () {
      expect(mockText.pascalCase, equals('ThisIsSomeSampleTextYouDig?'));
    });
  });

  group('Header-Case', () {
    test('from empty string.', () {
      expect(''.headerCase, equals(''));
    });

    test('from "${rcInput.originalText}".', () {
      expect(rcInput.headerCase, equals('This-Is-Some-Sample-Text-You-Dig?'));
    });

    test('from "${allCapsInput.originalText}".', () {
      expect(allCapsInput.headerCase, equals('Foo-Bar'));
    });

    test('from "${mockText}", using String extension.', () {
      expect(mockText.headerCase, equals('This-Is-Some-Sample-Text-You-Dig?'));
    });
  });

  group('Title Case', () {
    test('from empty string.', () {
      expect(''.titleCase, equals(''));
    });

    test('from "${rcInput.originalText}".', () {
      expect(rcInput.titleCase, equals('This Is Some Sample Text You Dig?'));
    });

    test('from "${allCapsInput.originalText}".', () {
      expect(allCapsInput.titleCase, equals('Foo Bar'));
    });

    test('from "${mockText}", using String extension.', () {
      expect(mockText.titleCase, equals('This Is Some Sample Text You Dig?'));
    });
  });

  group('camelCase', () {
    test('from empty string.', () {
      expect(''.camelCase, equals(''));
    });

    test('from "${rcInput.originalText}".', () {
      expect(rcInput.camelCase, equals('thisIsSomeSampleTextYouDig?'));
    });

    test('from "${allCapsInput.originalText}".', () {
      expect(allCapsInput.camelCase, equals('fooBar'));
    });

    test('from "${mockText}", using String extension.', () {
      expect(mockText.camelCase, equals('thisIsSomeSampleTextYouDig?'));
    });
  });

  group('Sentence case', () {
    test('from empty string.', () {
      expect(''.sentenceCase, equals(''));
    });

    test('from "${rcInput.originalText}".', () {
      expect(rcInput.sentenceCase, equals('This is some sample text you dig?'));
    });

    test('from "${allCapsInput.originalText}".', () {
      expect(allCapsInput.sentenceCase, equals('Foo bar'));
    });

    test('from "${mockText}", using String extension.', () {
      expect(
          mockText.sentenceCase, equals('This is some sample text you dig?'));
    });
  });

  group('CONSTANT_CASE', () {
    test('from empty string.', () {
      expect(''.constantCase, equals(''));
    });

    test('from "${rcInput.originalText}".', () {
      expect(rcInput.constantCase, equals('THIS_IS_SOME_SAMPLE_TEXT_YOU_DIG?'));
    });

    test('from "${allCapsInput.originalText}".', () {
      expect(allCapsInput.constantCase, equals('FOO_BAR'));
    });

    test('from "${mockText}", using String extension.', () {
      expect(
          mockText.constantCase, equals('THIS_IS_SOME_SAMPLE_TEXT_YOU_DIG?'));
    });
  });
}
