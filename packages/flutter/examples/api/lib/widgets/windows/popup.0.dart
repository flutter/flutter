// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// TODO(mattkae): remove invalid_use_of_internal_member ignore comment when this API is stable.
// See: https://github.com/flutter/flutter/issues/177586
// TODO(mattkae): refactor this example for better widget position tracking
// This positioning logic is simpler than you might want in production. See https://github.com/flutter/flutter/issues/178829.
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

class _CallbackPopupDelegate extends PopupWindowControllerDelegate {
  _CallbackPopupDelegate({required this.onDestroyCallback});

  final VoidCallback onDestroyCallback;

  @override
  void onWindowDestroyed() {
    onDestroyCallback();
  }
}

class _MyAppState extends State<MyApp> {
  final GlobalKey _key = GlobalKey();
  PopupWindowController? _popupController;

  void _showPopup() {
    final PopupWindowController controller = PopupWindowController(
      parent: WindowScope.of(context),
      anchorRect: _getAnchorRect()!,
      positioner: const WindowPositioner(
        parentAnchor: .right,
        childAnchor: .left,
      ),
      delegate: _CallbackPopupDelegate(
        onDestroyCallback: () {
          if (mounted) {
            setState(() {
              _popupController = null;
            });
          }
        },
      ),
    );
    mountToplevelWindow(
      context: context,
      entry: WindowEntry(
        controller: controller,
        builder: (BuildContext context) => MaterialApp(
          builder: (BuildContext context, Widget? child) => Material(
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
                    onPressed: controller.destroy,
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    setState(() {
      _popupController = controller;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          key: _key,
          onPressed: _popupController == null ? _showPopup : null,
          child: const Text('Show Popup'),
        ),
      ),
    );
  }

  Rect? _getAnchorRect() {
    final RenderBox? renderBox =
        _key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final Offset position = renderBox.localToGlobal(Offset.zero);
      final Size size = renderBox.size;
      return position & size; // creates a Rect
    }

    return null;
  }
}
