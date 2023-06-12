// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:args/args.dart';
import 'package:test/test.dart';

void main() {
  group('ArgParser.parse() is fast', () {
    test('for short flags', () {
      _testParserPerformance(ArgParser()..addFlag('short', abbr: 's'), '-s');
    });

    test('for abbreviations', () {
      _testParserPerformance(
          ArgParser()
            ..addFlag('short', abbr: 's')
            ..addFlag('short2', abbr: 't')
            ..addFlag('short3', abbr: 'u')
            ..addFlag('short4', abbr: 'v'),
          '-stuv');
    });

    test('for long flags', () {
      _testParserPerformance(ArgParser()..addFlag('long-flag'), '--long-flag');
    });

    test('for long options with =', () {
      _testParserPerformance(ArgParser()..addOption('long-option-name'),
          '--long-option-name=long-option-value');
    });
  });
}

/// Tests how quickly [parser] parses [string].
///
/// Checks that a 10x increase in arg count does not lead to greater than 30x
/// increase in parse time.
void _testParserPerformance(ArgParser parser, String string) {
  var baseSize = 50000;
  var baseList = List<String>.generate(baseSize, (_) => string);

  var multiplier = 10;
  var largeList = List<String>.generate(baseSize * multiplier, (_) => string);

  ArgResults baseAction() => parser.parse(baseList);
  ArgResults largeAction() => parser.parse(largeList);

  // Warm up JIT.
  baseAction();
  largeAction();

  var baseTime = _time(baseAction);
  var largeTime = _time(largeAction);

  print('Parsed $baseSize elements in ${baseTime}ms, '
      '${baseSize * multiplier} elements in ${largeTime}ms.');

  expect(largeTime, lessThan(baseTime * multiplier * 3),
      reason:
          'Comparing large data set time ${largeTime}ms to small data set time '
          '${baseTime}ms. Data set increased ${multiplier}x, time is allowed to '
          'increase up to ${multiplier * 3}x, but it increased '
          '${largeTime ~/ baseTime}x.');
}

int _time(void Function() function) {
  var stopwatch = Stopwatch()..start();
  function();
  return stopwatch.elapsedMilliseconds;
}
