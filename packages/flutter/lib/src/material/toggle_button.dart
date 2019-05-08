// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/src/material/debug.dart';
import 'package:flutter/widgets.dart';

import 'colors.dart';
import 'ink_well.dart';
import 'theme.dart';
import 'tooltip.dart';

// Minimum logical pixel size of the IconButton.
// See: <https://material.io/design/usability/accessibility.html#layout-typography>
const double _kMinButtonSize = 48.0;

const Border _kDefaultStandaloneBorder = Border(
  left: BorderSide(color: Colors.black12),
  top: BorderSide(color: Colors.black12),
  right: BorderSide(color: Colors.black12),
  bottom: BorderSide(color: Colors.black12),
);

class ToggleButton extends StatelessWidget {
  // TODO: Figure out which properties should be required
  ToggleButton({
    Key key,
    this.alignment = Alignment.center,
    this.icon,
    this.iconSize = 24.0,
    this.padding = const EdgeInsets.all(12.0),
    this.selected = false,
    this.iconColor,
    this.backgroundColor,
    this.disabledColor,
    this.highlightColor,
    this.splashColor,
    this.border = _kDefaultStandaloneBorder,
    this.onPressed,
    this.tooltip,
  }) : super(key: key);

  // TODO: Write out documentation for final fields

  final AlignmentGeometry alignment;

  final Widget icon;

  final double iconSize;

  final EdgeInsets padding;

  final bool selected;

  final Color iconColor;

  final Color backgroundColor;

  final Color highlightColor;

  final Color splashColor;

  final Border border;

  final Color disabledColor;

  final VoidCallback onPressed;

  final String tooltip;

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterial(context));
    Color currentColor;

    if (onPressed != null) {
      currentColor = iconColor;
    } else {
      currentColor = disabledColor ?? Theme.of(context).disabledColor;
    }

    // TODO: perhaps come up with better intermediate variable
    Widget resultingIcon = Semantics(
      button: true,
      enabled: onPressed != null,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: _kMinButtonSize,
          minHeight: _kMinButtonSize,
        ),
        child: Padding(
          padding: padding,
          child: SizedBox(
            height: iconSize,
            width: iconSize,
            // TODO: Test out need for alignment here (seems like not needed). If not needed, file issue for IconButton
            child: IconTheme.merge(
              data: IconThemeData(
                size: iconSize,
                color: currentColor,
              ),
              child: icon,
            ),
          )
        ),
      ),
    );

    if (tooltip != null) {
      resultingIcon = Tooltip(
        message: tooltip,
        child: resultingIcon,
      );
    }

    return InkWell(
      onTap: onPressed,
      child: resultingIcon,
      highlightColor: highlightColor ?? Theme.of(context).highlightColor,
      splashColor: splashColor ?? Theme.of(context).splashColor,
    );
  }

  // TODO: include debugFillProperties method
}