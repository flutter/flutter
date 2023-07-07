// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A container that is either [T1] or [T2].
class Either2<T1, T2> {
  final int _which;
  final Object? _value;

  Either2.t1(T1 t1)
      : _which = 1,
        _value = t1;

  Either2.t2(T2 t2)
      : _which = 2,
        _value = t2;

  T map<T>(T Function(T1) f1, T Function(T2) f2) {
    if (_which == 1) {
      return f1(_value as T1);
    } else {
      return f2(_value as T2);
    }
  }

  @override
  String toString() => map((t) => t.toString(), (t) => t.toString());
}
