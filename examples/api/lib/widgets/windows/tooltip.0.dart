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
    runWidget(
      RegularWindow(
        controller: RegularWindowController(
          preferredSize: const Size(800, 600),
          preferredConstraints: const BoxConstraints(
            minWidth: 640,
            minHeight: 480,
          ),
          title: 'Example Window',
        ),
        child: const MaterialApp(home: MyApp()),
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
  final GlobalKey _key = GlobalKey();
  TooltipWindowController? _tooltipController;

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = <Widget>[
      Text(
        key: _key,
        'Hover Me',
        style: const TextStyle(color: Colors.white),
      ),
    ];

    if (_tooltipController != null) {
      children.add(
        TooltipWindow(
          controller: _tooltipController!,
          child: Container(
            padding: const EdgeInsets.all(8),
            color: Colors.black,
            child: const Text(
              'This is a tooltip',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(
        () => _tooltipController = TooltipWindowController(
          parent: WindowScope.of(context),
          anchorRect: _getAnchorRect()!,
          positioner: const WindowPositioner(
            parentAnchor: WindowPositionerAnchor.right,
            childAnchor: WindowPositionerAnchor.left,
          ),
        ),
      ),
      onExit: (_) => setState(() {
        _tooltipController?.destroy();
        _tooltipController = null;
      }),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        color: _tooltipController != null ? Colors.blueAccent : Colors.blue,
        padding: const EdgeInsets.all(12),
        child: Row(children: children),
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
