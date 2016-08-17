// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

import 'colors.dart';
import 'debug.dart';
import 'icon.dart';
import 'icons.dart';
import 'icon_button.dart';
import 'theme.dart';

/// A widget representing a rotating expand/collapse button. The icon rotates
/// 180 deg when pressed, then reverts the animation on a second press.
/// The underlying icon is [Icons.expand_more].
///
/// See [IconButton] for a more general implementation of a pressable button
/// with an icon.
class ExpandIcon extends StatefulWidget {
  /// Creates an [ExpandIcon] with the given padding, and a callback that is
  /// triggered when the icon is pressed.
  ExpandIcon({
    Key key,
    this.size: 24.0,
    @required this.onPressed,
    this.padding: const EdgeInsets.all(8.0)
  }) : super(key: key) {
    assert(this.size != null);
    assert(this.padding != null);
  }

  /// The size of the icon.
  ///
  /// This property must not be null. It defaults to 24.0.
  final double size;

  /// The callback triggered when the icon is pressed and the state changes
  /// between expanded and collapsed.
  ///
  /// If this is set to null, the button will be disabled.
  final ValueChanged<bool> onPressed;

  /// The padding around the icon. The entire padded icon will reactb to input
  /// gestures.
  ///
  /// This property must not be null. It defaults to 8.0 padding on all sides.
  final EdgeInsets padding;

  @override
  _ExpandIconState createState() => new _ExpandIconState();
}

class _ExpandIconState extends State<ExpandIcon> {
  AnimationController _controller;
  Animation<double> _iconTurns;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = new AnimationController(duration: kThemeAnimationDuration);
    _iconTurns = new Tween<double>(begin: 0.0, end: 0.5).animate(
      new CurvedAnimation(
        parent: _controller,
        curve: Curves.fastOutSlowIn
      )
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handlePressed() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded)
        _controller.forward();
      else
        _controller.reverse();
    });

    if (config.onPressed != null)
      config.onPressed(_isExpanded);
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterial(context));
    return new IconButton(
      padding: config.padding,
      color: Colors.black38,
      onPressed: config.onPressed == null ? null : _handlePressed,
      icon: new RotationTransition(
        turns: _iconTurns,
        child: new Icon(Icons.expand_more)
      )
    );
  }
}
