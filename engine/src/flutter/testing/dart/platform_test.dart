// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:litetest/litetest.dart';

void main() {
  test('Platform.script has right URI', () async {
    // Platform.script should look like file:///path/to/engine/src/out/variant/gen/platform_test.dart.dill
    expect(Platform.script.path, endsWith('gen/platform_test.dart.dill'));
  });
}
