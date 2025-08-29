// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';

/// Flutter code sample for a [CupertinoMenuAnchor] that shows a basic menu.
void main() => runApp(const CupertinoMenuAnchorApp());

class CupertinoMenuAnchorApp extends StatelessWidget {
  const CupertinoMenuAnchorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      theme: CupertinoThemeData(brightness: Brightness.light, primaryColor: Color(0xFF007AFF)),
      home: CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(middle: Text('CupertinoMenuAnchor Example')),
        child: CupertinoMenuAnchorExample(),
      ),
    );
  }
}

class CupertinoMenuAnchorExample extends StatefulWidget {
  const CupertinoMenuAnchorExample({super.key});

  @override
  State<CupertinoMenuAnchorExample> createState() => _CupertinoMenuAnchorExampleState();
}

class _CupertinoMenuAnchorExampleState extends State<CupertinoMenuAnchorExample> {
  // Optional: Create a focus node to control the menu button.
  final FocusNode _buttonFocusNode = FocusNode(debugLabel: 'Menu Button');
  String _pressedItem = '';
  AnimationStatus _status = AnimationStatus.dismissed;

  @override
  void dispose() {
    _buttonFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          CupertinoMenuAnchor(
            onAnimationStatusChange: (AnimationStatus status) {
              _status = status;
            },
            childFocusNode: _buttonFocusNode,
            menuChildren: <Widget>[
              CupertinoMenuItem(
                onPressed: () {
                  setState(() {
                    _pressedItem = 'Regular Item';
                  });
                },
                subtitle: const Text('Subtitle'),
                panActivationDelay: const Duration(milliseconds: 500),
                child: const Text('Regular Item'),
              ),
              CupertinoMenuItem(
                onPressed: () {
                  setState(() {
                    _pressedItem = 'Colorful Item';
                  });
                },
                decoration: const WidgetStateProperty<BoxDecoration>.fromMap(
                  <WidgetStatesConstraint, BoxDecoration>{
                    WidgetState.dragged: BoxDecoration(color: Color(0x400000FF)),
                    WidgetState.pressed: BoxDecoration(color: Color(0x4000FF00)),
                    WidgetState.hovered: BoxDecoration(color: Color(0x40FF0000)),
                    WidgetState.focused: BoxDecoration(color: Color(0x4000FFFF)),
                    WidgetState.any: BoxDecoration(color: Color(0x00000000)),
                  },
                ),
                child: const Text('Colorful Item'),
              ),
              CupertinoMenuItem(
                trailing: const Icon(CupertinoIcons.delete),
                isDestructiveAction: true,
                child: const Text('Destructive Item'),
                onPressed: () {
                  setState(() {
                    _pressedItem = 'Destructive Item';
                  });
                },
              ),
            ],
            builder: (BuildContext context, MenuController controller, Widget? child) {
              return CupertinoButton.filled(
                focusNode: _buttonFocusNode,
                onPressed: () {
                  if (_status.isForwardOrCompleted) {
                    controller.close();
                  } else {
                    controller.open();
                  }
                },
                child: const Text('OPEN MENU'),
              );
            },
          ),
          if (_pressedItem.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Text(
                'You Pressed: $_pressedItem',
                style: CupertinoTheme.of(context).textTheme.textStyle,
              ),
            ),
        ],
      ),
    );
  }
}
