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

final TextStyle _kCupertinoDisabledButtonStyle = _kCupertinoButtonStyle.copyWith(
  color: const Color(0xFFC4C4C4),
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
    this.padding: const EdgeInsets.all(16.0),
    @required this.onPressed,
  });

  final String text;

  final EdgeInsets padding;

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

  void _handleTapDown(TapDownDetails details) {
    _animationController.animateTo(0.2);
  }

  void _handleTapUp(TapUpDetails details) {
    _animationController.animateTo(1.0);
  }

  void _handleTapCancel() {
    _animationController.animateTo(1.0);
  }

  @override
  Widget build(BuildContext context) {
    final bool enabled = config.enabled;
    return new GestureDetector(
      onTapDown: enabled ? _handleTapDown : null,
      onTapUp: enabled ? _handleTapUp : null,
      onTapCancel: enabled ? _handleTapCancel : null,
      onTap: config.onPressed,

      child: new ConstrainedBox(
        constraints: new BoxConstraints(minWidth: 48.0, minHeight: 48.0),
        child: new Padding(
          padding: config.padding,
          child: new FadeTransition(
            opacity: new CurvedAnimation(
              parent: _animationController,
              curve: Curves.decelerate,
            ),
            child: new Text(
              config.text,
              style: enabled ? _kCupertinoButtonStyle : _kCupertinoDisabledButtonStyle,
            ),
          ),
        ),
      ),
    );
  }

}
