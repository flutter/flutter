// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: public_member_api_docs

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

/// Flutter code sample for a [RawMenuAnchor] that animates a nested menu using
/// [RawMenuAnchor.onOpenRequested] and [RawMenuAnchor.onCloseRequested].
void main() {
  runApp(const RawMenuAnchorSubmenuAnimationApp());
}

/// Signature for the function that builds a [Menu]'s contents.
///
/// The [animationStatus] parameter indicates the current state of the menu
/// animation, which can be used to adjust the appearance of the menu panel.
typedef MenuPanelBuilder = Widget Function(BuildContext context, AnimationStatus animationStatus);

/// Signature for the function that builds a [Menu]'s anchor button.
///
/// The [MenuController] can be used to open and close the menu.
///
/// The [animationStatus] indicates the current state of the menu animation,
/// which can be used to adjust the appearance of the menu panel.
typedef MenuButtonBuilder =
    Widget Function(
      BuildContext context,
      MenuController controller,
      AnimationStatus animationStatus,
    );

class RawMenuAnchorSubmenuAnimationExample extends StatelessWidget {
  const RawMenuAnchorSubmenuAnimationExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Menu(
      panelBuilder: (BuildContext context, AnimationStatus animationStatus) {
        final MenuController rootMenuController = MenuController.maybeOf(context)!;
        return Align(
          alignment: Alignment.topRight,
          child: Column(
            children: <Widget>[
              for (int i = 0; i < 4; i++)
                Menu(
                  panelBuilder: (BuildContext context, AnimationStatus status) {
                    return SizedBox(
                      height: 120,
                      width: 120,
                      child: Center(
                        child: Text('Panel $i:\n${status.name}', textAlign: TextAlign.center),
                      ),
                    );
                  },
                  buttonBuilder:
                      (
                        BuildContext context,
                        MenuController controller,
                        AnimationStatus animationStatus,
                      ) {
                        return MenuItemButton(
                          onFocusChange: (bool focused) {
                            if (focused) {
                              rootMenuController.closeChildren();
                              controller.open();
                            }
                          },
                          onPressed: () {
                            if (!animationStatus.isForwardOrCompleted) {
                              rootMenuController.closeChildren();
                              controller.open();
                            } else {
                              controller.close();
                            }
                          },
                          trailingIcon: const Icon(Icons.arrow_forward),
                          child: Text('Submenu $i'),
                        );
                      },
                ),
            ],
          ),
        );
      },
      buttonBuilder:
          (BuildContext context, MenuController controller, AnimationStatus animationStatus) {
            return FilledButton(
              onPressed: () {
                if (animationStatus.isForwardOrCompleted) {
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
  const Menu({super.key, required this.panelBuilder, required this.buttonBuilder});
  final MenuPanelBuilder panelBuilder;
  final MenuButtonBuilder buttonBuilder;

  @override
  State<Menu> createState() => MenuState();
}

class MenuState extends State<Menu> with SingleTickerProviderStateMixin {
  final MenuController menuController = MenuController();
  late final AnimationController animationController;
  late final CurvedAnimation animation;
  bool get isSubmenu => MenuController.maybeOf(context) != null;
  AnimationStatus get animationStatus => animationController.status;

  @override
  void initState() {
    super.initState();
    animationController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 200))
          ..addStatusListener((AnimationStatus status) {
            if (mounted) {
              setState(() {
                // Rebuild to reflect animation status changes.
              });
            }
          });

    animation = CurvedAnimation(parent: animationController, curve: Curves.easeOutQuart);
  }

  @override
  void dispose() {
    animationController.dispose();
    animation.dispose();
    super.dispose();
  }

  void _handleMenuOpenRequest(Offset? position, VoidCallback showOverlay) {
    // Mount or reposition the menu before animating the menu open.
    showOverlay();

    if (animationStatus.isForwardOrCompleted) {
      // If the menu is already open or opening, the animation is already
      // running forward.
      return;
    }

    // Animate the menu into view.
    animationController.forward();
  }

  void _handleMenuCloseRequest(VoidCallback hideOverlay) {
    if (!animationStatus.isForwardOrCompleted) {
      // If the menu is already closed or closing, do nothing.
      return;
    }

    // Animate the menu's children out of view.
    menuController.closeChildren();

    // Animate the menu out of view.
    animationController.reverse().whenComplete(hideOverlay);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      role: SemanticsRole.menu,
      child: RawMenuAnchor(
        controller: menuController,
        onOpenRequested: _handleMenuOpenRequest,
        onCloseRequested: _handleMenuCloseRequest,
        overlayBuilder: (BuildContext context, RawMenuOverlayInfo info) {
          final ui.Offset position = isSubmenu
              ? info.anchorRect.topRight
              : info.anchorRect.bottomLeft;
          final ColorScheme colorScheme = ColorScheme.of(context);
          return Positioned(
            top: position.dy,
            left: position.dx,
            child: Semantics(
              explicitChildNodes: true,
              scopesRoute: true,
              // Remove focus while the menu is closing.
              child: ExcludeFocus(
                excluding: !animationStatus.isForwardOrCompleted,
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
                        child: widget.panelBuilder(context, animationStatus),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
        builder: (BuildContext context, MenuController controller, Widget? child) {
          return widget.buttonBuilder(context, controller, animationStatus);
        },
      ),
    );
  }
}

class RawMenuAnchorSubmenuAnimationApp extends StatelessWidget {
  const RawMenuAnchorSubmenuAnimationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.from(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          dynamicSchemeVariant: DynamicSchemeVariant.vibrant,
        ),
      ),
      home: const Scaffold(body: Center(child: RawMenuAnchorSubmenuAnimationExample())),
    );
  }
}
