// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Flutter code sample for [SimpleCascadingMenuApp].

void main() => runApp(const SimpleCascadingMenuApp());

/// A Simple Cascading Menu example using the [MenuAnchor] Widget.
class MyCascadingMenu extends StatefulWidget {
  const MyCascadingMenu({super.key});

  @override
  State<MyCascadingMenu> createState() => _MyCascadingMenuState();
}

class _MyCascadingMenuState extends State<MyCascadingMenu> {
  /// [FocusNode] for Menu Button.
  final FocusNode _buttonFocusNode = FocusNode(debugLabel: 'Menu Button');

  @override
  void dispose() {
    /// Disposes the focus node when state is disposed.
    _buttonFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      childFocusNode: _buttonFocusNode,
      menuChildren: <Widget>[
        MenuItemButton(
          child: const Text('Revert'),
          onPressed: () {},
        ),
        MenuItemButton(
          child: const Text('Setting'),
          onPressed: () {},
        ),
        MenuItemButton(
          child: const Text('Send Feedback'),
          onPressed: () {},
        ),
      ],
      builder: (_, MenuController controller, Widget? child) {
        return IconButton(
          focusNode: _buttonFocusNode,

          /// Opens or closes the menu based on its current state.
          onPressed: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },

          /// Displays Menu Button Icon.
          icon: const Icon(Icons.more_vert),
        );
      },
    );
  }
}

/// Top Level Application Widget
class SimpleCascadingMenuApp extends StatelessWidget {
  const SimpleCascadingMenuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('MenuAnchor Simple Example'),
          actions: const <Widget>[
            MyCascadingMenu(),
          ],
        ),
      ),
    );
  }
}
