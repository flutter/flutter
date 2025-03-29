// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: public_member_api_docs

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

/// Flutter code sample for a [RawMenuAnchorAnimationDelegate] that animates a
/// [RawMenuAnchor] with a [SpringSimulation].
void main() {
  runApp(const RawMenuAnchorAnimationDelegateApp());
}

class _AnimationDelegate extends RawMenuAnchorAnimationDelegate {
  _AnimationDelegate({required this.animationController});

  final AnimationController animationController;
  SpringSimulation get forwardSpring => SpringSimulation(
    SpringDescription.withDampingRatio(mass: 1.0, stiffness: 150, ratio: 0.7),
    animationController.value,
    1.0,
    0.0,
  );
  SpringSimulation get reverseSpring => SpringSimulation(
    SpringDescription.withDampingRatio(mass: 1.0, stiffness: 200, ratio: 0.7),
    animationController.value,
    0.0,
    0.0,
  );

  @override
  void handleMenuOpenRequest({ui.Offset? position}) {
    // Call whenComplete() rather than whenCompleteOrCancel() to avoid marking
    // the menu as opened when the [AnimationStatus] moves from forward to
    // reverse.
    animationController.animateWith(forwardSpring).whenComplete(markMenuOpened);
  }

  @override
  void handleMenuCloseRequest() {
    // Call whenComplete() rather than whenCompleteOrCancel() to avoid marking
    // the menu as closed when the [AnimationStatus] moves from reverse to
    // forward.
    animationController.animateBackWith(reverseSpring).whenComplete(markMenuClosed);
  }
}

class RawMenuAnchorAnimationDelegateExample extends StatefulWidget {
  const RawMenuAnchorAnimationDelegateExample({super.key});

  @override
  State<RawMenuAnchorAnimationDelegateExample> createState() => _RawMenuAnchorAnimationDelegateExampleState();
}

class _RawMenuAnchorAnimationDelegateExampleState extends State<RawMenuAnchorAnimationDelegateExample>
    with SingleTickerProviderStateMixin {
  late final AnimationController animationController;
  late final RawMenuAnchorAnimationDelegate _menuAnimator = _AnimationDelegate(
    animationController: animationController,
  );
  final MenuController menuController = MenuController();

  @override
  void initState() {
    super.initState();
    // Use an unbounded animation controller so that simulations are not clamped.
    animationController = AnimationController.unbounded(vsync: this);
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RawMenuAnchor(
      controller: menuController,
      delegate: _menuAnimator,
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
            child: ExcludeFocus(
              excluding: MenuController.maybeAnimationStatusOf(context) == AnimationStatus.reverse,
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
                        (double value) => ui.clampDouble(value, 0, 1),
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
                            'ANIMATION STATUS:\n${animationController.status.name}',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: colorScheme.onPrimary, fontSize: 12),
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
      builder: (BuildContext context, MenuController menuController, Widget? child) {
        return FilledButton(
          onPressed: () {
            if (menuController.animationStatus.isForwardOrCompleted) {
              menuController.close();
            } else {
              menuController.open();
            }
          },
          child: Text(menuController.animationStatus.isForwardOrCompleted ? 'Close' : 'Open'),
        );
      },
    );
  }
}

class RawMenuAnchorAnimationDelegateApp extends StatelessWidget {
  const RawMenuAnchorAnimationDelegateApp({super.key});

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
      home: const Scaffold(body: Center(child: RawMenuAnchorAnimationDelegateExample())),
    );
  }
}
