// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart._object_helper;

// Access hidden identity hash code field.
@pragma("wasm:intrinsic")
external int getIdentityHashField(Object obj);
@pragma("wasm:intrinsic")
external void setIdentityHashField(Object obj, int hash);
