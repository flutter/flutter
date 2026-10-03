// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// TODO(mattkae): remove invalid_use_of_internal_member ignore comment when this API is stable.
// See: https://github.com/flutter/flutter/issues/177586
// ignore_for_file: invalid_use_of_internal_member
// ignore_for_file: implementation_imports
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/_window.dart';
import 'package:flutter/src/widgets/_window_positioner.dart';

void main() {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    runWidget(
      WindowManager(
        initialWindows: <WindowEntry>[
          WindowEntry(
            controller: WindowController(
              size: const Size(800, 600),
              constraints: const BoxConstraints(minWidth: 640, minHeight: 480),
              title: 'Example Window',
            ),
            builder: (BuildContext context) => const MaterialApp(home: MyApp()),
          ),
        ],
      ),
    );
  } on UnsupportedError catch (e) {
    // TODO(mattkae): Remove this catch block when Windows tooltips are supported in tests.
    // For now, we need to catch the error so that the API smoke tests pass.
    runApp(
      MaterialApp(
        home: Scaffold(body: Center(child: Text(e.message ?? 'Unsupported'))),
      ),
    );
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() {
    return _MyAppState();
  }
}

class _MyAppState extends State<MyApp> {
  PopupWindowController? _popup;

  bool get _isShowing => !(_popup?.isDestroyed ?? true);

  // The anchorContext is below the NestedWindow, so NestedWindow.layoutInfoOf
  // reports the geometry of the button that the popup is anchored to.
  void _togglePopup(BuildContext anchorContext) {
    if (_isShowing) {
      _popup!.destroy();
      return;
    }
    final NestedWindowLayoutInfo info = NestedWindow.layoutInfoOf(
      anchorContext,
    );
    setState(() {
      _popup = PopupWindowController(
        parent: WindowScope.of(context),
        anchorRect: info.anchorRect,
        positioner: const WindowPositioner(
          parentAnchor: .right,
          childAnchor: .left,
        ),
      );
    });
  }

  @override
  void dispose() {
    _popup?.destroy();
    super.dispose();
  }

  Widget _buildPopupContent(BuildContext context, PopupWindowController popup) {
    return Material(
      color: Colors.black,
      child: Padding(
        padding: const .all(8),
        child: Column(
          mainAxisSize: .min,
          children: <Widget>[
            const Text(
              'This is a popup',
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: popup.destroy,
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final PopupWindowController? popup = _popup;
    return Center(
      child: NestedWindow(
        controller: popup,
        builder: _buildPopupContent,
        child: Builder(
          builder: (BuildContext anchorContext) => ElevatedButton(
            onPressed: () => _togglePopup(anchorContext),
            // The popup may also be destroyed by the platform, for example when
            // it loses focus, so the label listens to the popup directly.
            child: ListenableBuilder(
              listenable: Listenable.merge(<Listenable?>[popup]),
              builder: (BuildContext context, Widget? child) =>
                  Text(_isShowing ? 'Hide Popup' : 'Show Popup'),
            ),
          ),
        ),
      ),
    );
  }
}
