// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: public_member_api_docs

import 'dart:ui' as ui;

import 'package:flutter/material.dart' hide MenuController, RawMenuAnchor, RawMenuOverlayInfo;
import 'package:flutter/physics.dart';

import 'raw_menu_anchor.dart';

/// Flutter code sample for a [RawMenuAnchor] that animates a menu with a
/// [SpringSimulation].
void main() {
  runApp(const RawMenuAnchorAnimationApp());
}

class RawMenuAnchorAnimationExample extends StatefulWidget {
  const RawMenuAnchorAnimationExample({super.key});

  @override
  State<RawMenuAnchorAnimationExample> createState() => _RawMenuAnchorAnimationExampleState();
}

class _RawMenuAnchorAnimationExampleState extends State<RawMenuAnchorAnimationExample>
    with SingleTickerProviderStateMixin {
  late final AnimationController animationController;
  final MenuController menuController = MenuController();

  bool get isOpenOrOpening {
    return animationController.isForwardOrCompleted;
  }

  @override
  void initState() {
    super.initState();
    // Use an unbounded animation controller to allow simulations to overshoot.
    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  void _handleCloseRequest() {
    animationController.reverse().whenComplete(() {
      menuController.close(transition: false);
    });
  }

  void _handleOpenRequest() {
    menuController.open(transition: false);
    animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return RawMenuAnchor(
      controller: menuController,
      onCloseRequested: _handleCloseRequest,
      onOpenRequested: _handleOpenRequest,
      overlayBuilder: (BuildContext context, RawMenuOverlayInfo info) {
        // Center the menu below the anchor.
        final ui.Offset position = info.anchorRect.bottomCenter.translate(-75, 4);
        final ColorScheme colorScheme = ColorScheme.of(context);
        return Positioned(
          top: position.dy,
          left: position.dx,
          child: Semantics(
            explicitChildNodes: true,
            scopesRoute: true,
            child: TapRegion(
              groupId: info.tapRegionGroupId,
              onTapOutside: (PointerDownEvent event) {
                menuController.close();
              },
              child: ScaleTransition(
                scale: animationController.view,
                child: FadeTransition(
                  opacity: animationController.drive(
                    Animatable<double>.fromCallback((double value) => ui.clampDouble(value, 0, 1)),
                  ),
                  child: Material(
                    elevation: 8,
                    clipBehavior: Clip.antiAlias,
                    borderRadius: BorderRadius.circular(16),
                    color: colorScheme.primary,
                    child: SizeTransition(
                      axisAlignment: -1,
                      sizeFactor: animationController.view,
                      fixedCrossAxisSizeFactor: 1.0,
                      child: const SizedBox(height: 200, width: 150),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      builder: (BuildContext context, MenuController menuController, Widget? child) {
        return FilledButton(
          onPressed: () {
            if (isOpenOrOpening) {
              menuController.close();
            } else {
              menuController.open();
            }
          },
          child: const Text('Toggle'),
        );
      },
    );
  }
}

class RawMenuAnchorAnimationApp extends StatelessWidget {
  const RawMenuAnchorAnimationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.from(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          dynamicSchemeVariant: DynamicSchemeVariant.vibrant,
        ),
      ),
      home: const Scaffold(body: Center(child: RawMenuAnchorAnimationExample())),
    );
  }
}
