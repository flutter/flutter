// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/widgets.dart';

import '../resources/display_list.dart';

// see issue 626

class ProblemComponent extends StatefulComponent {

  void syncConstructorArguments(ProblemComponent source) { }

  bool _flag = false;

  void flip() {
    setState(() {
      _flag = true;
    });
  }

  Widget build() {
    if (_flag)
      return new Padding(padding: const EdgeDims.all(10.0));
    return new SizedBox(width: 100.0, height: 100.0);
  }
}

ProblemComponent a;
ProblemComponent b;

class TestApp extends App {
  Widget build() {
    return new Column([
        a = new ProblemComponent(),
        b = new ProblemComponent()
      ]
    );
  }
}

main() async {
  try {
    TestRenderView renderViewOverride = new TestRenderView();
    TestApp app = new TestApp();
    runApp(app, renderViewOverride: renderViewOverride);
    await renderViewOverride.checkFrame();
    b.flip();
    await renderViewOverride.checkFrame();
    a.flip();
    await renderViewOverride.checkFrame();
    renderViewOverride.endTest();
  } catch (e, s) {
    print("Exception: $e\nStack:\n$s\n");
  }
}
