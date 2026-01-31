// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: invalid_use_of_internal_member
// ignore_for_file: implementation_imports

import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/_window.dart';

class TooltipWindowContent extends StatelessWidget {
  /// Creates a tooltip window widget.
  const TooltipWindowContent({super.key, required this.controller});

  /// Controller for this widget.
  final TooltipWindowController controller;

  @override
  Widget build(BuildContext context) {
    return RepeatingAnimationBuilder(
      animatable: TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          weight: 50.0,
        ),
        TweenSequenceItem(
          tween: Tween<double>(begin: 1.0, end: 0.0),
          weight: 50.0,
        ),
      ]),
      duration: const Duration(seconds: 1),
      builder: (context, double value, Widget? child) {
        final double padding = 20 + value * 16;
        return Container(
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
          padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding),
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
        );
      },
    );
  }
}
