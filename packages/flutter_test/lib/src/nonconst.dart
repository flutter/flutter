// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// This function can be used to prevent some const lints.
///
/// It's usually used when we want several instances to be separate instances so
/// that we're not just checking with a single object.
///
/// ```dart
/// class A {
///   const A(this.i);
///   int i;
/// }
///
/// main () {
///   // prevent prefer_const_constructors lint
///   new A(nonconst(null));
///
///   // prevent prefer_const_declarations lint
///   final int $null = nonconst(null);
///   final A a = nonconst(const A(null));
/// }
/// ```
T nonconst<T>(T t) => t;