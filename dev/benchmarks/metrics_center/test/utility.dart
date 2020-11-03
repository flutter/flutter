// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'common.dart';

// This will be used in many of our unit tests.
void expectSetMatch<T>(Iterable<T> actual, Iterable<T> expected) {
  expect(Set<T>.from(actual), equals(Set<T>.from(expected)));
}
