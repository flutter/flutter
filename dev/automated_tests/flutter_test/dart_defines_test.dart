// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Dart defines can be provided', () {
    expect(const String.fromEnvironment('flutter.test.foo'), 'bar');
  });
}
