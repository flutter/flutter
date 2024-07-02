// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Flutter code sample for [CupertinoMenuAnchor] that creates a
/// navigation history menu similar to the navigation history stack on iOS.
void main() {
  runApp(const CupertinoHistoryMenuApp());
}

class CupertinoHistoryMenuApp extends StatelessWidget {
  const CupertinoHistoryMenuApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      localizationsDelegates: <LocalizationsDelegate<dynamic>>[
        DefaultMaterialLocalizations.delegate,
      ],
      home: RecursiveView(depth: 0),
    );
  }
}

/// A wrapper that shows a navigation history menu when the back button is
/// pressed down.
class CupertinoHistoryMenu extends StatelessWidget {
  const CupertinoHistoryMenu({
    super.key,
    required this.depth,
  });

  final int depth;

  @override
  Widget build(BuildContext context) {
    final CupertinoMenuController controller = CupertinoMenuController();

    // Close the menu if the route is popped.
    return PopScope(
      onPopInvoked: (bool popped) {
        if (popped) {
          controller.close();
        }
      },
      child: CupertinoMenuAnchor(
        controller: controller,
        menuChildren: <Widget>[
          // Build a list of menu items that represent the navigation history.
          for (int i = 0; i < depth; i++)
            CupertinoMenuItem(
              child: Text('View $i'),
              onPressed: () {
                controller.close();
                // Pop to the selected view
                Navigator.popUntil(
                  context,
                  (Route<dynamic> route) {
                    return route.settings.name == 'View $i' ||
                           route.settings.name == '/'; // Home route
                  },
                );
              },
            ),
        ],
        builder: (
          BuildContext context,
          CupertinoMenuController controller,
          Widget? child,
        ) {
          return GestureDetector(
            // Long press can't be used here because it would cancel the pan
            // gesture.
            onTapDown: (TapDownDetails details) {
              if (controller.menuStatus
                  case MenuStatus.opening || MenuStatus.opened) {
                controller.close();
              } else {
                controller.open();
              }
            },
            child: child,
          );
        },
        child: CupertinoNavigationBarBackButton(
            previousPageTitle: 'View ${depth - 1}',
            onPressed: () {
              Navigator.maybePop(context);
            },
        ),
      ),
    );
  }
}

/// A view that pushes itself onto the navigation stack.
class RecursiveView extends StatelessWidget {
  const RecursiveView({super.key, required this.depth});
  final int depth;

  @override
  Widget build(BuildContext context) {
    Widget? leading;
    if (depth != 0) {
      // Wrap the back button with a menu that shows the navigation history.
      leading = CupertinoHistoryMenu(depth: depth);
    }
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        leading: leading,
        middle: Text('View $depth'),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Text(
            '''Push some views and long press the '''
            '''\nback button to show a navigation history menu.''',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: CupertinoColors.systemGreen,
            ),
          ),
          const SizedBox(height: 32),
          Center(
            child: Hero(
              tag: 'push_button',
              child: CupertinoButton.filled(
                child: const Text('Push Next View'),
                onPressed: () {
                  _pushNextPage(context);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _pushNextPage(BuildContext context) {
    final int nextDepth = depth + 1;
    Navigator.of(context).push(
      CupertinoPageRoute<void>(
        settings: RouteSettings(name: 'View $nextDepth'),
        builder: (BuildContext context) {
          return RecursiveView(depth: nextDepth);
        },
      ),
    );
  }
}
