#!/usr/bin/env dart
// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import '../out/protos/import_public.pb.dart';

void main() {
  test('can reference a message type imported publicly', () {
    expect(Foo(), TypeMatcher<Foo>());
    expect(A(), TypeMatcher<A>());
  });
}
