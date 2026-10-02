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
  TooltipWindowController? _tooltip;

  bool get _isShowing => !(_tooltip?.isDestroyed ?? true);

  // The anchorContext is below the NestedWindow, so NestedWindow.layoutInfoOf
  // reports the geometry of the widget that the tooltip is anchored to.
  void _showTooltip(BuildContext anchorContext) {
    if (_isShowing) {
      return;
    }
    final NestedWindowLayoutInfo info = NestedWindow.layoutInfoOf(
      anchorContext,
    );
    setState(() {
      _tooltip = TooltipWindowController(
        parent: WindowScope.of(context),
        anchorRect: info.anchorRect,
        positioner: const WindowPositioner(
          parentAnchor: WindowPositionerAnchor.right,
          childAnchor: WindowPositionerAnchor.left,
        ),
      );
    });
  }

  void _hideTooltip() {
    _tooltip?.destroy();
  }

  @override
  void dispose() {
    _tooltip?.destroy();
    super.dispose();
  }

  Widget _buildTooltipContent(
    BuildContext context,
    TooltipWindowController tooltip,
  ) {
    return Container(
      padding: const .all(8),
      color: Colors.black,
      child: const Text(
        'This is a tooltip',
        style: TextStyle(color: Colors.white),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TooltipWindowController? tooltip = _tooltip;
    return Center(
      child: NestedWindow(
        controller: tooltip,
        builder: _buildTooltipContent,
        child: Builder(
          builder: (BuildContext anchorContext) => MouseRegion(
            onEnter: (_) => _showTooltip(anchorContext),
            onExit: (_) => _hideTooltip(),
            cursor: SystemMouseCursors.click,
            child: ListenableBuilder(
              listenable: Listenable.merge(<Listenable?>[tooltip]),
              builder: (BuildContext context, Widget? child) =>
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    color: _isShowing ? Colors.blueAccent : Colors.blue,
                    padding: const .all(12),
                    child: child,
                  ),
              child: const Text(
                'Hover Me',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
