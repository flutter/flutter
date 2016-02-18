// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'icon_theme.dart';
import 'icon_theme_data.dart';
import 'typography.dart';


/// Typically used to stack a one or two line header or footer on a Grid tile.
/// The layout is based on the "Grid Lists" section of the Material Design spec:
/// https://www.google.com/design/spec/components/grid-lists.html#grid-lists-specs
/// For a one-line header specify title and to add a second line specify caption.
/// Use left or right to add an icon.
class GridTileBar extends StatelessComponent {
  GridTileBar({ Key key, this.backgroundColor, this.left, this.right, this.title, this.caption }) : super(key: key);

  final Color backgroundColor;
  final Widget left;
  final Widget right;
  final Widget title;
  final Widget caption;

  Widget build(BuildContext context) {
    BoxDecoration decoration;
    if (backgroundColor != null)
      decoration = new BoxDecoration(backgroundColor: backgroundColor);

    EdgeDims padding;
    if (left != null && right != null)
      padding = const EdgeDims.symmetric(vertical: 16.0, horizontal: 8.0);
    else if (left != null)
      padding = const EdgeDims.only(left: 8.0, right: 16.0, top: 16.0, bottom: 16.0);
    else // right != null || (left == null && right == null)
      padding = const EdgeDims.only(left: 16.0, right: 8.0, top: 16.0, bottom: 16.0);

    final List<Widget> children = <Widget>[];

    if (left != null)
      children.add(new Padding(padding: const EdgeDims.only(right: 8.0), child: left));

    if (title != null && caption != null) {
      children.add(
        new Flexible(
          child: new Column(
            alignItems: FlexAlignItems.start,
            children: <Widget>[
              new DefaultTextStyle(
                style: Typography.white.subhead,
                child: title
              ),
              new DefaultTextStyle(
                style: Typography.white.caption,
                child: caption
              )
            ]
          )
        )
      );
    } else if (title != null || caption != null) {
      children.add(
        new Flexible(
          child: new DefaultTextStyle(
            style: Typography.white.subhead,
            child: title ?? caption
          )
        )
      );
    }

    if (right != null)
      children.add(new Padding(padding: const EdgeDims.only(left: 8.0), child: right));

    return new Container(
      padding: padding,
      decoration: decoration,
      child: new IconTheme(
        data: new IconThemeData(color: IconThemeColor.white),
        child: new Row(
          alignItems: FlexAlignItems.center,
          children: children
        )
      )
    );
  }
}
