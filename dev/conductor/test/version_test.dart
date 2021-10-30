// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:conductor/version.dart';

import './common.dart';

void main() {
  group('Version.increment()', () {
    test('throws exception on nonsensical `level`', () {
      final List<String> levels = <String>['f', '0', 'xyz'];
      for (final String level in levels) {
        final Version version = Version.fromString('1.0.0-0.0.pre');
        expect(
          () => Version.increment(version, level).toString(),
          throwsExceptionWith('Unknown increment level $level.'),
        );
      }
    });

    test('does not support incrementing x', () {
      const String level = 'x';

      final Version version = Version.fromString('1.0.0-0.0.pre');
      expect(
        () => Version.increment(version, level).toString(),
        throwsExceptionWith(
            'Incrementing $level is not supported by this tool'),
      );
    });

    test('successfully increments y', () {
      const String level = 'y';

      Version version = Version.fromString('1.0.0-0.0.pre');
      expect(Version.increment(version, level).toString(), '1.1.0-0.0.pre');

      version = Version.fromString('10.20.0-40.50.pre');
      expect(Version.increment(version, level).toString(), '10.21.0-0.0.pre');

      version = Version.fromString('1.18.0-3.0.pre');
      expect(Version.increment(version, level).toString(), '1.19.0-0.0.pre');
    });

    test('successfully increments z', () {
      const String level = 'z';

      Version version = Version.fromString('1.0.0');
      expect(Version.increment(version, level).toString(), '1.0.1');

      version = Version.fromString('10.20.0');
      expect(Version.increment(version, level).toString(), '10.20.1');

      version = Version.fromString('1.18.3');
      expect(Version.increment(version, level).toString(), '1.18.4');
    });

    test('does not support incrementing m', () {
      const String level = 'm';

      final Version version = Version.fromString('1.0.0-0.0.pre');
      expect(
        () => Version.increment(version, level).toString(),
        throwsAssertionWith("Do not increment 'm' via Version.increment"),
      );
    });

    test('successfully increments n', () {
      const String level = 'n';

      Version version = Version.fromString('1.0.0-0.0.pre');
      expect(Version.increment(version, level).toString(), '1.0.0-0.1.pre');

      version = Version.fromString('10.20.0-40.50.pre');
      expect(Version.increment(version, level).toString(), '10.20.0-40.51.pre');

      version = Version.fromString('1.18.0-3.0.pre');
      expect(Version.increment(version, level).toString(), '1.18.0-3.1.pre');
    });
  }, onPlatform: <String, dynamic>{
    'windows': const Skip('Flutter Conductor only supported on macos/linux'),
  });
}
