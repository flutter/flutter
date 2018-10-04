// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_tools/src/base/utils.dart';
import 'package:flutter_tools/src/base/version.dart';

import 'src/common.dart';

void main() {
  group('SettingsFile', () {
    test('parse', () {
      final SettingsFile file = SettingsFile.parse('''
# ignore comment
foo=bar
baz=qux
''');
      expect(file.values['foo'], 'bar');
      expect(file.values['baz'], 'qux');
      expect(file.values, hasLength(2));
    });
  });

  group('uuid', () {
    // xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx
    test('simple', () {
      final Uuid uuid = Uuid();
      final String result = uuid.generateV4();
      expect(result.length, 36);
      expect(result[8], '-');
      expect(result[13], '-');
      expect(result[18], '-');
      expect(result[23], '-');
    });

    test('can parse', () {
      final Uuid uuid = Uuid();
      final String result = uuid.generateV4();
      expect(int.parse(result.substring(0, 8), radix: 16), isNotNull);
      expect(int.parse(result.substring(9, 13), radix: 16), isNotNull);
      expect(int.parse(result.substring(14, 18), radix: 16), isNotNull);
      expect(int.parse(result.substring(19, 23), radix: 16), isNotNull);
      expect(int.parse(result.substring(24, 36), radix: 16), isNotNull);
    });

    test('special bits', () {
      final Uuid uuid = Uuid();
      String result = uuid.generateV4();
      expect(result[14], '4');
      expect(result[19].toLowerCase(), isIn('89ab'));

      result = uuid.generateV4();
      expect(result[19].toLowerCase(), isIn('89ab'));

      result = uuid.generateV4();
      expect(result[19].toLowerCase(), isIn('89ab'));
    });

    test('is pretty random', () {
      final Set<String> set = Set<String>();

      Uuid uuid = Uuid();
      for (int i = 0; i < 64; i++) {
        final String val = uuid.generateV4();
        expect(set, isNot(contains(val)));
        set.add(val);
      }

      uuid = Uuid();
      for (int i = 0; i < 64; i++) {
        final String val = uuid.generateV4();
        expect(set, isNot(contains(val)));
        set.add(val);
      }

      uuid = Uuid();
      for (int i = 0; i < 64; i++) {
        final String val = uuid.generateV4();
        expect(set, isNot(contains(val)));
        set.add(val);
      }
    });
  });

  group('Version', () {
    test('can parse and compare', () {
      expect(Version.unknown.toString(), equals('unknown'));
      expect(Version(null, null, null).toString(), equals('0'));

      final Version v1 = Version.parse('1');
      expect(v1.major, equals(1));
      expect(v1.minor, equals(0));
      expect(v1.patch, equals(0));

      expect(v1, greaterThan(Version.unknown));

      final Version v2 = Version.parse('1.2');
      expect(v2.major, equals(1));
      expect(v2.minor, equals(2));
      expect(v2.patch, equals(0));

      final Version v3 = Version.parse('1.2.3');
      expect(v3.major, equals(1));
      expect(v3.minor, equals(2));
      expect(v3.patch, equals(3));

      final Version v4 = Version.parse('1.12');
      expect(v4, greaterThan(v2));

      expect(v3, greaterThan(v2));
      expect(v2, greaterThan(v1));

      final Version v5 = Version(1, 2, 0, text: 'foo');
      expect(v5, equals(v2));

      expect(Version.parse('Preview2.2'), isNull);
    });
  });

  group('Poller', () {
    const Duration kShortDelay = Duration(milliseconds: 100);

    Poller poller;

    tearDown(() {
      poller?.cancel();
    });

    test('fires at start', () async {
      bool called = false;
      poller = Poller(() async {
        called = true;
      }, const Duration(seconds: 1));
      expect(called, false);
      await Future<void>.delayed(kShortDelay);
      expect(called, true);
    });

    test('runs periodically', () async {
      // Ensure we get the first (no-delay) callback, and one of the periodic callbacks.
      int callCount = 0;
      poller = Poller(() async {
        callCount++;
      }, Duration(milliseconds: kShortDelay.inMilliseconds ~/ 2));
      expect(callCount, 0);
      await Future<void>.delayed(kShortDelay);
      expect(callCount, greaterThanOrEqualTo(2));
    });

    test('no quicker then the periodic delay', () async {
      // Make sure that the poller polls at delay + the time it took to run the callback.
      final Completer<Duration> completer = Completer<Duration>();
      DateTime firstTime;
      poller = Poller(() async {
        if (firstTime == null)
          firstTime = DateTime.now();
        else
          completer.complete(DateTime.now().difference(firstTime));

        // introduce a delay
        await Future<void>.delayed(kShortDelay);
      }, kShortDelay);
      final Duration duration = await completer.future;
      expect(duration, greaterThanOrEqualTo(Duration(milliseconds: kShortDelay.inMilliseconds * 2)));
    });
  });

  group('Misc', () {
    test('snakeCase', () async {
      expect(snakeCase('abc'), equals('abc'));
      expect(snakeCase('abC'), equals('ab_c'));
      expect(snakeCase('aBc'), equals('a_bc'));
      expect(snakeCase('aBC'), equals('a_b_c'));
      expect(snakeCase('Abc'), equals('abc'));
      expect(snakeCase('AbC'), equals('ab_c'));
      expect(snakeCase('ABc'), equals('a_bc'));
      expect(snakeCase('ABC'), equals('a_b_c'));
    });
  });
}
