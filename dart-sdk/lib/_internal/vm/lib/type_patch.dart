// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "core_patch.dart";

// These Dart classes correspond to the VM internal implementation classes.

abstract class _AbstractType implements Type {
  @pragma("vm:external-name", "AbstractType_toString")
  external String toString();

  @pragma("vm:recognized", "asm-intrinsic")
  @pragma("vm:exact-result-type", "dart:core#_Smi")
  @pragma("vm:external-name", "AbstractType_getHashCode")
  external int get hashCode;

  @pragma("vm:recognized", "asm-intrinsic")
  @pragma("vm:exact-result-type", bool)
  @pragma("vm:external-name", "AbstractType_equality")
  external bool operator ==(other);
}

@pragma("vm:entry-point")
class _Type extends _AbstractType {
  factory _Type._uninstantiable() {
    throw "Unreachable";
  }

  @pragma("vm:recognized", "asm-intrinsic")
  @pragma("vm:exact-result-type", bool)
  @pragma("vm:external-name", "Type_equality")
  external bool operator ==(other);
}

@pragma("vm:entry-point")
class _FunctionType extends _AbstractType {
  factory _FunctionType._uninstantiable() {
    throw "Unreachable";
  }
}

@pragma("vm:entry-point")
class _RecordType extends _AbstractType {
  factory _RecordType._uninstantiable() {
    throw "Unreachable";
  }
}

@pragma("vm:entry-point")
class _TypeRef extends _AbstractType {
  factory _TypeRef._uninstantiable() {
    throw "Unreachable";
  }
}

@pragma("vm:entry-point")
class _TypeParameter extends _AbstractType {
  factory _TypeParameter._uninstantiable() {
    throw "Unreachable";
  }
}
