// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(dantup): Consolidate this with the equiv file in analysis_server (most
//  likely by having analysis_server reference this one).

Object? specToJson(Object? obj) {
  if (obj is ToJsonable) {
    return obj.toJson();
  } else {
    return obj;
  }
}

/// Represents either a [T1] or [T2].
///
/// This class is used for fields generated from the LSP/DAP specs that are
/// defined as unions in TypeScript (for example `String | number`) that cannot
/// directly be represented as Dart types.
///
/// Use the [map] function to access the element, providing a handler for each
/// of the possible types.
class Either2<T1, T2> extends ToJsonable {
  final int _which;
  final T1? _t1;
  final T2? _t2;

  Either2.t1(T1 this._t1)
      : _t2 = null,
        _which = 1;
  Either2.t2(T2 this._t2)
      : _t1 = null,
        _which = 2;

  T map<T>(T Function(T1) f1, T Function(T2) f2) {
    return _which == 1 ? f1(_t1 as T1) : f2(_t2 as T2);
  }

  @override
  Object? toJson() => map(specToJson, specToJson);

  @override
  String toString() => map((t) => t.toString(), (t) => t.toString());

  /// Checks whether the value of the union equals the supplied value.
  bool valueEquals(o) => map((t) => t == o, (t) => t == o);
}

/// An object from the LSP/DAP specs that can be converted to JSON.
abstract class ToJsonable {
  Object? toJson();
}
