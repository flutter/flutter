// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// This function can be used to call a const constructor in such a way as to
/// create a new instance rather than creating the common const instance.
///
/// ```dart
/// class A {
///   const A(this.i);
///   final int? i;
/// }
///
/// void main () {
///   // prevent prefer_const_constructors lint
///   A(nonconst(null));
///
///   // prevent prefer_const_declarations lint
///   final int? $null = nonconst(null);
///   final A a = nonconst(const A(null));
/// }
/// ```
T nonconst<T>(T t) => t;
