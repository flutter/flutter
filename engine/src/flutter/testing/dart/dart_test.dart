// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
import 'dart:async';

import 'package:test/test.dart' hide TypeMatcher, isInstanceOf;

/// Verifies Dart semantics governed by flags set by Flutter tooling.
void main() {
  group('Async', () {
    String greeting = 'hello';
    Future<void> changeGreeting() async {
      greeting += ' 1';
      await Future<void>.value(null);
      greeting += ' 2';
    }
    test('execution of async method starts synchronously', () async {
      expect(greeting, 'hello');
      final Future<void> future = changeGreeting();
      expect(greeting, 'hello 1');
      await future;
      expect(greeting, 'hello 1 2');
    });
  });
}
