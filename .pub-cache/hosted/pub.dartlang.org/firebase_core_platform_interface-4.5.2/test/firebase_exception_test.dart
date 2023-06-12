// ignore_for_file: require_trailing_commas
// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('$FirebaseException', () {
    test('should return a formatted message', () async {
      FirebaseException e = FirebaseException(
        plugin: 'foo',
        message: 'bar',
      );

      expect(e.toString(), '[foo/unknown] bar');
    });

    test('should return a formatted message with a custom code', () async {
      FirebaseException e =
          FirebaseException(plugin: 'foo', message: 'bar', code: 'baz');

      expect(e.toString(), '[foo/baz] bar');
    });

    test('should return a formatted message with a stack trace', () async {
      FirebaseException e = FirebaseException(
          plugin: 'foo',
          message: 'bar',
          code: 'baz',
          stackTrace: StackTrace.current);

      // Anything with a stack trace adds 2 blanks lines following the message.
      expect(e.toString(), startsWith('[foo/baz] bar\n\n'));
    });

    test('should override the == operator', () async {
      FirebaseException e1 =
          FirebaseException(plugin: 'foo', message: 'bar', code: 'baz');

      FirebaseException e2 =
          FirebaseException(plugin: 'foo', message: 'bar', code: 'baz');

      FirebaseException e3 =
          FirebaseException(plugin: 'foo', message: 'bar', code: 'baz');

      expect(e1 == e2, true);
      expect(e1 != e3, false);
    });
  });
}
