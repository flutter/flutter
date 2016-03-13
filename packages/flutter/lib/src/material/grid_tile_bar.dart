// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'colors.dart';
import 'icon_theme.dart';
import 'icon_theme_data.dart';
import 'typography.dart';


/// Typically used to stack a one or two line header or footer on a Grid tile.
/// The layout is based on the "Grid Lists" section of the Material Design spec:
/// https://www.google.com/design/spec/components/grid-lists.html#grid-lists-specs
/// For a one-line header specify [title] and to add a second line specify [subtitle].
/// Use [leading] or [trailing] to add an icon.
class GridTileBar extends StatelessWidget {
  GridTileBar({
    Key key,
    this.backgroundColor,
    this.leading,
    this.title,
    this.subtitle,
    this.trailing
  }) : super(key: key);

  final Color backgroundColor;
  final Widget leading;
  final Widget title;
  final Widget subtitle;
  final Widget trailing;

  Widget build(BuildContext context) {
    BoxDecoration decoration;
    if (backgroundColor != null)
      decoration = new BoxDecoration(backgroundColor: backgroundColor);

    EdgeInsets padding;
    if (leading != null && trailing != null)
      padding = const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0);
    else if (leading != null)
      padding = const EdgeInsets.only(left: 8.0, right: 16.0, top: 16.0, bottom: 16.0);
    else // trailing != null || (leading == null && trailing == null)
      padding = const EdgeInsets.only(left: 16.0, right: 8.0, top: 16.0, bottom: 16.0);

    final List<Widget> children = <Widget>[];

    if (leading != null)
      children.add(new Padding(padding: const EdgeInsets.only(right: 8.0), child: leading));

    if (title != null && subtitle != null) {
      children.add(
        new Flexible(
          child: new Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              new DefaultTextStyle(
                style: Typography.white.subhead,
                child: title
              ),
              new DefaultTextStyle(
                style: Typography.white.caption,
                child: subtitle
              )
            ]
          )
        )
      );
    } else if (title != null || subtitle != null) {
      children.add(
        new Flexible(
          child: new DefaultTextStyle(
            style: Typography.white.subhead,
            child: title ?? subtitle
          )
        )
      );
    }

    if (trailing != null)
      children.add(new Padding(padding: const EdgeInsets.only(left: 8.0), child: trailing));

    return new Container(
      padding: padding,
      decoration: decoration,
      child: new IconTheme(
        data: new IconThemeData(color: Colors.white),
        child: new Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: children
        )
      )
    );
  }
}
