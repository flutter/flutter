// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';

/// Flutter code sample for a basic [CupertinoMenuAnchor].
void main() => runApp(const CupertinoMenuAnchorApp());

class CupertinoMenuAnchorApp extends StatelessWidget {
  const CupertinoMenuAnchorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      home: CupertinoPageScaffold(child: CupertinoMenuAnchorExample()),
    );
  }
}

class CupertinoMenuAnchorExample extends StatefulWidget {
  const CupertinoMenuAnchorExample({super.key});

  @override
  State<CupertinoMenuAnchorExample> createState() =>
      _CupertinoMenuAnchorExampleState();
}

class _CupertinoMenuAnchorExampleState
    extends State<CupertinoMenuAnchorExample> {
  // Optional: Create a focus node to allow focus traversal between the menu
  // button and the menu overlay.
  final FocusNode _buttonFocusNode = FocusNode(debugLabel: 'Menu Button');
  AnimationStatus _animationStatus = AnimationStatus.dismissed;

  @override
  void dispose() {
    _buttonFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Center(
          child: CupertinoMenuAnchor(
            onAnimationStatusChanged: (AnimationStatus status) {
              // Since we are only checking the animation status when the button
              // is pressed, we don't need to call setState here.
              _animationStatus = status;
            },
            childFocusNode: _buttonFocusNode,
            menuChildren: <Widget>[
              CupertinoMenuItem(
                onPressed: () {},
                subtitle: const Text('Subtitle'),
                trailing: const Icon(CupertinoIcons.star),
                child: const Text('Menu Item'),
              ),
            ],
            builder:
                (
                  BuildContext context,
                  MenuController controller,
                  Widget? child,
                ) {
                  return CupertinoButton(
                    sizeStyle: CupertinoButtonSize.small,
                    focusNode: _buttonFocusNode,
                    onPressed: () {
                      if (_animationStatus.isForwardOrCompleted) {
                        controller.close();
                      } else {
                        controller.open();
                      }
                    },
                    child: const Icon(CupertinoIcons.ellipsis_vertical_circle),
                  );
                },
          ),
        ),
      ],
    );
  }
}
