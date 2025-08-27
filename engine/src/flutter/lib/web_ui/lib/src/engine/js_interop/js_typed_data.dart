// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:js_interop';

// Some APIs we need on typed arrays that are not exposed by the dart sdk yet
extension TypedArrayExtension on JSTypedArray {
  external JSTypedArray slice(int start, int end);
  external void set(JSTypedArray source, int start);
  external int get length;
}
