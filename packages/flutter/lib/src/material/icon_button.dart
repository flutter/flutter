// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import 'icon.dart';

class IconButton extends StatelessComponent {
  const IconButton({
    Key key,
    this.icon,
    this.color,
    this.colorFilter,
    this.onPressed
  }) : super(key: key);

  final String icon;
  final IconThemeColor color;
  final ui.ColorFilter colorFilter;
  final GestureTapCallback onPressed;

  Widget build(BuildContext context) {
    return new GestureDetector(
      onTap: onPressed,
      child: new Padding(
        padding: const EdgeDims.all(8.0),
        child: new Icon(
          type: icon,
          size: 24,
          color: color,
          colorFilter: colorFilter
        )
      )
    );
  }

  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('$icon');
  }
}
