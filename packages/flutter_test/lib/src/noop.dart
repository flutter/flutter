// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// This function can be used to make a statement used and prevent lint
/// reporting unnecessary statement.
///
/// ```dart
/// var a = 1;
///
/// main () {
///   // prevent unnecessary_statements lint
///   noop(a);
/// }
/// ```
void noop(Object o) {}
