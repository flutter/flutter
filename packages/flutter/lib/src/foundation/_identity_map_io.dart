// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';

/// Create a new identity [Map].
///
/// This cannot be used with classes that override [Object.hashCode] or
/// [Object.==].
///
/// On the web this will be backed by a JavaScript Map, which is more
/// performant if the type of `K` is not a [String], [int], [double], or [bool].
///
/// On Mobile and desktop this returns an identity [HashMap].
Map<K, V> createIdentityMap<K, V>() {
  return HashMap<K, V>.identity();
}

/// Create a new identity [Set].
///
/// This cannot be used with classes that override [Object.hashCode] or
/// [Object.==].
///
/// On the web this will be backed by a JavaScript Set, which is more
/// performant if the type of `V` is not a [String], [int], [double], or [bool].
///
/// On Mobile and desktop this returns an identity [HashMap].
Set<V> createIdentitySet<V>() {
  return HashSet<V>.identity();
}
