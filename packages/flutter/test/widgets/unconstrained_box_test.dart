// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

void main() {
  testWidgets('reassemble widget without consstrainedAxis',
      (WidgetTester tester) async {
    final UnconstrainedBox box = new UnconstrainedBox(child: new Container());

    await tester.pumpWidget(box);
    tester.binding.reassembleApplication();
    await tester.pump();
  });
}
