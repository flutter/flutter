#!/usr/bin/env dart
// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import '../out/protos/default_value_escape.pb.dart';

void main() {
  test('default values are escaped properly', () {
    final f = F();
    expect(f.a, 'a\nb');
    expect(f.b, 'a\'b');
    expect(f.c, 'a"b');
    expect(f.d, 'a\$b');
    expect(f.e, 'a\\b');
    expect(f.f, 'a\x00b');
    expect(f.g, '🇺🇸');
  });
}
