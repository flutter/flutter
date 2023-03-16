// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'colors.dart';
import 'theme.dart';

/// A header used in a Material Design [GridTile].
///
/// Typically used to add a one or two line header or footer on a [GridTile].
///
/// For a one-line header, include a [title] widget. To add a second line, also
/// include a [subtitle] widget. Use [leading] or [trailing] to add an icon.
///
/// See also:
///
///  * [GridTile]
///  * <https://material.io/design/components/image-lists.html#anatomy>
class GridTileBar extends StatelessWidget {
  /// Creates a grid tile bar.
  ///
  /// Typically used to with [GridTile].
  const GridTileBar({
    super.key,
    this.backgroundColor,
    this.leading,
    this.title,
    this.subtitle,
    this.trailing,
  });

  /// The color to paint behind the child widgets.
  ///
  /// Defaults to transparent.
  final Color? backgroundColor;

  /// A widget to display before the title.
  ///
  /// Typically an [Icon] or an [IconButton] widget.
  final Widget? leading;

  /// The primary content of the list item.
  ///
  /// Typically a [Text] widget.
  final Widget? title;

  /// Additional content displayed below the title.
  ///
  /// Typically a [Text] widget.
  final Widget? subtitle;

  /// A widget to display after the title.
  ///
  /// Typically an [Icon] or an [IconButton] widget.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    BoxDecoration? decoration;
    if (backgroundColor != null) {
      decoration = BoxDecoration(color: backgroundColor);
    }

    final EdgeInsetsDirectional padding = EdgeInsetsDirectional.only(
      start: leading != null ? 8.0 : 16.0,
      end: trailing != null ? 8.0 : 16.0,
    );

    final ThemeData darkTheme = ThemeData.dark();
    return Container(
      padding: padding,
      decoration: decoration,
      height: (title != null && subtitle != null) ? 68.0 : 48.0,
      child: Theme(
        data: darkTheme,
        child: IconTheme.merge(
          data: const IconThemeData(color: Colors.white),
          child: Row(
            children: <Widget>[
              if (leading != null)
                Padding(padding: const EdgeInsetsDirectional.only(end: 8.0), child: leading),
              if (title != null && subtitle != null)
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      DefaultTextStyle(
                        style: darkTheme.textTheme.titleMedium!,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                        child: title!,
                      ),
                      DefaultTextStyle(
                        style: darkTheme.textTheme.bodySmall!,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                        child: subtitle!,
                      ),
                    ],
                  ),
                )
              else if (title != null || subtitle != null)
                Expanded(
                  child: DefaultTextStyle(
                    style: darkTheme.textTheme.titleMedium!,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    child: title ?? subtitle!,
                  ),
                ),
              if (trailing != null)
                Padding(padding: const EdgeInsetsDirectional.only(start: 8.0), child: trailing),
            ],
          ),
        ),
      ),
    );
  }
}
