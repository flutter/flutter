// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'banner_theme.dart';
import 'button_bar.dart';
import 'button_theme.dart';
import 'divider.dart';
import 'theme.dart';

/// A Material Design banner.
///
/// A banner displays an important, succinct message, and provides actions for
/// users to address (or dismiss the banner). It requires a user action to be
/// dismissed.
///
/// Banners should be displayed at the top of the screen, below a top app bar.
/// They are persistent and nonmodal, allowing the user to either ignore them or
/// interact with them at any time.
///
/// The [actions] will be placed beside the [content] if there is only one.
/// Otherwise, the [actions] will be placed below the [content]. Use
/// [forceActionsBelow] to override this behavior.
///
/// The [actions] and [content] must be provided. An optional leading widget
/// (typically an [Image]) can also be provided. The [contentTextStyle] and
/// [backgroundColor] can be provided to customize the banner.
class MaterialBanner extends StatelessWidget {
  /// Creates a [MaterialBanner].
  ///
  /// The [actions], [content], and [forceActionsBelow] must be non-null.
  const MaterialBanner({
    Key key,
    @required this.content,
    this.contentTextStyle,
    @required this.actions,
    this.leading,
    this.backgroundColor,
    this.forceActionsBelow = false,
  }) : assert(content != null),
       assert(actions != null),
       assert(forceActionsBelow != null),
       super(key: key);

  /// The content of the [MaterialBanner].
  ///
  /// Typically a [Text] widget.
  final Widget content;

  /// Style for the text in the [content] of the [MaterialBanner].
  ///
  /// If null, defaults to [ThemeData.textTheme.body1].
  final TextStyle contentTextStyle;

  /// The set of actions that are displayed at the bottom of the bottom or right
  /// side of the [MaterialBanner].
  ///
  /// Typically this is a list of [FlatButton] widgets.
  ///
  /// These widgets will be wrapped in a [ButtonBar], which introduces 8 pixels
  /// of padding on each side.
  final List<Widget> actions;

  /// The (optional) leading widget of the [MaterialBanner].
  ///
  /// Typically an [Image] widget.
  final Widget leading;

  /// The background color of the surface of this [MaterialBanner].
  ///
  /// This sets the [Material.color] on this [MaterialBanner]'s [Container].
  ///
  /// If `null`, [ThemeData.canvasColor] is used.
  final Color backgroundColor;

  /// An override to force the [actions] to be below the [content] regardless of
  /// how many there are.
  ///
  /// If this is `true`, the [actions] will be placed below the [content]. If
  /// this is `false`, the [actions] will be placed next to the [content] if
  /// [actions.length] is `1` and below the [content] if greater than `1`.
  final bool forceActionsBelow;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final MaterialBannerThemeData bannerTheme = MaterialBannerTheme.of(context);

    final bool isSingleRow = actions.length == 1 && !forceActionsBelow;
    final EdgeInsetsDirectional padding = isSingleRow
        ? const EdgeInsetsDirectional.only(start: 16.0, top: 2.0)
        : const EdgeInsetsDirectional.only(start: 16.0, top: 24.0, end: 16.0, bottom: 4.0);

    final Widget buttonBar = ButtonTheme.bar(
      layoutBehavior: ButtonBarLayoutBehavior.constrained,
      child: ButtonBar(
        children: actions,
      ),
    );

    return Container(
      color: backgroundColor ?? bannerTheme.backgroundColor ?? theme.canvasColor,
      child: Column(
        children: <Widget>[
          Padding(
            padding: padding,
            child: Row(
              children: <Widget>[
                if (leading != null)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 16.0),
                    child: leading,
                  ),
                Flexible(
                  child: DefaultTextStyle(
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    style: contentTextStyle ?? bannerTheme.contentTextStyle ?? theme.textTheme.body1,
                    child: content,
                  ),
                ),
                if (isSingleRow)
                  buttonBar,
              ],
            ),
          ),
          if (!isSingleRow)
            buttonBar,
          const Divider(height: 0),
        ],
      ),
    );
  }
}