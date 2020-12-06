// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/commands/create.dart';

import '../src/common.dart';

void main() {

  test('Validates Pub package name', () {
    expect(isValidPackageName('is'), false);
    expect(isValidPackageName('92'), false);
    expect(isValidPackageName('a-b-c'), false);

    expect(isValidPackageName('foo_bar'), true);
    expect(isValidPackageName('_foo_bar'), true);
    expect(isValidPackageName('fizz93'), true);
  });
}
