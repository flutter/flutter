// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: invalid_use_of_internal_member
// ignore_for_file: implementation_imports

import 'package:flutter/widgets.dart';
import 'package:flutter/src/widgets/_window.dart';

class TooltipWindowContent extends StatefulWidget {
  /// Creates a tooltip window widget.
  /// [controller] the controller for this window
  /// [child] the content to render into this window
  /// [key] the key for this widget
  const TooltipWindowContent({super.key, required this.controller});

  /// Controller for this widget.
  final TooltipWindowController controller;

  @override
  State<TooltipWindowContent> createState() => _TooltipWindowContentState();
}

class _TooltipWindowContentState extends State<TooltipWindowContent>
    with SingleTickerProviderStateMixin {
  @override
  void dispose() {
    widget.controller.destroy();
    _animationController.dispose();
    super.dispose();
  }

  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    // Ensure the view is created before rendering.
    Future<void>.delayed(const Duration(seconds: 10), () {
      widget.controller.destroy();
    });
    _animationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _animationController.repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, _) {
        final double padding =
            20 + (16.0 * _animationController.value).ceilToDouble() / 1.0;
        // print('Padding: $padding');
        return DefaultTextStyle(
          style: const TextStyle(
            color: Color(0xFF000000),
            fontSize: 16.0,
            fontWeight: FontWeight.w500,
          ),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF444444), width: 1.0),
              color: const Color(0xFFFF55FF),
              borderRadius: BorderRadius.circular(14.0),
            ),
            padding: EdgeInsets.all(padding),
            child: Text('Tooltip Window'),
          ),
        );
      },
    );
  }
}
