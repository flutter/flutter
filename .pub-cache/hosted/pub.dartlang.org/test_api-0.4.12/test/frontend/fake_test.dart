// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:test_api/fake.dart' as test_api;

void main() {
  late _FakeSample fake;
  setUp(() {
    fake = _FakeSample();
  });
  test('method invocation', () {
    expect(() => fake.f(), throwsA(TypeMatcher<UnimplementedError>()));
  });
  test('getter', () {
    expect(() => fake.x, throwsA(TypeMatcher<UnimplementedError>()));
  });
  test('setter', () {
    expect(() => fake.x = 0, throwsA(TypeMatcher<UnimplementedError>()));
  });
  test('operator', () {
    expect(() => fake + 1, throwsA(TypeMatcher<UnimplementedError>()));
  });
}

class _Sample {
  void f() {}

  int get x => 0;

  set x(int value) {}

  int operator +(int other) => 0;
}

class _FakeSample extends test_api.Fake implements _Sample {}
