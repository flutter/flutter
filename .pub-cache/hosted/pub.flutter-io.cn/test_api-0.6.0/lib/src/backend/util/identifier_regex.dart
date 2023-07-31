// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A regular expression matching a full string as a hyphenated identifier.
///
/// This is like a standard Dart identifier, except that it can also contain
/// hyphens.
final anchoredHyphenatedIdentifier = RegExp(r'^[a-zA-Z_-][a-zA-Z0-9_-]*$');
