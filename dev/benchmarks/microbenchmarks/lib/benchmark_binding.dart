// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';

class BenchmarkingBinding extends LiveTestWidgetsFlutterBinding {
  BenchmarkingBinding();

  final Stopwatch drawFrameWatch = Stopwatch();

  @override
  void handleBeginFrame(Duration? rawTimeStamp) {
    drawFrameWatch.start();
    super.handleBeginFrame(rawTimeStamp);
  }

  @override
  void handleDrawFrame() {
    super.handleDrawFrame();
    drawFrameWatch.stop();
  }
}
