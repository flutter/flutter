// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'icon.dart';
import 'icon_theme_data.dart';
import 'ink_well.dart';
import 'tooltip.dart';

class IconButton extends StatelessComponent {
  const IconButton({
    Key key,
    this.icon,
    this.colorTheme,
    this.color,
    this.onPressed,
    this.tooltip
  }) : super(key: key);

  final String icon;
  final IconThemeColor colorTheme;
  final Color color;
  final VoidCallback onPressed;
  final String tooltip;

  Widget build(BuildContext context) {
    Widget result = new Padding(
      padding: const EdgeDims.all(8.0),
      child: new Icon(
        icon: icon,
        colorTheme: colorTheme,
        color: color
      )
    );
    if (tooltip != null) {
      result = new Tooltip(
        message: tooltip,
        child: result
      );
    }
    return new InkResponse(
      onTap: onPressed,
      child: result
    );
  }

  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('$icon');
    if (onPressed == null)
      description.add('disabled');
    if (colorTheme != null)
      description.add('$colorTheme');
    if (tooltip != null)
      description.add('tooltip: "$tooltip"');
  }
}
