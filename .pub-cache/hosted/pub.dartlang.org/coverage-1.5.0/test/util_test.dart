// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:coverage/src/util.dart';
import 'package:test/test.dart';

const _failCount = 5;
const _delay = Duration(milliseconds: 10);

void main() {
  test('retry', () async {
    var count = 0;
    final stopwatch = Stopwatch()..start();

    Future failCountTimes() async {
      expect(stopwatch.elapsed, greaterThanOrEqualTo(_delay * count));

      while (count < _failCount) {
        count++;
        throw 'not yet!';
      }
      return 42;
    }

    final value = await retry(failCountTimes, _delay) as int;

    expect(value, 42);
    expect(count, _failCount);
    expect(stopwatch.elapsed, greaterThanOrEqualTo(_delay * count));
  });

  group('retry with timeout', () {
    test('if it finishes', () async {
      var count = 0;
      final stopwatch = Stopwatch()..start();

      Future failCountTimes() async {
        expect(stopwatch.elapsed, greaterThanOrEqualTo(_delay * count));

        while (count < _failCount) {
          count++;
          throw 'not yet!';
        }
        return 42;
      }

      final safeTimoutDuration = _delay * _failCount * 10;
      final value = await retry(
        failCountTimes,
        _delay,
        timeout: safeTimoutDuration,
      ) as int;

      expect(value, 42);
      expect(count, _failCount);
      expect(stopwatch.elapsed, greaterThanOrEqualTo(_delay * count));
    });

    test('if it does not finish', () async {
      var count = 0;
      final stopwatch = Stopwatch()..start();

      var caught = false;
      var countAfterError = 0;

      Future failCountTimes() async {
        if (caught) {
          countAfterError++;
        }
        expect(stopwatch.elapsed, greaterThanOrEqualTo(_delay * count));

        count++;
        throw 'never';
      }

      final unsafeTimeoutDuration = _delay * (_failCount / 2);

      try {
        await retry(failCountTimes, _delay, timeout: unsafeTimeoutDuration);
      } on StateError catch (e) {
        expect(e.message, 'Failed to complete within 25ms');
        caught = true;

        expect(countAfterError, 0,
            reason: 'Execution should stop after a timeout');

        await Future<dynamic>.delayed(_delay * 3);

        expect(countAfterError, 0, reason: 'Even after a delay');
      }

      expect(caught, isTrue);
    });
  });

  group('extractVMServiceUri', () {
    test('returns null when not found', () {
      expect(extractVMServiceUri('foo bar baz'), isNull);
    });

    test('returns null for an incorrectly formatted URI', () {
      const msg = 'Observatory listening on :://';
      expect(extractVMServiceUri(msg), null);
    });

    test('returns URI at end of string', () {
      const msg = 'Observatory listening on http://foo.bar:9999/';
      expect(extractVMServiceUri(msg), Uri.parse('http://foo.bar:9999/'));
    });

    test('returns URI with auth token at end of string', () {
      const msg = 'Observatory listening on http://foo.bar:9999/cG90YXRv/';
      expect(
          extractVMServiceUri(msg), Uri.parse('http://foo.bar:9999/cG90YXRv/'));
    });

    test('return URI embedded within string', () {
      const msg = '1985-10-26 Observatory listening on http://foo.bar:9999/ **';
      expect(extractVMServiceUri(msg), Uri.parse('http://foo.bar:9999/'));
    });

    test('return URI with auth token embedded within string', () {
      const msg =
          '1985-10-26 Observatory listening on http://foo.bar:9999/cG90YXRv/ **';
      expect(
          extractVMServiceUri(msg), Uri.parse('http://foo.bar:9999/cG90YXRv/'));
    });

    test('handles new Dart VM service message format', () {
      const msg =
          'The Dart VM service is listening on http://foo.bar:9999/cG90YXRv/';
      expect(
          extractVMServiceUri(msg), Uri.parse('http://foo.bar:9999/cG90YXRv/'));
    });
  });

  group('getIgnoredLines', () {
    const invalidSources = [
      '''final str = ''; // coverage:ignore-start
        final str = '';
        final str = ''; // coverage:ignore-start
        ''',
      '''final str = ''; // coverage:ignore-start
        final str = '';
        final str = ''; // coverage:ignore-start
        final str = ''; // coverage:ignore-end
        final str = '';
        final str = ''; // coverage:ignore-end
        ''',
      '''final str = ''; // coverage:ignore-start
        final str = '';
        final str = ''; // coverage:ignore-end
        final str = '';
        final str = ''; // coverage:ignore-end
        ''',
      '''final str = ''; // coverage:ignore-end
        final str = '';
        final str = ''; // coverage:ignore-start
        final str = '';
        final str = ''; // coverage:ignore-end
        ''',
      '''final str = ''; // coverage:ignore-end
        final str = '';
        final str = ''; // coverage:ignore-end
        ''',
      '''final str = ''; // coverage:ignore-end
        final str = '';
        final str = ''; // coverage:ignore-start
        ''',
      '''final str = ''; // coverage:ignore-end
        ''',
      '''final str = ''; // coverage:ignore-start
        ''',
    ];

    test('returns empty when the annotations are not balanced', () {
      for (final content in invalidSources) {
        expect(getIgnoredLines(content.split('\n')), isEmpty);
      }
    });

    test(
        'returns [[0,lines.length]] when the annotations are not '
        'balanced but the whole file is ignored', () {
      for (final content in invalidSources) {
        final lines = content.split('\n');
        lines.add(' // coverage:ignore-file');
        expect(getIgnoredLines(lines), [
          [0, lines.length]
        ]);
      }
    });

    test('Returns [[0,lines.length]] when the whole file is ignored', () {
      final lines = '''final str = ''; // coverage:ignore-start
      final str = ''; // coverage:ignore-end
      final str = ''; // coverage:ignore-file
      '''
          .split('\n');

      expect(getIgnoredLines(lines), [
        [0, lines.length]
      ]);
    });

    test('return the correct range of lines ignored', () {
      final lines = '''
      final str = ''; // coverage:ignore-start
      final str = ''; // coverage:ignore-line
      final str = ''; // coverage:ignore-end
      final str = ''; // coverage:ignore-start
      final str = ''; // coverage:ignore-line
      final str = ''; // coverage:ignore-end
      '''
          .split('\n');

      expect(getIgnoredLines(lines), [
        [1, 3],
        [4, 6],
      ]);
    });

    test('return the correct list of lines ignored', () {
      final lines = '''
      final str = ''; // coverage:ignore-line
      final str = ''; // coverage:ignore-line
      final str = ''; // coverage:ignore-line
      '''
          .split('\n');

      expect(getIgnoredLines(lines), [
        [1, 1],
        [2, 2],
        [3, 3],
      ]);
    });
  });
}
