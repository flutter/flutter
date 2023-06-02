// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Framework code should use this method in favor of calling `toString` on
/// [Object.runtimeType].
///
/// Calling `toString` on a runtime type is a non-trivial operation that can
/// negatively impact performance. If asserts are enabled, this method will
/// return `object.runtimeType.toString()`; otherwise, it will return the
/// [optimizedValue], which must be a simple constant string.
String objectRuntimeType(Object? object, String optimizedValue) {
  assert(() {
    optimizedValue = object.runtimeType.toString();
    return true;
  }());
  return optimizedValue;
}


abstract class WeakValue<T> {
  WeakValue._();

  factory WeakValue(T value){
    throw UnimplementedError();
    //return WeakObjectValue<T>(value);
  }

  /// Returns the value if it is still accessible, otherwise returns null.
  T? get value;
}

class _WeakObjectValue<T extends Object> extends WeakValue<T>{

  final WeakReference<T> _ref;

  _WeakObjectValue(T value) : _ref = WeakReference(value), super._();

  @override
  T? get value => _ref.target;
}
