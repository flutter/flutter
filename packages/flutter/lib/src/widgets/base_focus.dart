// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';

import 'focus_manager.dart';
import 'focus_scope.dart';
import 'framework.dart';
import 'gesture_detector.dart';

/// A widget that steals focus from other focusable nodes.
///
/// This is used to allow clicking outside of a textfield or other
/// editable text to "deselect" the text field without needing to
/// jump to another focusable widget.
class FocusTrap extends StatefulWidget {
  /// Create a new [FocusTrap] widget.
  const FocusTrap({
    required this.child,
    this.focusNode,
    Key? key
  }) : super(key: key);

  final Widget child;
  final FocusNode? focusNode;

  @override
  State<FocusTrap> createState() => _FocusTrapState();
}

class _FocusTrapState extends State<FocusTrap> {
  final Map<Type, GestureRecognizerFactory> _gestures = <Type, GestureRecognizerFactory>{};
  late FocusNode _focusNode;

  FocusNode get focusNode => widget.focusNode ?? _focusNode;

  void _stealFocus(TapDownDetails details) {
    if (details.kind != PointerDeviceKind.mouse)
      return;
    focusNode.requestFocus();
  }

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _gestures[TapGestureRecognizer] = GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
        () => TapGestureRecognizer(debugOwner: this),
        (TapGestureRecognizer instance) {
          instance
            .onTapDown = _stealFocus;
        },
      );
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      child: RawGestureDetector(
        child: widget.child,
        gestures: _gestures,
      ),
      focusNode: focusNode,
    );
  }
}
