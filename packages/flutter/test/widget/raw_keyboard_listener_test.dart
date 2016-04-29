// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

void main() {
  testWidgets('Can dispose without keyboard', (WidgetTester tester) {
    tester.pumpWidget(new RawKeyboardListener(child: new Container()));
    tester.pumpWidget(new Container());
  });
}
