// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async' show FutureOr;

import 'package:flutter/rendering.dart';
import 'package:flutter_goldens/flutter_goldens.dart' as flutter_goldens;

Future<void> testExecutable(FutureOr<void> testMain()) async {
  debugCheckIntrinsicSizes = true;
  return flutter_goldens.testExecutable(testMain);
}
