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

  // testWidgets('Moving a RenderObjectWidget to the RootWidget via GlobalKey fails', (WidgetTester tester) async {
  //   final Widget globalKeyedWidget = ColoredBox(
  //     key: GlobalKey(),
  //     color: Colors.red,
  //   );
  //
  //   await pumpWidgetWithoutViewWrapper(
  //     tester: tester,
  //     widget: View(
  //       view: tester.view,
  //       child: globalKeyedWidget,
  //     ),
  //   );
  //   expect(tester.takeException(), isNull);
  //
  //   await pumpWidgetWithoutViewWrapper(
  //     tester: tester,
  //     widget: globalKeyedWidget,
  //   );
  //
  //   expect(tester.takeException(), isFlutterError.having(
  //     (FlutterError error) => error.message,
  //     'message',
  //     contains('cannot find ancestor RenderObject to attach to.'),
  //   ));
  // });

  testWidgets('A View cannot be a child of a render object widget', (WidgetTester tester) async {
    await tester.pumpWidget(Center(
      child: View(
        view: FakeView(tester.view),
        child: Container(),
      ),
    ));

    expect(tester.takeException(), isFlutterError.having(
      (FlutterError error) => error.message,
      'message',
      contains('cannot maintain an independent render tree at its current location.'),
    ));
  });

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

  // testWidgets('A View can not be moved via GlobalKey to be a child of a RenderObject', (WidgetTester tester) async {
  //   final Widget globalKeyedView = View(
  //     key: GlobalKey(debugLabel: 'ViewKey'),
  //     view: FakeView(tester.view),
  //     child: const ColoredBox(color: Colors.red),
  //   );
  //
  //   await pumpWidgetWithoutViewWrapper(
  //     tester: tester,
  //     widget: ViewCollection(
  //       views: <Widget>[
  //         View(
  //           view: tester.view,
  //           child: const SizedBox(),
  //         ),
  //         globalKeyedView,
  //       ],
  //     ),
  //   );
  //   expect(tester.takeException(), isNull);
  //
  //   await pumpWidgetWithoutViewWrapper(
  //     tester: tester,
  //     widget: ViewCollection(
  //       views: <Widget>[
  //         View(
  //           view: tester.view,
  //           child: SizedBox(
  //             child: globalKeyedView,
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  //
  //   expect(tester.takeException(), isFlutterError.having(
  //     (FlutterError error) => error.message,
  //     'message',
  //     contains('cannot maintain an independent render tree at its current location.'),
  //   ));
  //   // Clean-up some cascading failures resulting from the error above to make
  //   // sure the test passes.
  //   await tester.pumpWidget(Container());
  //   expect(tester.takeException(), isNotNull);
  // });

  testWidgets('The view property of a ViewAnchor cannot be a render object widget', (WidgetTester tester) async {
    await tester.pumpWidget(
      ViewAnchor(
        view: const ColoredBox(color: Colors.red),
        child: Container(),
      ),
    );

    expect(tester.takeException(), isFlutterError.having(
      (FlutterError error) => error.message,
      'message',
      startsWith('RenderObject for ColoredBox cannot find ancestor RenderObject to attach to.'),
    ));
  });

  // testWidgets('A RenderObject cannot be moved into the view property of a ViewAnchor via GlobalKey', (WidgetTester tester) async {
  //   final Widget globalKeyedWidget = ColoredBox(
  //     key: GlobalKey(),
  //     color: Colors.red,
  //   );
  //
  //   await tester.pumpWidget(
  //     ViewAnchor(
  //       child: globalKeyedWidget,
  //     ),
  //   );
  //   expect(tester.takeException(), isNull);
  //
  //   await tester.pumpWidget(
  //     ViewAnchor(
  //       view: globalKeyedWidget,
  //       child: const SizedBox(),
  //     ),
  //   );
  //
  //   expect(tester.takeException(), isFlutterError.having(
  //     (FlutterError error) => error.message,
  //     'message',
  //     contains('cannot find ancestor RenderObject to attach to.'),
  //   ));
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

  // testWidgets('ViewAnchor cannot be moved to the top of the widget tree (outside of View) via GlobalKey', (WidgetTester tester) async {
  //   final Widget globalKeyedViewAnchor = ViewAnchor(
  //     key: GlobalKey(),
  //     child: const SizedBox(),
  //   );
  //
  //   await pumpWidgetWithoutViewWrapper(
  //     tester: tester,
  //     widget: View(
  //       view: tester.view,
  //       child: globalKeyedViewAnchor,
  //     ),
  //   );
  //   expect(tester.takeException(), isNull);
  //
  //   await pumpWidgetWithoutViewWrapper(
  //     tester: tester,
  //     widget: globalKeyedViewAnchor,
  //   );
  //
  //   expect(tester.takeException(), isFlutterError.having(
  //     (FlutterError error) => error.message,
  //     'message',
  //     contains('cannot find ancestor RenderObject to attach to.'),
  //   ));
  // });

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

  // testWidgets('View can be moved to the top of the widget tree view GlobalKey', (WidgetTester tester) async {
  //   final Widget globalKeyView = View(
  //     view: FakeView(tester.view),
  //     child: const ColoredBox(color: Colors.red),
  //   );
  //
  //   await pumpWidgetWithoutViewWrapper(
  //     tester: tester,
  //     widget: View(
  //       view: tester.view,
  //       child: ViewAnchor(
  //         view: globalKeyView,
  //         child: const SizedBox(),
  //       ),
  //     ),
  //   );
  //   expect(tester.takeException(), isNull);
  //   expect(find.byType(SizedBox), findsOneWidget);
  //   expect(find.byType(ColoredBox), findsOneWidget);
  //
  //   await pumpWidgetWithoutViewWrapper(
  //     tester: tester,
  //     widget: globalKeyView,
  //   );
  //   expect(tester.takeException(), isNull);
  //   expect(find.byType(SizedBox), findsNothing);
  //   expect(find.byType(ColoredBox), findsOneWidget);
  // });

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

    expect(tester.takeException(), isFlutterError.having(
      (FlutterError error) => error.message,
      'message',
      startsWith('The Element for ViewCollection cannot be inserted into slot "null" of its ancestor.'),
    ));
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

  testWidgets('ViewCollection cannot have render object widgets as children', (WidgetTester tester) async {
    await pumpWidgetWithoutViewWrapper(
      tester: tester,
      widget: ViewCollection(
        views: const <Widget>[
          ColoredBox(color: Colors.red),
        ],
      ),
    );

    expect(tester.takeException(), isFlutterError.having(
      (FlutterError error) => error.message,
      'message',
      startsWith('RenderObject for ColoredBox cannot find ancestor RenderObject to attach to.'),
    ));
  });

  // testWidgets('Views can be moved in and out of ViewCollections via GlobalKey', (WidgetTester tester) async {
  //   final Widget greenView = View(
  //     key: GlobalKey(),
  //     view: tester.view,
  //     child: const ColoredBox(color: Colors.green),
  //   );
  //   final Widget redView = View(
  //     key: GlobalKey(),
  //     view: FakeView(tester.view),
  //     child: const ColoredBox(color: Colors.red),
  //   );
  //
  //   await pumpWidgetWithoutViewWrapper(
  //     tester: tester,
  //     widget: ViewCollection(
  //       views: <Widget>[
  //         greenView,
  //         ViewCollection(
  //           views: <Widget>[
  //             redView,
  //           ],
  //         ),
  //       ]
  //     ),
  //   );
  //   expect(tester.takeException(), isNull);
  //   expect(find.byType(ColoredBox), findsNWidgets(2));
  //
  //   await pumpWidgetWithoutViewWrapper(
  //     tester: tester,
  //     widget: ViewCollection(
  //         views: <Widget>[
  //           redView,
  //           ViewCollection(
  //             views: <Widget>[
  //               greenView,
  //             ],
  //           ),
  //         ]
  //     ),
  //   );
  //   expect(tester.takeException(), isNull);
  //   expect(find.byType(ColoredBox), findsNWidgets(2));
  // });
}

Future<void> pumpWidgetWithoutViewWrapper({required WidgetTester tester, required  Widget widget}) {
  tester.binding.attachRootWidget(widget);
  tester.binding.scheduleFrame();
  return tester.binding.pump();
}

class FakeView extends TestFlutterView{
  FakeView(FlutterView view, { this.viewId = 100 }) : super(
    view: view,
    platformDispatcher: view.platformDispatcher as TestPlatformDispatcher,
    display: view.display as TestDisplay,
  );

  @override
  final int viewId;
}

// TODO(goderbauer):  slot updates?
