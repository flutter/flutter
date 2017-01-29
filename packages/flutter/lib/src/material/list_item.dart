// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

import 'constants.dart';
import 'debug.dart';
import 'ink_well.dart';
import 'theme.dart';

/// A single row typically containing an icon and some text.
///
/// List items are one to three lines of text optionally flanked by icons or
/// other widgets, such as check boxes. The icons (or other widgets) for the
/// item are defined with the [leading] and [trailing] parameters. The first
/// line of text is not optional and is specified with [title]. The value of
/// [subtitle], which _is_ optional, will occupy the space allocated for an
/// additional line of text, or two lines if [isThreeLine] is true. If [dense]
/// is true then the overall height of this list item and the size of the
/// [DefaultTextStyle]s that wrap the [title] and [subtitle] widget are reduced.
///
/// List items are always a fixed height (which height depends on how
/// [isThreeLine], [dense], and [subtitle] are configured); they do not grow in
/// height based on their contents. If you are looking for a widget that allows
/// for arbitrary layout in a row, consider [Row].
///
/// List items are typically used in [MaterialList]s or in [Card]s.
///
/// Requires one of its ancestors to be a [Material] widget.
///
/// See also:
///
///  * [MaterialList], which takes a list of [ListItem] widgets and shows them
///    as a scrolling list.
///  * [Card], which can be used with [Column] to show a few [ListItem]s.
///  * [CircleAvatar], which shows an icon representing a person.
///  * [Divider], which can be used to separate [ListItem]s.
///  * [ListItem.divideItems], another way to separate [ListItem]s.
///  * <https://material.google.com/components/lists.html>
class ListItem extends StatelessWidget {
  /// Creates a list item.
  ///
  /// If [isThreeLine] is true, then [subtitle] must not be null.
  ///
  /// Requires one of its ancestors to be a [Material] widget.
  ListItem({
    Key key,
    this.leading,
    this.title,
    this.subtitle,
    this.trailing,
    this.isThreeLine: false,
    this.dense: false,
    this.enabled: true,
    this.onTap,
    this.onLongPress
  }) : super(key: key);

  /// A widget to display before the title.
  ///
  /// Typically a [CircleAvatar] widget.
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
  /// Typically an [Icon] widget.
  final Widget trailing;

  /// Whether this list item is intended to display three lines of text.
  ///
  /// If false, the list item is treated as having one line if the subtitle is
  /// null and treated as having two lines if the subtitle is non-null.
  final bool isThreeLine;

  /// Whether this list item is part of a vertically dense list.
  final bool dense;

  /// Whether this list item is interactive.
  ///
  /// If false, this list item is styled with the disabled color from the
  /// current [Theme] and the [onTap] and [onLongPress] callbacks are
  /// inoperative.
  final bool enabled;

  /// Called when the user taps this list item.
  ///
  /// Inoperative if [enabled] is false.
  final GestureTapCallback onTap;

  /// Called when the user long-presses on this list item.
  ///
  /// Inoperative if [enabled] is false.
  final GestureLongPressCallback onLongPress;

  /// Add a one pixel border in between each item. If color isn't specified the
  /// [ThemeData.dividerColor] of the context's [Theme] is used.
  ///
  /// See also:
  ///
  /// * [Divider], which you can use to obtain this effect manually.
  static Iterable<Widget> divideItems({ BuildContext context, @required Iterable<Widget> items, Color color }) sync* {
    assert(items != null);
    assert(color != null || context != null);

    final Color dividerColor = color ?? Theme.of(context).dividerColor;
    final Iterator<Widget> iterator = items.iterator;
    final bool isNotEmpty = iterator.moveNext();

    Widget item = iterator.current;
    while (iterator.moveNext()) {
      yield new DecoratedBox(
        decoration: new BoxDecoration(
          border: new Border(
            bottom: new BorderSide(color: dividerColor),
          ),
        ),
        child: item,
      );
      item = iterator.current;
    }
    if (isNotEmpty)
      yield item;
  }

  TextStyle _primaryTextStyle(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle style = theme.textTheme.subhead;
    if (!enabled) {
      final Color color = theme.disabledColor;
      return dense ? style.copyWith(fontSize: 13.0, color: color) : style.copyWith(color: color);
    }
    return dense ? style.copyWith(fontSize: 13.0) : style;
  }

  TextStyle _secondaryTextStyle(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color color = theme.textTheme.caption.color;
    final TextStyle style = theme.textTheme.body1;
    return dense ? style.copyWith(color: color, fontSize: 12.0) : style.copyWith(color: color);
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterial(context));
    final bool isTwoLine = !isThreeLine && subtitle != null;
    final bool isOneLine = !isThreeLine && !isTwoLine;
    double itemHeight;
    if (isOneLine)
      itemHeight = dense ? 48.0 : 56.0;
    else if (isTwoLine)
      itemHeight = dense ? 60.0 : 72.0;
    else
      itemHeight = dense ? 76.0 : 88.0;

    // Overall, the list item is a Row() with these children.
    final List<Widget> children = <Widget>[];

    if (leading != null) {
      children.add(new Container(
        margin: const EdgeInsets.only(right: 16.0),
        width: 40.0,
        alignment: FractionalOffset.centerLeft,
        child: leading
      ));
    }

    final Widget primaryLine = new AnimatedDefaultTextStyle(
      style: _primaryTextStyle(context),
      duration: kThemeChangeDuration,
      child: title ?? new Container()
    );
    Widget center = primaryLine;
    if (subtitle != null && (isTwoLine || isThreeLine)) {
      center = new Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          primaryLine,
          new AnimatedDefaultTextStyle(
            style: _secondaryTextStyle(context),
            duration: kThemeChangeDuration,
            child: subtitle
          )
        ]
      );
    }
    children.add(new Expanded(
      child: center
    ));

    if (trailing != null) {
      children.add(new Container(
        margin: const EdgeInsets.only(left: 16.0),
        alignment: FractionalOffset.centerRight,
        child: trailing
      ));
    }

    return new InkWell(
      onTap: enabled ? onTap : null,
      onLongPress: enabled ? onLongPress : null,
      child: new Container(
        height: itemHeight,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: new Row(
          children: children
        )
      )
    );
  }
}
