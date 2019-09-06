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
/// users to address (or dismiss the banner). A user action is required for it
/// to be dismissed.
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
///
/// This widget is unrelated to the widgets library [Banner] widget.
class MaterialBanner extends StatelessWidget {
  /// Creates a [MaterialBanner].
  ///
  /// The [actions], [content], and [forceActionsBelow] must be non-null.
  /// The [actions.length] must be greater than 0.
  const MaterialBanner({
    Key key,
    @required this.content,
    this.contentTextStyle,
    @required this.actions,
    this.leading,
    this.backgroundColor,
    this.padding,
    this.leadingPadding,
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
  /// If `null`, [MaterialBannerThemeData.contentTextStyle] is used. If that is
  /// also `null`, [ThemeData.textTheme.body1] is used.
  final TextStyle contentTextStyle;

  /// The set of actions that are displayed at the bottom or trailing side of
  /// the [MaterialBanner].
  ///
  /// Typically this is a list of [FlatButton] widgets.
  ///
  /// These widgets will be wrapped in a [ButtonBar], which introduces 8 pixels
  /// of padding on each side.
  final List<Widget> actions;

  /// The (optional) leading widget of the [MaterialBanner].
  ///
  /// Typically an [Icon] widget.
  final Widget leading;

  /// The color of the surface of this [MaterialBanner].
  ///
  /// If `null`, [MaterialBannerThemeData.backgroundColor] is used. If that is
  /// also `null`, [ThemeData.colorScheme.surface] is used.
  final Color backgroundColor;

  /// The amount of space by which to inset the [content].
  ///
  /// If the [actions] are below the [content], this defaults to
  /// `EdgeInsetsDirectional.only(start: 16.0, top: 24.0, end: 16.0, bottom: 4.0)`.
  ///
  /// If the [actions] are trailing the [content], this defaults to
  /// `EdgeInsetsDirectional.only(start: 16.0, top: 2.0)`.
  final EdgeInsetsGeometry padding;

  /// The amount of space by which to inset the [leading] widget.
  ///
  /// This defaults to `EdgeInsetsDirectional.only(end: 16.0)`.
  final EdgeInsetsGeometry leadingPadding;

  /// An override to force the [actions] to be below the [content] regardless of
  /// how many there are.
  ///
  /// If this is `true`, the [actions] will be placed below the [content]. If
  /// this is `false`, the [actions] will be placed on the trailing side of the
  /// [content] if [actions.length] is `1` and below the [content] if greater
  /// than `1`.
  final bool forceActionsBelow;

  @override
  Widget build(BuildContext context) {
    assert(actions.isNotEmpty);

    final ThemeData theme = Theme.of(context);
    final MaterialBannerThemeData bannerTheme = MaterialBannerTheme.of(context);

    final bool isSingleRow = actions.length == 1 && !forceActionsBelow;
    final EdgeInsetsGeometry padding = this.padding ?? bannerTheme.padding ?? (isSingleRow
        ? const EdgeInsetsDirectional.only(start: 16.0, top: 2.0)
        : const EdgeInsetsDirectional.only(start: 16.0, top: 24.0, end: 16.0, bottom: 4.0));
    final EdgeInsetsGeometry leadingPadding = this.leadingPadding
        ?? bannerTheme.padding
        ?? const EdgeInsetsDirectional.only(end: 16.0);

    final Widget buttonBar = ButtonBar(
      layoutBehavior: ButtonBarLayoutBehavior.constrained,
      children: actions,
    );

    final Color backgroundColor = this.backgroundColor
        ?? bannerTheme.backgroundColor
        ?? theme.colorScheme.surface;
    final TextStyle textStyle = contentTextStyle
        ?? bannerTheme.contentTextStyle
        ?? theme.textTheme.body1;

    return Container(
      color: backgroundColor,
      child: Column(
        children: <Widget>[
          Padding(
            padding: padding,
            child: Row(
              children: <Widget>[
                if (leading != null)
                  Padding(
                    padding: leadingPadding,
                    child: leading,
                  ),
                Expanded(
                  child: DefaultTextStyle(
                    style: textStyle,
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