// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show Platform;

/// Major.minor.patch version of current dart version.
final dartVersion = Platform.version.split(RegExp('[^0-9]')).take(3).join('.');
