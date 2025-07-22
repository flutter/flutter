// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "core_patch.dart";

@pragma("vm:entry-point")
final class _Closure implements Function {
  factory _Closure._uninstantiable() {
    throw "Unreachable";
  }

  @pragma("vm:external-name", "Closure_equals")
  external bool operator ==(Object other);

  int get hashCode {
    _hash ??= _computeHash();
    return _hash;
  }

  @pragma("vm:entry-point")
  _Closure get call => this;

  @pragma("vm:external-name", "Closure_computeHash")
  external int _computeHash();

  // No instance fields should be declared before the following fields whose
  // offsets must be identical in Dart and C++.

  // The following fields are declared both in raw_object.h (for direct access
  // from C++ code) and also here so that the offset-to-field map used by
  // deferred objects is properly initialized.
  // Caution: These fields are not Dart instances, but VM objects. Their Dart
  // names do not need to match the C++ names, but they must be private.
  @pragma("vm:entry-point")
  var _instantiator_type_arguments;
  @pragma("vm:entry-point")
  var _function_type_arguments;
  @pragma("vm:entry-point")
  var _delayed_type_arguments;
  @pragma("vm:entry-point")
  var _function;
  @pragma("vm:entry-point")
  var _context;

  // Note: _Closure objects are created by VM "magically", without invoking
  // constructor. So, _Closure default constructor is never compiled and
  // detection of default-initialized fields is not performed.
  // As a consequence, VM incorrectly assumes that _hash field is not
  // nullable and may incorrectly remove 'if (_hash == null)' in get:hashCode.
  // This initializer makes _hash field nullable even without constructor
  // compilation.
  @pragma("vm:entry-point")
  var _hash = null;
}
