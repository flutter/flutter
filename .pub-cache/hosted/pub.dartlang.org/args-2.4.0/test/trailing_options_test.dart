// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:args/args.dart';
import 'package:test/test.dart';

void main() {
  test('allowTrailingOptions defaults to true', () {
    var parser = ArgParser();
    expect(parser.allowTrailingOptions, isTrue);
  });

  group('when trailing options are allowed', () {
    late ArgParser parser;
    setUp(() {
      parser = ArgParser(allowTrailingOptions: true);
    });

    void expectThrows(List<String> args) {
      expect(() => parser.parse(args), throwsFormatException,
          reason: 'with allowTrailingOptions: true');
    }

    test('collects non-options in rest', () {
      parser.addFlag('flag');
      parser.addOption('opt', abbr: 'o');
      var results = parser.parse(['a', '--flag', 'b', '-o', 'value', 'c']);
      expect(results['flag'], isTrue);
      expect(results['opt'], equals('value'));
      expect(results.rest, equals(['a', 'b', 'c']));
    });

    test('stops parsing options at "--"', () {
      parser.addFlag('flag');
      parser.addOption('opt', abbr: 'o');
      var results = parser.parse(['a', '--flag', '--', '-ovalue', 'c']);
      expect(results['flag'], isTrue);
      expect(results.rest, equals(['a', '-ovalue', 'c']));
    });

    test('only consumes first "--"', () {
      parser.addFlag('flag', abbr: 'f');
      parser.addOption('opt', abbr: 'o');
      var results = parser.parse(['a', '--', 'b', '--', 'c']);
      expect(results.rest, equals(['a', 'b', '--', 'c']));
    });

    test('parses a trailing flag', () {
      parser.addFlag('flag');
      var results = parser.parse(['arg', '--flag']);

      expect(results['flag'], isTrue);
      expect(results.rest, equals(['arg']));
    });

    test('throws on a trailing option missing its value', () {
      parser.addOption('opt');
      expectThrows(['arg', '--opt']);
    });

    test('parses a trailing option', () {
      parser.addOption('opt');
      var results = parser.parse(['arg', '--opt', 'v']);
      expect(results['opt'], equals('v'));
      expect(results.rest, equals(['arg']));
    });

    test('throws on a trailing unknown flag', () {
      expectThrows(['arg', '--xflag']);
    });

    test('throws on a trailing unknown option and value', () {
      expectThrows(['arg', '--xopt', 'v']);
    });

    test('throws on a command', () {
      parser.addCommand('com');
      expectThrows(['arg', 'com']);
    });
  });

  test("uses the innermost command's trailing options behavior", () {
    var parser = ArgParser(allowTrailingOptions: true);
    parser.addFlag('flag', abbr: 'f');
    var command =
        parser.addCommand('cmd', ArgParser(allowTrailingOptions: false));
    command.addFlag('verbose', abbr: 'v');

    var results = parser.parse(['a', '-f', 'b']);
    expect(results['flag'], isTrue);
    expect(results.rest, equals(['a', 'b']));

    results = parser.parse(['cmd', '-f', 'a', '-v', '--unknown']);
    expect(results['flag'], isTrue); // Not trailing.
    expect(results.command!['verbose'], isFalse);
    expect(results.command!.rest, equals(['a', '-v', '--unknown']));
  });
}
