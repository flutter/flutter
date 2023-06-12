// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'version_fallback.dart' if (dart.library.io) 'version_io.dart' as impl;

/// If `dart:io` is available, returns the current Dart SDK version.
///
/// Otherwise, returns 'unknown'.
String get dartVersion => impl.dartVersion;
