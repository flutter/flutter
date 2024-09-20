// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "core_patch.dart";

@patch
@pragma("vm:recognized", "other")
@pragma("vm:exact-result-type", bool)
@pragma("vm:external-name", "Identical_comparison")
external bool identical(Object? a, Object? b);

@patch
@pragma("vm:entry-point", "call")
int identityHashCode(Object? object) => object._identityHashCode;
