// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';

// ignore_for_file: deprecated_member_use_from_same_package

// This test does not guarantee that the solo tests/groups are called, this is
// extensively tested in the test package. It however tests that non-solo
// tests are skipped
void main() {
  test('not_solo_test', () {
    fail('not_solo');
  });

  test('solo_test', () {
    expect(true, isTrue);
  }, solo: true);

  group('solo_group', () {
    test('test', () {
      expect(true, isTrue);
    });
  }, solo: true);
}
