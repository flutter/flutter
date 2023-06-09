// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Providing a RenderObjectWidget directly to the RootWidget fails', (WidgetTester tester) async {
    // No render tree exists to attach the RenderObjectWidget to.
    await pumpWidgetWithoutViewWrapper(
      tester: tester,
      widget: const ColoredBox(color: Colors.red),
    );

    expect(tester.takeException(), isFlutterError.having(
      (FlutterError error) => error.message,
      'message',
      startsWith('RenderObject for ColoredBox cannot find ancestor RenderObject to attach to.'),
    ));
  });

  // testWidgets('A View cannot be a child of a render object widget', (WidgetTester tester) async {
  //   await tester.pumpWidget(Center(
  //     child: View(
  //       view: FakeView(tester.view),
  //       child: Container(),
  //     ),
  //   ));
  //
  //   expect(tester.takeException(), isFlutterError.having(
  //     (FlutterError error) => error.message,
  //     'message',
  //     contains('cannot maintain an independent render tree at its current location.'),
  //   ));
  //
  //   // The tree is in very bad shape after that error, clean it up so it doesn't fail during teardown.
  //   await tester.pumpWidget(Container());
  //   expect(tester.takeException(), isAssertionError);
  // });

  testWidgets('The child of a ViewAnchor cannot be a View', (WidgetTester tester) async {
    await tester.pumpWidget(
      ViewAnchor(
        child: View(
          view: FakeView(tester.view),
          child: Container(),
        ),
      ),
    );

    expect(tester.takeException(), isFlutterError.having(
      (FlutterError error) => error.message,
      'message',
      contains('cannot maintain an independent render tree at its current location.'),
    ));
  });

  // testWidgets('The view property of a ViewAnchor cannot be a render object widget', (WidgetTester tester) async {
  //   await tester.pumpWidget(
  //     ViewAnchor(
  //       view: const ColoredBox(color: Colors.red),
  //       child: Container(),
  //     ),
  //   );
  //
  //   expect(tester.takeException(), isFlutterError);
  // });

  testWidgets('ViewAnchor cannot be used at the top of the widget tree (outside of View)', (WidgetTester tester) async {
    await pumpWidgetWithoutViewWrapper(
      tester: tester,
      widget: const ViewAnchor(
        child: SizedBox(),
      ),
    );

    expect(tester.takeException(), isFlutterError.having(
      (FlutterError error) => error.message,
      'message',
      startsWith('RenderObject for SizedBox cannot find ancestor RenderObject to attach to.'),
    ));
  });

  testWidgets('View can be used at the top of the widget tree', (WidgetTester tester) async {
    await pumpWidgetWithoutViewWrapper(
      tester: tester,
      widget: View(
        view: tester.view,
        child: Container(),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('ViewCollection can be used at the top of the widget tree', (WidgetTester tester) async {
    await pumpWidgetWithoutViewWrapper(
      tester: tester,
      widget: ViewCollection(
        views: <Widget>[
          View(
            view: tester.view,
            child: Container(),
          ),
        ],
      ),
    );

    expect(tester.takeException(), isNull);
  });

  // Currently working on
  testWidgets('ViewCollection cannot be used inside a View', (WidgetTester tester) async {
    await tester.pumpWidget(
      ViewCollection(
        views: <Widget>[
          View(
            view: FakeView(tester.view),
            child: Container(),
          ),
        ],
      ),
    );

    expect(tester.takeException(), isFlutterError);
  });

  testWidgets('ViewCollection can be used as ViewAnchor.view', (WidgetTester tester) async {
    await tester.pumpWidget(
      ViewAnchor(
        view: ViewCollection(
          views: <Widget>[
            View(
              view: FakeView(tester.view),
              child: Container(),
            )
          ],
        ),
        child: Container(),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  // testWidgets('ViewCollection cannot have render object widgets as children', (WidgetTester tester) async {
  //   await pumpWidgetWithoutViewWrapper(
  //     tester: tester,
  //     widget: ViewCollection(
  //       views: const <Widget>[
  //         ColoredBox(color: Colors.red),
  //       ],
  //     ),
  //   );
  //
  //   expect(tester.takeException(), isFlutterError);
  // });
}

Future<void> pumpWidgetWithoutViewWrapper({required WidgetTester tester, required  Widget widget}) {
  tester.binding.attachRootWidget(widget);
  tester.binding.scheduleFrame();
  return tester.binding.pump();
}

class FakeView extends TestFlutterView{
  FakeView(FlutterView view) : super(
    view: view,
    platformDispatcher: view.platformDispatcher as TestPlatformDispatcher,
    display: view.display as TestDisplay,
  );

  @override
  int get viewId => 100;
}
