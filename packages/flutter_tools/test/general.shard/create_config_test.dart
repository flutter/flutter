// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/commands/create_base.dart';

import '../src/common.dart';

void main() {

  test('Validates Pub package name', () {
    expect(isValidPackageName('is'), false);
    expect(isValidPackageName('92'), false);
    expect(isValidPackageName('a-b-c'), false);

    expect(isValidPackageName('foo_bar'), true);
    expect(isValidPackageName('_foo_bar'), true);
    expect(isValidPackageName('fizz93'), true);

    expect(isValidPackageName('Foo_bar'), false);
  });

  test('Suggest a valid Pub package name', () {
    expect(potentialValidPackageName('92'), '_92');
    expect(potentialValidPackageName('a-b-c'), 'a_b_c');


    expect(potentialValidPackageName('foo.bar'), 'foo_bar');
    expect(potentialValidPackageName('Foo_bar'), 'foo_bar');
    expect(potentialValidPackageName('foo._bar'), 'foo_bar');

  });

  test('kWindowsDrivePattern', () {
    expect(CreateBase.kWindowsDrivePattern.hasMatch(r'D:\'), isFalse);
    expect(CreateBase.kWindowsDrivePattern.hasMatch(r'z:\'), isFalse);
    expect(CreateBase.kWindowsDrivePattern.hasMatch(r'\d:'), isFalse);
    expect(CreateBase.kWindowsDrivePattern.hasMatch(r'ef:'), isFalse);
    expect(CreateBase.kWindowsDrivePattern.hasMatch(r'D:'), isTrue);
    expect(CreateBase.kWindowsDrivePattern.hasMatch(r'c:'), isTrue);
  });
}
