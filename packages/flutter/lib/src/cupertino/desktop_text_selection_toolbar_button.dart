// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import 'button.dart';
import 'colors.dart';
import 'text_selection_toolbar_button.dart';
import 'theme.dart';

// These values were measured from a screenshot of TextEdit on MacOS 10.15.7 on
// a Macbook Pro.
const TextStyle _kToolbarButtonFontStyle = TextStyle(
  inherit: false,
  fontSize: 14.0,
  letterSpacing: -0.15,
  fontWeight: FontWeight.w400,
);

// This value was measured from a screenshot of TextEdit on MacOS 10.15.7 on a
// Macbook Pro.
const EdgeInsets _kToolbarButtonPadding = EdgeInsets.fromLTRB(
  20.0,
  0.0,
  20.0,
  3.0,
);

/// A button in the style of the Mac context menu buttons.
class CupertinoDesktopTextSelectionToolbarButton extends StatefulWidget {
  /// Creates an instance of CupertinoDesktopTextSelectionToolbarButton.
  ///
  /// [child] cannot be null.
  const CupertinoDesktopTextSelectionToolbarButton({
    super.key,
    required this.onPressed,
    required Widget this.child,
  }) : buttonItem = null;

  /// Create an instance of [CupertinoDesktopTextSelectionToolbarButton] whose child is
  /// a [Text] widget styled like the default Mac context menu button.
  CupertinoDesktopTextSelectionToolbarButton.text({
    super.key,
    required BuildContext context,
    required this.onPressed,
    required String text,
  }) : buttonItem = null,
       child = Text(
         text,
         overflow: TextOverflow.ellipsis,
         style: _kToolbarButtonFontStyle.copyWith(
           color: const CupertinoDynamicColor.withBrightness(
             color: CupertinoColors.black,
             darkColor: CupertinoColors.white,
           ).resolveFrom(context),
         ),
       );

  /// Create an instance of [CupertinoDesktopTextSelectionToolbarButton] from
  /// the given [ContextMenuButtonItem].
  ///
  /// [buttonItem] cannot be null.
  CupertinoDesktopTextSelectionToolbarButton.buttonItem({
    super.key,
    required ContextMenuButtonItem this.buttonItem,
  }) : onPressed = buttonItem.onPressed,
       child = null;

  /// {@macro flutter.cupertino.CupertinoTextSelectionToolbarButton.onPressed}
  final VoidCallback onPressed;

  /// {@macro flutter.cupertino.CupertinoTextSelectionToolbarButton.child}
  final Widget? child;

  /// {@macro flutter.cupertino.CupertinoTextSelectionToolbarButton.onPressed}
  final ContextMenuButtonItem? buttonItem;

  @override
  State<CupertinoDesktopTextSelectionToolbarButton> createState() => _CupertinoDesktopTextSelectionToolbarButtonState();
}

class _CupertinoDesktopTextSelectionToolbarButtonState extends State<CupertinoDesktopTextSelectionToolbarButton> {
  bool _isHovered = false;

  void _onEnter(PointerEnterEvent event) {
    setState(() {
      _isHovered = true;
    });
  }

  void _onExit(PointerExitEvent event) {
    setState(() {
      _isHovered = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Widget child = widget.child ?? Text(
      CupertinoTextSelectionToolbarButton.getButtonLabel(context, widget.buttonItem!),
      overflow: TextOverflow.ellipsis,
      style: _kToolbarButtonFontStyle.copyWith(
        color: const CupertinoDynamicColor.withBrightness(
          color: CupertinoColors.black,
          darkColor: CupertinoColors.white,
        ).resolveFrom(context),
      ),
    );
    return SizedBox(
      width: double.infinity,
      child: MouseRegion(
        onEnter: _onEnter,
        onExit: _onExit,
        child: CupertinoButton(
          alignment: Alignment.centerLeft,
          borderRadius: null,
          color: _isHovered ? CupertinoTheme.of(context).primaryColor : null,
          minSize: 0.0,
          onPressed: widget.onPressed,
          padding: _kToolbarButtonPadding,
          pressedOpacity: 0.7,
          child: child,
        ),
      ),
    );
  }
}
