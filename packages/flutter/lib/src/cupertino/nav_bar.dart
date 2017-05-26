// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show ImageFilter;

import 'package:flutter/widgets.dart';

const double _kNavBarHeight = 44.0;

class CupertinoNavigationBar extends StatelessWidget implements PreferredSizeWidget {
  const CupertinoNavigationBar(
    Key key,
    this.leading,
    this.middle,
    this.trailing,
    this.backgroundColor,
    this.foregroundColor,
  ) : assert(middle != null, 'There must be a middle widget, usually a title'),
      super(key: key);

  final Widget leading;
  final Widget middle;
  final Widget trailing;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Size get preferredSize => null;

  @override
  Widget build(BuildContext context) {
    final bool addBlur = backgroundColor.alpha != 0xFF;

    Widget result = new DecoratedBox(
      decoration: new BoxDecoration(
        border: const Border(
          bottom: const BorderSide(
            color: const Color(0x4C000000),
            width: 0.0, // One physical pixel.
            style: BorderStyle.solid,
          ),
        ),
        color: backgroundColor,
      ),
      child: new SizedBox(
        height: _kNavBarHeight + MediaQuery.of(context).padding.top,
        child: IconTheme.merge( // Default with the inactive state.
          data: new IconThemeData(
            color: foregroundColor,
            size: 22.0,
          ),
          child: DefaultTextStyle.merge( // Default with the inactive state.
            style: new TextStyle(
              fontSize: 17.0,
              letterSpacing: -0.24,
              color: foregroundColor,
            ),
            child: new Padding(
              padding: new EdgeInsets.only(top: MediaQuery.of(context).padding.top),
              child: new NavigationToolbar(
                leading: leading,
                middle: middle,
                trailing: trailing,
                centerMiddle: true,
              ),
            ),
          ),
        ),
      ),
    );

    if (addBlur) {
      // For non-opaque backgrounds, apply a blur effect.
      result = new ClipRect(
        child: new BackdropFilter(
          filter: new ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: result,
        ),
      );
    }

    return result;
  }
}