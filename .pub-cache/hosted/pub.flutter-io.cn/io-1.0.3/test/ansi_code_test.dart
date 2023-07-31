// Copyright 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
import 'dart:io';
import 'package:io/ansi.dart';
import 'package:test/test.dart';

const _ansiEscapeLiteral = '\x1B';
const _ansiEscapeForScript = '\\033';
const sampleInput = 'sample input';

void main() {
  group('ansiOutputEnabled', () {
    test('default value matches dart:io', () {
      expect(ansiOutputEnabled,
          stdout.supportsAnsiEscapes && stderr.supportsAnsiEscapes);
    });

    test('override true', () {
      overrideAnsiOutput(true, () {
        expect(ansiOutputEnabled, isTrue);
      });
    });

    test('override false', () {
      overrideAnsiOutput(false, () {
        expect(ansiOutputEnabled, isFalse);
      });
    });

    test('forScript variaents ignore `ansiOutputEnabled`', () {
      const expected =
          '$_ansiEscapeForScript[34m$sampleInput$_ansiEscapeForScript[0m';

      for (var override in [true, false]) {
        overrideAnsiOutput(override, () {
          expect(blue.escapeForScript, '$_ansiEscapeForScript[34m');
          expect(blue.wrap(sampleInput, forScript: true), expected);
          expect(wrapWith(sampleInput, [blue], forScript: true), expected);
        });
      }
    });
  });

  test('foreground and background colors match', () {
    expect(foregroundColors, hasLength(backgroundColors.length));

    for (var i = 0; i < foregroundColors.length; i++) {
      final foreground = foregroundColors[i];
      expect(foreground.type, AnsiCodeType.foreground);
      expect(foreground.name.toLowerCase(), foreground.name,
          reason: 'All names should be lower case');
      final background = backgroundColors[i];
      expect(background.type, AnsiCodeType.background);
      expect(background.name.toLowerCase(), background.name,
          reason: 'All names should be lower case');

      expect(foreground.name, background.name);

      // The last base-10 digit also matches – good to sanity check
      expect(foreground.code % 10, background.code % 10);
    }
  });

  test('all styles are styles', () {
    for (var style in styles) {
      expect(style.type, AnsiCodeType.style);
      expect(style.name.toLowerCase(), style.name,
          reason: 'All names should be lower case');
      if (style == styleBold) {
        expect(style.reset, resetBold);
      } else {
        expect(style.reset!.code, equals(style.code + 20));
      }
      expect(style.name, equals(style.reset!.name));
    }
  });

  for (var forScript in [true, false]) {
    group(forScript ? 'forScript' : 'escaped', () {
      final escapeLiteral =
          forScript ? _ansiEscapeForScript : _ansiEscapeLiteral;

      group('wrap', () {
        _test('color', () {
          final expected = '$escapeLiteral[34m$sampleInput$escapeLiteral[0m';

          expect(blue.wrap(sampleInput, forScript: forScript), expected);
        });

        _test('style', () {
          final expected = '$escapeLiteral[1m$sampleInput$escapeLiteral[22m';

          expect(styleBold.wrap(sampleInput, forScript: forScript), expected);
        });

        _test('style', () {
          final expected = '$escapeLiteral[34m$sampleInput$escapeLiteral[0m';

          expect(blue.wrap(sampleInput, forScript: forScript), expected);
        });

        test('empty', () {
          expect(blue.wrap('', forScript: forScript), '');
        });

        test(null, () {
          expect(blue.wrap(null, forScript: forScript), isNull);
        });
      });

      group('wrapWith', () {
        _test('foreground', () {
          final expected = '$escapeLiteral[34m$sampleInput$escapeLiteral[0m';

          expect(wrapWith(sampleInput, [blue], forScript: forScript), expected);
        });

        _test('background', () {
          final expected = '$escapeLiteral[44m$sampleInput$escapeLiteral[0m';

          expect(wrapWith(sampleInput, [backgroundBlue], forScript: forScript),
              expected);
        });

        _test('style', () {
          final expected = '$escapeLiteral[1m$sampleInput$escapeLiteral[0m';

          expect(wrapWith(sampleInput, [styleBold], forScript: forScript),
              expected);
        });

        _test('2 styles', () {
          final expected = '$escapeLiteral[1;3m$sampleInput$escapeLiteral[0m';

          expect(
              wrapWith(sampleInput, [styleBold, styleItalic],
                  forScript: forScript),
              expected);
        });

        _test('2 foregrounds', () {
          expect(
              () => wrapWith(sampleInput, [blue, white], forScript: forScript),
              throwsArgumentError);
        });

        _test('multi', () {
          final expected =
              '$escapeLiteral[1;4;34;107m$sampleInput$escapeLiteral[0m';

          expect(
              wrapWith(sampleInput,
                  [blue, backgroundWhite, styleBold, styleUnderlined],
                  forScript: forScript),
              expected);
        });

        test('no codes', () {
          expect(wrapWith(sampleInput, []), sampleInput);
        });

        _test('empty', () {
          expect(
              wrapWith('', [blue, backgroundWhite, styleBold],
                  forScript: forScript),
              '');
        });

        _test('null', () {
          expect(
              wrapWith(null, [blue, backgroundWhite, styleBold],
                  forScript: forScript),
              isNull);
        });
      });
    });
  }
}

void _test<T>(String name, T Function() body) =>
    test(name, () => overrideAnsiOutput<T>(true, body));
