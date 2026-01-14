// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: public_member_api_docs

import 'dart:ui';

import 'package:flutter/material.dart';

/// Flutter code sample for a [RawMenuAnchor] that animates a simple menu using
/// [RawMenuAnchor.onOpenRequested] and [RawMenuAnchor.onCloseRequested].
void main() {
  runApp(const RawMenuAnchorAnimationApp());
}

class RawMenuAnchorAnimationExample extends StatefulWidget {
  const RawMenuAnchorAnimationExample({super.key});

  @override
  State<RawMenuAnchorAnimationExample> createState() =>
      _RawMenuAnchorAnimationExampleState();
}

class _RawMenuAnchorAnimationExampleState
    extends State<RawMenuAnchorAnimationExample>
    with SingleTickerProviderStateMixin {
  late final AnimationController animationController;
  final MenuController menuController = MenuController();
  AnimationStatus get _animationStatus => animationController.status;

  @override
  void initState() {
    super.initState();
    animationController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 300),
        )..addStatusListener((AnimationStatus status) {
          setState(() {
            // Rebuild to reflect animation status changes on the UI.
          });
        });
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  void _handleMenuOpenRequest(Offset? position, VoidCallback showOverlay) {
    // Mount or reposition the menu before animating the menu open.
    showOverlay();

    if (_animationStatus.isForwardOrCompleted) {
      // If the menu is already open or opening, the animation is already
      // running forward.
      return;
    }

    // Animate the menu into view.
    animationController.forward();
  }

  void _handleMenuCloseRequest(VoidCallback hideOverlay) {
    if (!_animationStatus.isForwardOrCompleted) {
      // If the menu is already closed or closing, do nothing.
      return;
    }

    // Animate the menu out of view.
    animationController.reverse().whenComplete(hideOverlay);
  }

  @override
  Widget build(BuildContext context) {
    return RawMenuAnchor(
      controller: menuController,
      onOpenRequested: _handleMenuOpenRequest,
      onCloseRequested: _handleMenuCloseRequest,
      overlayBuilder: (BuildContext context, RawMenuOverlayInfo info) {
        // Center the menu below the anchor.
        final Offset position = info.anchorRect.bottomCenter.translate(-75, 4);
        final ColorScheme colorScheme = ColorScheme.of(context);
        return Positioned(
          top: position.dy,
          left: position.dx,
          child: Semantics(
            explicitChildNodes: true,
            scopesRoute: true,
            child: ExcludeFocus(
              excluding: !_animationStatus.isForwardOrCompleted,
              child: TapRegion(
                groupId: info.tapRegionGroupId,
                onTapOutside: (PointerDownEvent event) {
                  menuController.close();
                },
                child: ScaleTransition(
                  scale: animationController.view,
                  child: FadeTransition(
                    opacity: animationController.drive(
                      Animatable<double>.fromCallback(
                        (double value) => clampDouble(value, 0, 1),
                      ),
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
                        child: SizedBox(
                          height: 200,
                          width: 150,
                          child: Text(
                            'ANIMATION STATUS:\n${_animationStatus.name}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: colorScheme.onPrimary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      builder:
          (BuildContext context, MenuController menuController, Widget? child) {
            return FilledButton(
              onPressed: () {
                if (_animationStatus.isForwardOrCompleted) {
                  menuController.close();
                } else {
                  menuController.open();
                }
              },
              child: _animationStatus.isForwardOrCompleted
                  ? const Text('Close')
                  : const Text('Open'),
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
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          dynamicSchemeVariant: DynamicSchemeVariant.vibrant,
        ),
      ),
      home: const Scaffold(
        body: Center(child: RawMenuAnchorAnimationExample()),
      ),
    );
  }
}
