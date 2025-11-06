// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_goldens/flutter_goldens.dart' as flutter_goldens show testExecutable;
import 'package:flutter_test/flutter_test.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) {
  // Enable golden file testing using Skia Gold.
  return flutter_goldens.testExecutable(testMain);
}
