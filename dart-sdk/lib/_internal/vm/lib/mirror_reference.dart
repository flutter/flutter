// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "mirrors_patch.dart";

@pragma("vm:entry-point")
class _MirrorReference {
  factory _MirrorReference._uninstantiable() {
    throw "Unreachable";
  }

  @pragma("vm:external-name", "MirrorReference_equals")
  external bool operator ==(Object other);
}
