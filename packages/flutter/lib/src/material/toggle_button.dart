// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'colors.dart';
import 'icon_button.dart';
import 'ink_decoration.dart';
import 'theme.dart';

const Border kDefaultStandaloneBorder = Border(
  left: BorderSide(color: Colors.black12),
  top: BorderSide(color: Colors.black12),
  right: BorderSide(color: Colors.black12),
  bottom: BorderSide(color: Colors.black12),
);

class ToggleButton extends StatelessWidget {
  ToggleButton({
    this.iconSize = 24.0,
    this.border = kDefaultStandaloneBorder,
    this.onPressed,
    this.padding = const EdgeInsets.all(12.0),
    this.selected = false,
    this.icon,
    this.iconColor,
  });

  final Border border;

  final VoidCallback onPressed;

  @required
  final Widget icon;

  final Color iconColor;

  final double iconSize;

  final EdgeInsets padding;

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Ink(
      decoration: BoxDecoration(
        // update proper background colors based on theme and passed in values
        color: selected ? Colors.white : Colors.black12,
        border: border,
      ),
      child: IconButton(
        color: iconColor ?? Theme.of(context).iconTheme.color,
        icon: icon,
        iconSize: iconSize,
        onPressed: onPressed,
        padding: padding,
      ),
    );
  }
}