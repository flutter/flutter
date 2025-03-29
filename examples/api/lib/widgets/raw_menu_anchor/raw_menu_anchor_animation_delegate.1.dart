// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: public_member_api_docs

import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Flutter code sample for a [RawMenuAnchorAnimationDelegate] that animates a
/// nested menu.
void main() {
  runApp(const NestedRawMenuAnchorAnimationDelegateApp());
}

class NestedRawMenuAnchorAnimationDelegateExample extends StatelessWidget {
  const NestedRawMenuAnchorAnimationDelegateExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Menu(
      panel: Builder(
        builder: (BuildContext context) {
          final MenuController rootMenuController = MenuController.maybeOf(context)!;
          return Align(
            alignment: Alignment.topRight,
            child: Column(
              children: <Widget>[
                for (int i = 0; i < 4; i++)
                  Menu(
                    panel: Builder(
                      builder: (BuildContext context) {
                        final String animationStatus =
                            MenuController.maybeAnimationStatusOf(context)!.name;
                        return SizedBox(
                          height: 120,
                          width: 120,
                          child: Center(
                            child: Text('Panel $i:\n$animationStatus', textAlign: TextAlign.center),
                          ),
                        );
                      },
                    ),
                    builder: (BuildContext context, MenuController controller) {
                      return MenuItemButton(
                        onFocusChange: (bool focused) {
                          if (focused) {
                            rootMenuController.closeChildren();
                            controller.open();
                          }
                        },
                        onPressed: () {
                          if (!controller.animationStatus.isForwardOrCompleted) {
                            rootMenuController.closeChildren();
                            controller.open();
                          } else {
                            controller.close();
                          }
                        },
                        trailingIcon: const Text('▶'),
                        child: Text('Submenu $i'),
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
      builder: (BuildContext context, MenuController controller) {
        return FilledButton(
          onPressed: () {
            if (controller.animationStatus.isForwardOrCompleted) {
              controller.close();
            } else {
              controller.open();
            }
          },
          child: const Text('Menu'),
        );
      },
    );
  }
}

class Menu extends StatefulWidget {
  const Menu({super.key, required this.panel, required this.builder});
  final Widget panel;
  final Widget Function(BuildContext, MenuController) builder;

  @override
  State<Menu> createState() => MenuState();
}

class MenuState extends State<Menu>
    with SingleTickerProviderStateMixin, RawMenuAnchorAnimationDelegate {
  final MenuController menuController = MenuController();
  late final AnimationController animationController;
  late final CurvedAnimation animation;
  bool get isSubmenu => MenuController.maybeOf(context) != null;

  @override
  void initState() {
    super.initState();
    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    animation = CurvedAnimation(parent: animationController, curve: Curves.easeOutQuart);
  }

  @override
  void dispose() {
    animationController.dispose();
    animation.dispose();
    super.dispose();
  }

  @override
  void handleMenuOpenRequest({ui.Offset? position}) {
    // Call whenComplete() rather than whenCompleteOrCancel() to avoid marking
    // the menu as opened when the AnimationStatus moves from forward to
    // reverse.
    animationController.forward().whenComplete(markMenuOpened);
  }

  @override
  void handleMenuCloseRequest() {
    // Animate the children of this menu closed.
    menuController.closeChildren();
    animationController.reverse().whenComplete(markMenuClosed);
  }

  @override
  Widget build(BuildContext context) {
    return RawMenuAnchor(
      controller: menuController,
      delegate: this,
      overlayBuilder: (BuildContext context, RawMenuOverlayInfo info) {
        final ui.Offset position =
            isSubmenu ? info.anchorRect.topRight : info.anchorRect.bottomLeft;
        final ColorScheme colorScheme = ColorScheme.of(context);
        return Positioned(
          top: position.dy,
          left: position.dx,
          child: Semantics(
            explicitChildNodes: true,
            scopesRoute: true,
            child: ExcludeFocus(
              // Remove focus while the menu is closing.
              excluding: animation.status == AnimationStatus.reverse,
              child: TapRegion(
                groupId: info.tapRegionGroupId,
                onTapOutside: (PointerDownEvent event) {
                  menuController.close();
                },
                child: FadeTransition(
                  opacity: animation,
                  child: Material(
                    elevation: 8,
                    clipBehavior: Clip.antiAlias,
                    borderRadius: BorderRadius.circular(8),
                    shadowColor: colorScheme.shadow,
                    child: SizeTransition(
                      axisAlignment: position.dx < 0 ? 1 : -1,
                      sizeFactor: animation,
                      fixedCrossAxisSizeFactor: 1.0,
                      child: widget.panel,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      builder: (BuildContext context, MenuController controller, Widget? child) {
        return widget.builder(context, controller);
      },
    );
  }
}

class NestedRawMenuAnchorAnimationDelegateApp extends StatelessWidget {
  const NestedRawMenuAnchorAnimationDelegateApp({super.key});

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
      home: const Scaffold(body: Center(child: NestedRawMenuAnchorAnimationDelegateExample())),
    );
  }
}
