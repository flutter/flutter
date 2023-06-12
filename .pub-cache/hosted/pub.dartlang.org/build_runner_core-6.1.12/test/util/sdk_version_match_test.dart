// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import 'package:build_runner_core/src/util/sdk_version_match.dart';

void main() {
  group('utils.sdk_version_match', () {
    test('should return true if versions are exactly same', () async {
      expect(isSameSdkVersion('2.0.0-dev30.0', '2.0.0-dev30.0'), isTrue);
      expect(
          isSameSdkVersion('2.0.0-dev30.0 (unknown_timestamp) "linux_x64"',
              '2.0.0-dev30.0 (unknown_timestamp) "linux_x64"'),
          isTrue);
      expect(isSameSdkVersion('random_string', 'random_string'), isTrue);
    });
    test(
        'should return true if versions are same but version strings are different',
        () async {
      expect(isSameSdkVersion('2.0.0-dev30.0 11', '2.0.0-dev30.0'), isTrue);
      expect(
          isSameSdkVersion('2.0.0-dev30.0 (unknown_timestamp) "linux_x64"',
              '2.0.0-dev30.0 (unknown_timestamp) "macos_x64"'),
          isTrue);
    });

    test('should return false if versions are different', () async {
      expect(isSameSdkVersion('2.0.0-dev30.0', '2.0.0-dev30.1'), isFalse);
      expect(
          isSameSdkVersion('2.0.0-dev30.0 (unknown_timestamp) "linux_x64"',
              '2.0.0-dev30.4 (unknown_timestamp) "linux_x64"'),
          isFalse);
      expect(isSameSdkVersion('random_string', 'random_string_other'), isFalse);
    });
  });
}
