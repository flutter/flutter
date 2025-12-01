// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: invalid_use_of_internal_member
// ignore_for_file: implementation_imports

import 'package:flutter/material.dart';
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
    _animationController.dispose();
    super.dispose();
  }

  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();
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
        final double scale = 1.0 + (0.05 * _animationController.value);
        return Transform.scale(
          scale: scale,
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0x4D000000),
                  blurRadius: 12.0,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Color(0x33FFFFFF),
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(8),
                  child: const Icon(
                    Icons.info,
                    color: Color(0xFFFFFFFF),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Tooltip Window',
                  style: TextStyle(
                    color: Color(0xFFFFFFFF),
                    fontSize: 16.0,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
