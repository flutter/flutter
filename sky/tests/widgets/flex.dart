// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:sky/widgets.dart';

import '../resources/display_list.dart';

class TestApp extends App {
  Widget build() {
    return new Container(
      padding: new EdgeDims.all(50.0),
      child: new Flex([
          new Card(
            child: new Container(
              width: 300.0,
              height: 500.0,
              child: new Flex([
                  new Text('TOP'),
                  new Flexible(
                    child: new Container(
                      decoration: new BoxDecoration(backgroundColor: new Color(0xFF509050)),
                      child: new Flex([new Text('bottom')],
                        direction: FlexDirection.vertical,
                        alignItems: FlexAlignItems.stretch
                      )
                    )
                  )
                ],
                alignItems: FlexAlignItems.stretch,
                direction: FlexDirection.vertical
              )
            )
          ),
          new Card(
            child: new Container(
              width: 300.0,
              height: 500.0,
              child: new Flex([
                  new Flexible(
                    child: new Container(
                      decoration: new BoxDecoration(backgroundColor: new Color(0xFF509050)),
                      child: new Flex([new Text('top')],
                        direction: FlexDirection.vertical,
                        alignItems: FlexAlignItems.stretch
                      )
                    )
                  ),
                  new Text('BOTTOM')
                ],
                alignItems: FlexAlignItems.stretch,
                direction: FlexDirection.vertical
              )
            )
          )
        ],
        direction: FlexDirection.horizontal
      )
    );
  }
}

main() async {
  TestRenderView renderViewOverride = new TestRenderView();
  TestApp app = new TestApp();
  runApp(app, renderViewOverride: renderViewOverride);
  await renderViewOverride.checkFrame();
  renderViewOverride.endTest();
}
