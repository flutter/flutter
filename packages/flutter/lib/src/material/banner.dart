// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'banner_theme.dart';
import 'divider.dart';
import 'theme.dart';

/// A Material Design banner.
///
/// A banner displays an important, succinct message, and provides actions for
/// users to address (or dismiss the banner). A user action is required for it
/// to be dismissed.
///
/// Banners should be displayed at the top of the screen, below a top app bar.
/// They are persistent and non-modal, allowing the user to either ignore them or
/// interact with them at any time.
///
/// {@tool dartpad --template=stateless_widget_material}
/// ```dart
/// Widget build(BuildContext context) {
///   return Scaffold(
///     appBar: AppBar(
///       title: const Text('The MaterialBanner is below'),
///     ),
///     body: const MaterialBanner(
///       padding: EdgeInsets.all(20),
///       content: Text('Hello, I am a Material Banner'),
///       leading: Icon(Icons.agriculture_outlined),
///       backgroundColor: Color(0xFFE0E0E0),
///       actions: <Widget>[
///         TextButton(
///           child: Text('OPEN'),
///           onPressed: null,
///         ),
///         TextButton(
///           child: Text('DISMISS'),
///           onPressed: null,
///         ),
///       ],
///     ),
///   );
/// }
/// ```
/// {@end-tool}
///
/// The [actions] will be placed beside the [content] if there is only one.
/// Otherwise, the [actions] will be placed below the [content]. Use
/// [forceActionsBelow] to override this behavior.
///
/// If the [actions] placed below the [content], they will be laid out in a row.
/// If there isn't sufficient room to display everything, they are laid out
/// in a column instead.
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
    Key? key,
    required this.content,
    this.contentTextStyle,
    required this.actions,
    this.leading,
    this.backgroundColor,
    this.padding,
    this.leadingPadding,
    this.forceActionsBelow = false,
    this.overflowAlignment = OverflowBarAlignment.end,
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
  /// also `null`, [TextTheme.bodyText2] of [ThemeData.textTheme] is used.
  final TextStyle? contentTextStyle;

  /// The set of actions that are displayed at the bottom or trailing side of
  /// the [MaterialBanner].
  ///
  /// Typically this is a list of [TextButton] widgets.
  final List<Widget> actions;

  /// The (optional) leading widget of the [MaterialBanner].
  ///
  /// Typically an [Icon] widget.
  final Widget? leading;

  /// The color of the surface of this [MaterialBanner].
  ///
  /// If `null`, [MaterialBannerThemeData.backgroundColor] is used. If that is
  /// also `null`, [ColorScheme.surface] of [ThemeData.colorScheme] is used.
  final Color? backgroundColor;

  /// The amount of space by which to inset the [content].
  ///
  /// If the [actions] are below the [content], this defaults to
  /// `EdgeInsetsDirectional.only(start: 16.0, top: 24.0, end: 16.0, bottom: 4.0)`.
  ///
  /// If the [actions] are trailing the [content], this defaults to
  /// `EdgeInsetsDirectional.only(start: 16.0, top: 2.0)`.
  final EdgeInsetsGeometry? padding;

  /// The amount of space by which to inset the [leading] widget.
  ///
  /// This defaults to `EdgeInsetsDirectional.only(end: 16.0)`.
  final EdgeInsetsGeometry? leadingPadding;

  /// An override to force the [actions] to be below the [content] regardless of
  /// how many there are.
  ///
  /// If this is true, the [actions] will be placed below the [content]. If
  /// this is false, the [actions] will be placed on the trailing side of the
  /// [content] if [actions]'s length is 1 and below the [content] if greater
  /// than 1.
  ///
  /// Defaults to false.
  final bool forceActionsBelow;

  /// The horizontal alignment of the [actions] when the [actions] laid out in a column.
  ///
  /// Defaults to [OverflowBarAlignment.end].
  final OverflowBarAlignment overflowAlignment;

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
        ?? bannerTheme.leadingPadding
        ?? const EdgeInsetsDirectional.only(end: 16.0);

    final Widget buttonBar = Container(
      alignment: AlignmentDirectional.centerEnd,
      constraints: const BoxConstraints(minHeight: 52.0),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: OverflowBar(
        overflowAlignment: overflowAlignment,
        spacing: 8,
        children: actions,
      ),
    );

    final Color backgroundColor = this.backgroundColor
        ?? bannerTheme.backgroundColor
        ?? theme.colorScheme.surface;
    final TextStyle? textStyle = contentTextStyle
        ?? bannerTheme.contentTextStyle
        ?? theme.textTheme.bodyText2;

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
                    style: textStyle!,
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
