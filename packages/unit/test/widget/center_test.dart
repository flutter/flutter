// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:test/test.dart';

import 'widget_tester.dart';

void main() {
  test('Can be placed in an infinte box', () {
    testWidgets((WidgetTester tester) {
      tester.pumpWidget(new Block(<Widget>[new Center()]));
    });
  });
}
