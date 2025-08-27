// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file is part of dev/bots/test.dart's runTracingTests test.

import 'package:flutter/foundation.dart';

void main() {
  // This file is intended to be compiled in profile mode.
  // In that mode, the function below throws an exception.
  // The dev/bots/test.dart test looks for the string from that exception.
  // The string below is matched verbatim in dev/bots/test.dart as a control
  // to make sure this file did get compiled.
  DiagnosticsNode.message('TIMELINE ARGUMENTS TEST CONTROL FILE').toTimelineArguments();
}
