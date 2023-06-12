// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show Platform;

/// If we have `dart:io` available, we pull the current operating system from
/// the [Platform] class, so we'll get errno values that match our current
/// operating system.
final String operatingSystem = Platform.operatingSystem;
