// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('preset selected', () {});
  test('not selected by the passing preset', () => fail('The preset was not applied.'));
  test('command option combined selection', () {});
  test('command option filtered out', () => fail('The command option was not applied.'));
  test(
    'outside preset combined selection',
    () => fail('The preset was not combined with the command option.'),
  );
}
