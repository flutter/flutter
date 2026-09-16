// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show Display;

import 'package:flutter/src/foundation/_features.dart' show isWindowingEnabled;
import 'package:flutter/src/widgets/_window.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'multi_view_testing.dart';

class _StubWindowController extends WindowController {
  _StubWindowController(WidgetTester tester, {int viewId = 100}) : super.empty() {
    rootView = FakeView(tester.view, viewId: viewId);
  }

  @override
  Size get contentSize => Size.zero;

  @override
  String get title => 'Stub Window';

  @override
  bool get isActivated => true;

  @override
  bool get isMaximized => false;

  @override
  bool get isMinimized => false;

  @override
  bool get isFullscreen => false;

  @override
  void setSize(Size size) {}

  @override
  void setConstraints(BoxConstraints constraints) {}

  @override
  void setTitle(String title) {}

  @override
  void activate() {}

  @override
  void setMaximized(bool maximized) {}

  @override
  void setMinimized(bool minimized) {}

  @override
  void setFullscreen(bool fullscreen, {Display? display}) {}

  @override
  bool get isDestroyed => _destroyed;
  bool _destroyed = false;

  @override
  void destroy() {
    _destroyed = true;
  }
}

class _StubDialogWindowController extends DialogWindowController {
  _StubDialogWindowController(WidgetTester tester, {int viewId = 200}) : super.empty() {
    rootView = FakeView(tester.view, viewId: viewId);
  }

  @override
  BaseWindowController? get parent => null;

  @override
  Size get contentSize => Size.zero;

  @override
  String get title => 'Stub Dialog';

  @override
  bool get isActivated => true;

  @override
  bool get isMinimized => false;

  @override
  void setSize(Size size) {}

  @override
  void setConstraints(BoxConstraints constraints) {}

  @override
  void setTitle(String title) {}

  @override
  void activate() {}

  @override
  void setMinimized(bool minimized) {}

  @override
  bool get isDestroyed => _destroyed;
  bool _destroyed = false;

  @override
  void destroy() {
    _destroyed = true;
  }
}

class _Host extends StatefulWidget {
  const _Host({super.key, required this.dialogController});

  final DialogWindowController dialogController;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  bool showDialogWindow = false;
  String label = 'first';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        const Text('main', textDirection: TextDirection.ltr),
        if (showDialogWindow)
          DialogWindow(
            controller: widget.dialogController,
            child: Text(label, textDirection: TextDirection.ltr),
          ),
      ],
    );
  }
}

void main() {
  isWindowingEnabled = true;

  testWidgets('nested DialogWindow under WindowManager', (WidgetTester tester) async {
    final _StubWindowController main = _StubWindowController(tester);
    final _StubDialogWindowController dialog = _StubDialogWindowController(tester);
    addTearDown(main.dispose);
    addTearDown(dialog.dispose);

    final GlobalKey<_HostState> key = GlobalKey<_HostState>();

    await tester.pumpWidget(
      wrapWithView: false,
      WindowManager(
        initialWindows: <MountedWindow>[
          MountedWindow(
            controller: main,
            builder: (BuildContext context) => _Host(key: key, dialogController: dialog),
          ),
        ],
      ),
    );

    expect(find.text('main'), findsOneWidget);

    key.currentState!.setState(() {
      key.currentState!.showDialogWindow = true;
    });
    await tester.pump();
    await tester.pump();
    expect(find.text('first'), findsOneWidget);

    key.currentState!.setState(() {
      key.currentState!.label = 'second';
    });
    await tester.pump();
    await tester.pump();
    expect(find.text('second'), findsOneWidget);
    expect(find.text('first'), findsNothing);

    key.currentState!.setState(() {
      key.currentState!.showDialogWindow = false;
    });
    await tester.pump();
    await tester.pump();
    expect(find.text('second'), findsNothing);
  });
}
