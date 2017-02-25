// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

const TextStyle _kCupertinoButtonStyle = const TextStyle(
  fontFamily: '.SF UI Text',
  inherit: false,
  fontSize: 14.0,
  fontWeight: FontWeight.normal,
  color: const Color(0xFF007AFF),
  textBaseline: TextBaseline.alphabetic,
);

/// An iOS style button.
///
/// Takes in a text or an icon that fades out and in on touch. May optionally have an
/// invariant border.
///
/// See also:
///
///  * <https://developer.apple.com/ios/human-interface-guidelines/ui-controls/buttons/>
class CupertinoButton extends StatefulWidget {
  CupertinoButton({
    this.text,
    this.padding = 16.0,
    @required this.onPressed,
  });

  final String text;

  final double padding;

  /// The callback that is called when the button is tapped or otherwise activated.
  ///
  /// If this is set to null, the button will be disabled.
  final VoidCallback onPressed;

  /// Whether the button is enabled or disabled. Buttons are disabled by default. To
  /// enable a button, set its [onPressed] property to a non-null value.
  bool get enabled => onPressed != null;

  @override
  _CupertinoButtonState createState() => new _CupertinoButtonState();

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    if (!enabled)
      description.add('disabled');
  }
}

class _CupertinoButtonState extends State<CupertinoButton> with SingleTickerProviderStateMixin {

  AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = new AnimationController(
      duration: const Duration(milliseconds: 200),
      value: 1.0,
      vsync: this,
    );
  }

  @override
  Widget build(BuildContext context) {
    return new GestureDetector(
      onTapDown: config.enabled ? _handleTapDown : null,
      onTapUp: config.enabled ? _handleTapUp : null,
      onTap: config.enabled ? _handleTap : null,
      onTapCancel: config.enabled ? _handleTapCancel : null,

      child: new ConstrainedBox(
        constraints: new BoxConstraints(minWidth: 48.0, minHeight: 48.0),
        child: new Padding(
          padding: new EdgeInsets.all(config.padding),
          child: new AnimatedDefaultTextStyle(
            style: _kCupertinoButtonStyle,
            duration: const Duration(milliseconds: 200),
            child: new FadeTransition(
              opacity: new CurvedAnimation(
                parent: _animationController,
                curve: Curves.decelerate,
              ),
              child: new Text(
                config.text,
              )
            ),
          ),
        ),
      ),
    );
  }

  void _handleTapDown(TapDownDetails details) {
    _animationController.animateTo(0.2);
  }

  void _handleTapUp(TapUpDetails details) {
    _animationController.animateTo(1.0);
  }

  void _handleTapCancel() {
    _animationController.animateTo(1.0);
  }

  void _handleTap() {
    config.onPressed();
  }

}
