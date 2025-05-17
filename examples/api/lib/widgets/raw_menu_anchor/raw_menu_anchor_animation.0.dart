// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: public_member_api_docs

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

/// Flutter code sample for a [RawMenuAnchorAnimationApp] that animates a
/// [RawMenuAnchor] with a [SpringSimulation].
void main() {
  runApp(const RawMenuAnchorAnimationApp());
}

class AnimatedMenu extends StatefulWidget {
  const AnimatedMenu({super.key, required this.menuController});

  final MenuController menuController;

  @override
  State<AnimatedMenu> createState() => _AnimatedMenuState();
}

class _AnimatedMenuState extends State<AnimatedMenu>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  final MenuController _internalController = MenuController();

  SpringSimulation get forwardSpring => SpringSimulation(
    SpringDescription.withDampingRatio(mass: 1.0, stiffness: 150, ratio: 0.7),
    _animationController.value,
    1.0,
    0.0,
  );
  SpringSimulation get reverseSpring => SpringSimulation(
    SpringDescription.withDampingRatio(mass: 1.0, stiffness: 200, ratio: 0.7),
    _animationController.value,
    0.0,
    0.0,
  );

  @override
  void initState() {
    super.initState();
    // Use an unbounded animation controller so that simulations are not clamped.
    _animationController = AnimationController.unbounded(vsync: this);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _open(_) {
    // Call whenComplete() rather than whenCompleteOrCancel() to avoid marking
    // the menu as opened when the [AnimationStatus] moves from forward to
    // reverse.
    _internalController.open();
    setState(() {
      widget.menuController.animationStatus = AnimationStatus.forward;
    });
    _animationController.animateWith(forwardSpring).whenComplete(() {
      setState(() {
        widget.menuController.animationStatus = AnimationStatus.completed;
      });
    });
  }

  void _close([_]) {
    // Call whenComplete() rather than whenCompleteOrCancel() to avoid marking
    // the menu as closed when the [AnimationStatus] moves from reverse to
    // forward.
    setState(() {
      widget.menuController.animationStatus = AnimationStatus.reverse;
    });
    _animationController.animateBackWith(reverseSpring).whenComplete(() {
      _internalController.close();
      setState(() {
        widget.menuController.animationStatus = AnimationStatus.dismissed;
      });
    });
  }

  void _dismiss(_) {
    _close();
  }

  @override
  Widget build(BuildContext context) {
    return Actions(
      actions: <Type, Action<Intent>>{
        OpenMenuIntent: CallbackAction<OpenMenuIntent>(onInvoke: _open),
        CloseMenuIntent: CallbackAction<CloseMenuIntent>(onInvoke: _close),
        // Handle DismissIntent for dismiss requests dispathed from between
        // AnimatedMenu and its RawMenuAnchor.
        if (widget.menuController.isOpen)
          DismissIntent: CallbackAction<DismissIntent>(onInvoke: _dismiss),
        // Handle DismissMenuIntent for dismiss requests dispathed from within
        // the RawMenuAnchor.
        DismissMenuIntent: CallbackAction<DismissMenuIntent>(onInvoke: _dismiss),
      },
      child: _AttachMenuController(
        controller: widget.menuController,
        child: Builder(builder: _buildAnchor),
      )
    );
  }

  Widget _buildAnchor(BuildContext context) {
    return RawMenuAnchor(
      controller: _internalController,
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
              excluding: widget.menuController.animationStatus == AnimationStatus.reverse,
              child: TapRegion(
                groupId: info.tapRegionGroupId,
                onTapOutside: (PointerDownEvent event) {
                  widget.menuController.close();
                },
                child: ScaleTransition(
                  scale: _animationController.view,
                  child: FadeTransition(
                    opacity: _animationController.drive(
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
                        sizeFactor: _animationController.view,
                        fixedCrossAxisSizeFactor: 1.0,
                        child: SizedBox(
                          height: 200,
                          width: 150,
                          child: Text(
                            'ANIMATION STATUS:\n${_animationController.status.name}',
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
      child: FilledButton(
        onPressed: () {
          if (widget.menuController.animationStatus.isForwardOrCompleted) {
            widget.menuController.close();
          } else {
            widget.menuController.open();
          }
        },
        child: Text(widget.menuController.animationStatus.isForwardOrCompleted ? 'Close' : 'Open'),
      ),
    );
  }
}

// Attach the controller to the state.
//
// This widget ensures that the controller's attached context is within the
// scope of `Actions`.
class _AttachMenuController extends StatefulWidget {
  _AttachMenuController({required this.controller, required this.child});

  final MenuController controller;
  final Widget child;

  @override
  _AttachMenuControllerState createState() => _AttachMenuControllerState();
}

class _AttachMenuControllerState extends State<_AttachMenuController> {
  @override
  void initState() {
    super.initState();
    widget.controller.attach(context);
  }

  @override
  void didUpdateWidget(_AttachMenuController oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.detach(context);
      widget.controller.attach(context);
    }
  }

  @override
  void dispose() {
    widget.controller.detach(context);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class RawMenuAnchorAnimationApp extends StatefulWidget {
  const RawMenuAnchorAnimationApp({super.key});

  @override
  State<RawMenuAnchorAnimationApp> createState() => _RawMenuAnchorAnimationAppState();
}

class _RawMenuAnchorAnimationAppState extends State<RawMenuAnchorAnimationApp> {
  final MenuController controller = MenuController();

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
      home: Scaffold(body: Center(child: AnimatedMenu(menuController: controller))),
    );
  }
}
