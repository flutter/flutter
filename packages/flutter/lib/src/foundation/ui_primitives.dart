// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:ui_primitives/ui_primitives.dart' hide VoidCallback;

export 'package:ui_primitives/ui_primitives.dart' hide VoidCallback;

void configureErrorReportingInUiPrimitives() {
  FrameworkErrorReporter.instance = _FlutterErrorReporter();
}

class _FlutterErrorReporter implements FrameworkErrorReporter {
  @override
  FrameworkError errorByDetails(FrameworkErrorDetails details) {
    // TODO: implement errorByDetails
    throw UnimplementedError();
  }

  @override
  FrameworkError errorByMessage(String message) {
    // TODO: implement errorByMessage
    throw UnimplementedError();
  }

  @override
  void report(FrameworkErrorDetails details) {
    // TODO: implement report
  }
}
