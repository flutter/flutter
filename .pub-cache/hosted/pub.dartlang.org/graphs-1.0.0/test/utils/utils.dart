// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

bool xEquals(X a, X b) => a.value == b.value;

int xHashCode(X a) => a.value.hashCode;

class X {
  final String value;

  X(this.value);

  @override
  bool operator ==(Object other) => throw UnimplementedError();

  @override
  int get hashCode => 42;

  @override
  String toString() => '($value)';
}
