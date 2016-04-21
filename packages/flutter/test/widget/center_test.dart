// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

void main() {
  testWidgets('Can be placed in an infinite box', (WidgetTester tester) {
      tester.pumpWidget(new Block(children: <Widget>[new Center()]));
  });
}
