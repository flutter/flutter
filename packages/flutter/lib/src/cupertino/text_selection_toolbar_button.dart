// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'button.dart';
import 'colors.dart';

const TextStyle _kToolbarButtonFontStyle = TextStyle(
  inherit: false,
  fontSize: 14.0,
  letterSpacing: -0.15,
  fontWeight: FontWeight.w400,
);

// Colors extracted from https://developer.apple.com/design/resources/.
// TODO(LongCatIsLooong): https://github.com/flutter/flutter/issues/41507.
const Color _kToolbarBackgroundColor = Color(0xEB202020);

// Eyeballed value.
const EdgeInsets _kToolbarButtonPadding = EdgeInsets.symmetric(vertical: 16.0, horizontal: 18.0);

/// A button in the style of the iOS text selection toolbar buttons.
class CupertinoTextSelectionToolbarButton extends StatelessWidget {
  /// Create an instance of [CupertinoTextSelectionToolbarButton].
  const CupertinoTextSelectionToolbarButton({
    Key? key,
    this.onPressed,
    required this.child,
  }) : super(key: key);

  /// The child of this button.
  ///
  /// Usually a [Text] or an [Icon].
  final Widget child;

  /// Called when this button is pressed.
  final VoidCallback? onPressed;

  /// Returns a [Text] widget in the style of the iOS text selection toolbar
  /// buttons.
  ///
  /// Pass the resulting widget into the [child] parameter when using a
  /// CupertinoTextSelectionToolbarButton in a CupertinoTextSelectionToolbar.
  static Text getText(String string, [bool enabled = true]) {
    return Text(
      string,
      overflow: TextOverflow.ellipsis,
      style: _kToolbarButtonFontStyle.copyWith(
        color: enabled ? CupertinoColors.white : CupertinoColors.inactiveGray,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      child: child,
      borderRadius: null,
      color: _kToolbarBackgroundColor,
      disabledColor: _kToolbarBackgroundColor,
      onPressed: onPressed,
      padding: _kToolbarButtonPadding,
      pressedOpacity: onPressed == null ? 1.0 : 0.7,
    );
  }
}
