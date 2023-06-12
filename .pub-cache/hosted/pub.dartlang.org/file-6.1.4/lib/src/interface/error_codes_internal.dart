// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// In environments that don't have `dart:io`, we can't access the Platform
/// class to determine what platform we're on, so we just pretend we're on
/// Linux, meaning we'll get errno values that match Linux's errno.h.
const String operatingSystem = 'linux';
