// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'colors.dart';
import 'icon_theme.dart';
import 'icon_theme_data.dart';
import 'typography.dart';

/// A header used in a material design [GridTile].
///
/// Typically used to add a one or two line header or footer on a [GridTile].
///
/// For a one-line header, include a [title] widget. To add a second line, also
/// include a [subtitle] wiget. Use [leading] or [trailing] to add an icon.
///
/// See also:
///
///  * [GridTile]
///  * <https://www.google.com/design/spec/components/grid-lists.html#grid-lists-specs>
class GridTileBar extends StatelessWidget {
  /// Creates a grid tile bar.
  ///
  /// Typically used to with [GridTile].
  GridTileBar({
    Key key,
    this.backgroundColor,
    this.leading,
    this.title,
    this.subtitle,
    this.trailing
  }) : super(key: key);

  /// The color to paint behind the child widgets.
  ///
  /// Defaults to transparent.
  final Color backgroundColor;

  /// A widget to display before the title.
  ///
  /// Typically an [Icon] or an [IconButton] widget.
  final Widget leading;

  /// The primary content of the list item.
  ///
  /// Typically a [Text] widget.
  final Widget title;

  /// Additional content displayed below the title.
  ///
  /// Typically a [Text] widget.
  final Widget subtitle;

  /// A widget to display after the title.
  ///
  /// Typically an [Icon] or an [IconButton] widget.
  final Widget trailing;

  @override
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
              new DefaultTextStyle.explicit(
                style: Typography.white.subhead,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                child: title
              ),
              new DefaultTextStyle.explicit(
                style: Typography.white.caption,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                child: subtitle
              )
            ]
          )
        )
      );
    } else if (title != null || subtitle != null) {
      children.add(
        new Flexible(
          child: new DefaultTextStyle.explicit(
            style: Typography.white.subhead,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
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
