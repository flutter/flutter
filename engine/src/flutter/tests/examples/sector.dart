// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:sky/widgets/widget.dart';

import '../../examples/widgets/sector.dart';
import '../resources/display_list.dart';

main() async {
  TestRenderView testRenderView = new TestRenderView();
  SectorApp app = new SectorApp();
  runApp(app, renderViewOverride: testRenderView);
  await testRenderView.checkFrame();
  app.addSector();
  await testRenderView.checkFrame();
  app.addSector();
  await testRenderView.checkFrame();
  app.addSector();
  await testRenderView.checkFrame();
  app.removeSector();
  await testRenderView.checkFrame();
  app.removeSector();
  await testRenderView.checkFrame();
  app.addSector();
  await testRenderView.checkFrame();
  testRenderView.endTest();
}
