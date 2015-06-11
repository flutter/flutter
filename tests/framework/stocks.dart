// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:sky/framework/app.dart';
import 'package:sky/framework/widgets/ui_node.dart';

import '../../examples/stocks2/lib/stock_app.dart';
import '../resources/display_list.dart';
import '../resources/third_party/unittest/unittest.dart';
import '../resources/unit.dart';

void main() {
  initUnit();

  TestRenderView testRenderView = new TestRenderView();

  test("launching stock app", () {
    new StocksApp(renderViewOverride: testRenderView);
    new Future.microtask(testRenderView.checkFrame);
  });
}
