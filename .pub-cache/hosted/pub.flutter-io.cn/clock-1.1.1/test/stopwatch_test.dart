// Copyright 2018 Google Inc. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the 'License');
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an 'AS IS' BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'package:clock/clock.dart';

import 'package:test/test.dart';

import 'utils.dart';

void main() {
  test('returns the system frequency', () {
    expect(fixed(1990, 11, 8).stopwatch().frequency,
        equals(Stopwatch().frequency));
  });

  group('before it starts', () {
    late Stopwatch stopwatch;
    setUp(() {
      stopwatch = clock.stopwatch();
    });

    test('is not running', () => expect(stopwatch.isRunning, isFalse));

    test('stop() does nothing', () {
      stopwatch.stop();
      expect(stopwatch.isRunning, isFalse);
      expect(stopwatch.elapsed, equals(Duration.zero));
    });

    group('reports no elapsed', () {
      test('duration', () => expect(stopwatch.elapsed, equals(Duration.zero)));
      test('ticks', () => expect(stopwatch.elapsedTicks, isZero));
      test('microseconds', () => expect(stopwatch.elapsedMicroseconds, isZero));
      test('milliseconds', () => expect(stopwatch.elapsedMilliseconds, isZero));
    });
  });

  group('when 12345μs have elapsed', () {
    late DateTime time;
    late Clock clock;
    late Stopwatch stopwatch;
    setUp(() {
      time = date(1990, 11, 8);
      clock = Clock(() => time);
      stopwatch = clock.stopwatch()..start();
      time = clock.microsFromNow(12345);
    });

    group('and the stopwatch is active', () {
      test('is running', () {
        expect(stopwatch.isRunning, isTrue);
      });

      test('reports more elapsed time', () {
        time = clock.microsFromNow(54321);
        expect(stopwatch.elapsedMicroseconds, equals(66666));
      });

      test('start does nothing', () {
        stopwatch.start();
        expect(stopwatch.isRunning, isTrue);
        expect(stopwatch.elapsedMicroseconds, equals(12345));
      });

      group('reset()', () {
        setUp(() {
          stopwatch.reset();
        });

        test('sets the elapsed time to zero', () {
          expect(stopwatch.elapsed, equals(Duration.zero));
        });

        test('reports more elapsed time', () {
          time = clock.microsFromNow(54321);
          expect(stopwatch.elapsedMicroseconds, equals(54321));
        });
      });

      group('reports elapsed', () {
        test('duration', () {
          expect(
              stopwatch.elapsed, equals(const Duration(microseconds: 12345)));
        });

        test('ticks', () {
          expect(stopwatch.elapsedTicks,
              equals((Stopwatch().frequency * 12345) ~/ 1000000));
        });

        test('microseconds', () {
          expect(stopwatch.elapsedMicroseconds, equals(12345));
        });

        test('milliseconds', () {
          expect(stopwatch.elapsedMilliseconds, equals(12));
        });
      });
    });

    group('and the stopwatch is inactive, reports that as', () {
      setUp(() {
        stopwatch.stop();
      });

      test('is not running', () {
        expect(stopwatch.isRunning, isFalse);
      });

      test("doesn't report more elapsed time", () {
        time = clock.microsFromNow(54321);
        expect(stopwatch.elapsedMicroseconds, equals(12345));
      });

      test('start starts reporting more elapsed time', () {
        stopwatch.start();
        expect(stopwatch.isRunning, isTrue);
        time = clock.microsFromNow(54321);
        expect(stopwatch.elapsedMicroseconds, equals(66666));
      });

      group('reset()', () {
        setUp(() {
          stopwatch.reset();
        });

        test('sets the elapsed time to zero', () {
          expect(stopwatch.elapsed, equals(Duration.zero));
        });

        test("doesn't report more elapsed time", () {
          time = clock.microsFromNow(54321);
          expect(stopwatch.elapsed, equals(Duration.zero));
        });
      });

      group('reports elapsed', () {
        test('duration', () {
          expect(
              stopwatch.elapsed, equals(const Duration(microseconds: 12345)));
        });

        test('ticks', () {
          expect(stopwatch.elapsedTicks,
              equals((Stopwatch().frequency * 12345) ~/ 1000000));
        });

        test('microseconds', () {
          expect(stopwatch.elapsedMicroseconds, equals(12345));
        });

        test('milliseconds', () {
          expect(stopwatch.elapsedMilliseconds, equals(12));
        });
      });
    });
  }, onPlatform: {
    'js': const Skip('Web does not have enough precision'),
  });
}
