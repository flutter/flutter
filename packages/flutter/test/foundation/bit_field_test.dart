// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

@TestOn('!chrome')

import 'package:flutter/foundation.dart';
import '../flutter_test_alternative.dart';

// ignore: unused_field
enum _TestEnum { a, b, c, d, e, f, g, h, }

void main() {
  test('BitField control test', () {
    final BitField<_TestEnum> field = BitField<_TestEnum>(8);

    expect(field[_TestEnum.d], isFalse);

    field[_TestEnum.d] = true;
    field[_TestEnum.e] = true;

    expect(field[_TestEnum.c], isFalse);
    expect(field[_TestEnum.d], isTrue);
    expect(field[_TestEnum.e], isTrue);

    field[_TestEnum.e] = false;

    expect(field[_TestEnum.c], isFalse);
    expect(field[_TestEnum.d], isTrue);
    expect(field[_TestEnum.e], isFalse);

    field.reset();

    expect(field[_TestEnum.c], isFalse);
    expect(field[_TestEnum.d], isFalse);
    expect(field[_TestEnum.e], isFalse);

    field.reset(true);

    expect(field[_TestEnum.c], isTrue);
    expect(field[_TestEnum.d], isTrue);
    expect(field[_TestEnum.e], isTrue);
  });

  test('BitField.filed control test', () {
    final BitField<_TestEnum> field1 = BitField<_TestEnum>.filled(8, true);

    expect(field1[_TestEnum.d], isTrue);

    final BitField<_TestEnum> field2 = BitField<_TestEnum>.filled(8, false);

    expect(field2[_TestEnum.d], isFalse);
  });
}
