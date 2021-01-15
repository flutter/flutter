// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('example', () {
    test('passed', () {
      print('This is print');
      stderr.writeln('This is writeln');
      expect(true, true);
    });
    test('failed', () {
      expect(true, false);
    });
    test('skipped', () {
      expect(true, false);
    }, skip: true);
  });
}
