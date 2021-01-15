// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/rendering.dart';

import '_goldens_io.dart'
  if (dart.library.html) '_goldens_web.dart' as flutter_goldens;

Future<void> testExecutable(FutureOr<void> testMain()) {
  // Enable checks because there are many implementations of [RenderBox] in this
  // package can benefit from the additional validations.
  debugCheckIntrinsicSizes = true;

  return flutter_goldens.testExecutable(testMain);
}
