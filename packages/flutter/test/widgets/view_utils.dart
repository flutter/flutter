// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

extension WrapperlessWidgetTester on WidgetTester {
  /// Similar to [pumpWidget], but does not wrap the widget tree with an
  /// implicit view.
  Future<void> pumpWidgetWithoutViewWrapper(Widget widget) {
    binding.attachRootWidget(widget);
    binding.scheduleFrame();
    return binding.pump();
  }
}
