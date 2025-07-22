// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "core_patch.dart";

// Base class for record instances.
@pragma("vm:entry-point")
final class _Record implements Record {
  factory _Record._uninstantiable() {
    throw "Unreachable";
  }

  // Do not inline to avoid mixing _fieldAt with
  // record field accesses.
  @pragma("vm:never-inline")
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! _Record) {
      return false;
    }

    _Record otherRec = unsafeCast<_Record>(other);
    if (_shape != otherRec._shape) {
      return false;
    }

    final int numFields = _numFields;
    for (int i = 0; i < numFields; ++i) {
      if (_fieldAt(i) != otherRec._fieldAt(i)) {
        return false;
      }
    }
    return true;
  }

  // Do not inline to avoid mixing _fieldAt with
  // record field accesses.
  @pragma("vm:never-inline")
  int get hashCode {
    int hash = _shape;
    final int numFields = _numFields;
    for (int i = 0; i < numFields; ++i) {
      hash = SystemHash.combine(hash, _fieldAt(i).hashCode);
    }
    return SystemHash.finish(hash);
  }

  // Do not inline to avoid mixing _fieldAt with
  // record field accesses.
  @pragma("vm:never-inline")
  String toString() {
    StringBuffer buffer = StringBuffer("(");
    final int numFields = _numFields;
    final _List fieldNames = _fieldNames;
    final int numPositionalFields = numFields - fieldNames.length;
    for (int i = 0; i < numFields; ++i) {
      if (i != 0) {
        buffer.write(", ");
      }
      if (i >= numPositionalFields) {
        buffer.write(unsafeCast<String>(fieldNames[i - numPositionalFields]));
        buffer.write(": ");
      }
      buffer.write(_fieldAt(i).toString());
    }
    buffer.write(")");
    return buffer.toString();
  }

  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  external int get _shape;

  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  @pragma("vm:idempotent")
  external int get _numFields;

  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  @pragma("vm:idempotent")
  external _List get _fieldNames;

  // Currently compiler does not take into account aliasing
  // between access to record fields via _fieldAt and
  // via record.foo / record.$n.
  // So this method should only be used in methods
  // which only access record fields with _fieldAt and
  // annotated with @pragma("vm:never-inline").
  @pragma("vm:recognized", "other")
  @pragma("vm:prefer-inline")
  external Object? _fieldAt(int index);
}
