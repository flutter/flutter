// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'colors.dart';
import 'constants.dart';
import 'debug.dart';
import 'divider.dart';
import 'ink_well.dart';
import 'theme.dart';

/// Defines the title font used for [ListTile] descendants of a [ListTileTheme].
///
/// List tiles that appear in a [Drawer] use the theme's [TextTheme.body2]
/// text style, which is a little smaller than the theme's [TextTheme.subhead]
/// text style, which is used by default.
enum ListTileStyle {
  /// Use a title font that's appropriate for a [ListTile] in a list.
  list,

  /// Use a title font that's appropriate for a [ListTile] that appears in a [Drawer].
  drawer,
}

/// An inherited widget that defines color and style parameters for [ListTile]s
/// in this widget's subtree.
///
/// Values specified here are used for [ListTile] properties that are not given
/// an explicit non-null value.
///
/// The [Drawer] widget specifies a tile theme for its children which sets
/// [style] to [ListTileStyle.drawer].
class ListTileTheme extends InheritedWidget {
  /// Creates a list tile theme that controls the color and style parameters for
  /// [ListTile]s.
  const ListTileTheme({
    Key key,
    this.dense: false,
    this.style: ListTileStyle.list,
    this.selectedColor,
    this.iconColor,
    this.textColor,
    Widget child,
  }) : super(key: key, child: child);

  /// Creates a list tile theme that controls the color and style parameters for
  /// [ListTile]s, and merges in the current list tile theme, if any.
  ///
  /// The [child] argument must not be null.
  static Widget merge({
    Key key,
    bool dense,
    ListTileStyle style,
    Color selectedColor,
    Color iconColor,
    Color textColor,
    @required Widget child,
  }) {
    assert(child != null);
    return new Builder(
      builder: (BuildContext context) {
        final ListTileTheme parent = ListTileTheme.of(context);
        return new ListTileTheme(
          key: key,
          dense: dense ?? parent.dense,
          style: style ?? parent.style,
          selectedColor: selectedColor ?? parent.selectedColor,
          iconColor: iconColor ?? parent.iconColor,
          textColor: textColor ?? parent.textColor,
          child: child,
        );
      },
    );
  }

  /// If true then [ListTile]s will have the vertically dense layout.
  final bool dense;

  /// If specified, [style] defines the font used for [ListTile] titles.
  final ListTileStyle style;

  /// If specified, the color used for icons and text when a [ListTile] is selected.
  final Color selectedColor;

  /// If specified, the icon color used for enabled [ListTile]s that are not selected.
  final Color iconColor;

  /// If specified, the text color used for enabled [ListTile]s that are not selected.
  final Color textColor;

  /// The closest instance of this class that encloses the given context.
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// ListTileTheme theme = ListTileTheme.of(context);
  /// ```
  static ListTileTheme of(BuildContext context) {
    final ListTileTheme result = context.inheritFromWidgetOfExactType(ListTileTheme);
    return result ?? const ListTileTheme();
  }

  @override
  bool updateShouldNotify(ListTileTheme oldTheme) {
    return dense != oldTheme.dense
        || style != oldTheme.style
        || selectedColor != oldTheme.selectedColor
        || iconColor != oldTheme.iconColor
        || textColor != oldTheme.textColor;
  }
}

/// Where to place the control in widgets that use [ListTile] to position a
/// control next to a label.
///
/// See also:
///
///  * [CheckboxListTile], which combines a [ListTile] with a [Checkbox].
///  * [RadioListTile], which combines a [ListTile] with a [Radio] button.
enum ListTileControlAffinity {
  /// Position the control on the leading edge, and the secondary widget, if
  /// any, on the trailing edge.
  leading,

  /// Position the control on the trailing edge, and the secondary widget, if
  /// any, on the leading edge.
  trailing,

  /// Position the control relative to the text in the fashion that is typical
  /// for the current platform, and place the secondary widget on the opposite
  /// side.
  platform,
}

/// A single fixed-height row that typically contains some text as well as
/// a leading or trailing icon.
///
/// A list tile contains one to three lines of text optionally flanked by icons or
/// other widgets, such as check boxes. The icons (or other widgets) for the
/// tile are defined with the [leading] and [trailing] parameters. The first
/// line of text is not optional and is specified with [title]. The value of
/// [subtitle], which _is_ optional, will occupy the space allocated for an
/// additional line of text, or two lines if [isThreeLine] is true. If [dense]
/// is true then the overall height of this tile and the size of the
/// [DefaultTextStyle]s that wrap the [title] and [subtitle] widget are reduced.
///
/// List tiles are always a fixed height (which height depends on how
/// [isThreeLine], [dense], and [subtitle] are configured); they do not grow in
/// height based on their contents. If you are looking for a widget that allows
/// for arbitrary layout in a row, consider [Row].
///
/// List tiles are typically used in [ListView]s, or arranged in [Column]s in
/// [Drawer]s and [Card]s.
///
/// Requires one of its ancestors to be a [Material] widget.
///
/// ## Sample code
///
/// Here is a simple tile with an icon and some text.
///
/// ```dart
/// new ListTile(
///   leading: const Icon(Icons.event_seat),
///   title: const Text('The seat for the narrator'),
/// )
/// ```
///
/// Tiles can be much more elaborate. Here is a tile which can be tapped, but
/// which is disabled when the `_act` variable is not 2. When the tile is
/// tapped, the whole row has an ink splash effect (see [InkWell]).
///
/// ```dart
/// int _act = 1;
/// // ...
/// new ListTile(
///   leading: const Icon(Icons.flight_land),
///   title: const Text('Trix\'s airplane'),
///   subtitle: _act != 2 ? const Text('The airplane is only in Act II.') : null,
///   enabled: _act == 2,
///   onTap: () { /* react to the tile being tapped */ }
/// )
/// ```
///
/// See also:
///
///  * [ListTileTheme], which defines visual properties for [ListTile]s.
///  * [ListView], which can display an arbitrary number of [ListTile]s
///    in a scrolling list.
///  * [CircleAvatar], which shows an icon representing a person and is often
///    used as the [leading] element of a ListTile.
///  * [Card], which can be used with [Column] to show a few [ListTile]s.
///  * [Divider], which can be used to separate [ListTile]s.
///  * [ListTile.divideTiles], a utility for inserting [Divider]s in between [ListTile]s.
///  * [CheckboxListTile], [RadioListTile], and [SwitchListTile], widgets
///    that combine [ListTile] with other controls.
///  * <https://material.google.com/components/lists.html>
class ListTile extends StatelessWidget {
  /// Creates a list tile.
  ///
  /// If [isThreeLine] is true, then [subtitle] must not be null.
  ///
  /// Requires one of its ancestors to be a [Material] widget.
  const ListTile({
    Key key,
    this.leading,
    this.title,
    this.subtitle,
    this.trailing,
    this.isThreeLine: false,
    this.dense,
    this.enabled: true,
    this.onTap,
    this.onLongPress,
    this.selected: false,
  }) : assert(isThreeLine != null),
       assert(enabled != null),
       assert(selected != null),
       assert(!isThreeLine || subtitle != null),
       super(key: key);

  /// A widget to display before the title.
  ///
  /// Typically an [Icon] or a [CircleAvatar] widget.
  final Widget leading;

  /// The primary content of the list tile.
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

  /// Whether this list tile is intended to display three lines of text.
  ///
  /// If false, the list tile is treated as having one line if the subtitle is
  /// null and treated as having two lines if the subtitle is non-null.
  final bool isThreeLine;

  /// Whether this list tile is part of a vertically dense list.
  ///
  /// If this property is null then its value is based on [ListTileTheme.dense].
  final bool dense;

  /// Whether this list tile is interactive.
  ///
  /// If false, this list tile is styled with the disabled color from the
  /// current [Theme] and the [onTap] and [onLongPress] callbacks are
  /// inoperative.
  final bool enabled;

  /// Called when the user taps this list tile.
  ///
  /// Inoperative if [enabled] is false.
  final GestureTapCallback onTap;

  /// Called when the user long-presses on this list tile.
  ///
  /// Inoperative if [enabled] is false.
  final GestureLongPressCallback onLongPress;

  /// If this tile is also [enabled] then icons and text are rendered with the same color.
  ///
  /// By default the selected color is the theme's primary color. The selected color
  /// can be overridden with a [ListTileTheme].
  final bool selected;

  /// Add a one pixel border in between each tile. If color isn't specified the
  /// [ThemeData.dividerColor] of the context's [Theme] is used.
  ///
  /// See also:
  ///
  /// * [Divider], which you can use to obtain this effect manually.
  static Iterable<Widget> divideTiles({ BuildContext context, @required Iterable<Widget> tiles, Color color }) sync* {
    assert(tiles != null);
    assert(color != null || context != null);

    final Iterator<Widget> iterator = tiles.iterator;
    final bool isNotEmpty = iterator.moveNext();

    final Decoration decoration = new BoxDecoration(
      border: new Border(
        bottom: Divider.createBorderSide(context, color: color),
      ),
    );

    Widget tile = iterator.current;
    while (iterator.moveNext()) {
      yield new DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: decoration,
        child: tile,
      );
      tile = iterator.current;
    }
    if (isNotEmpty)
      yield tile;
  }

  Color _iconColor(ThemeData theme, ListTileTheme tileTheme) {
    if (!enabled)
      return theme.disabledColor;

    if (selected && tileTheme?.selectedColor != null)
      return tileTheme.selectedColor;

    if (!selected && tileTheme?.iconColor != null)
      return tileTheme.iconColor;

    switch (theme.brightness) {
      case Brightness.light:
        return selected ? theme.primaryColor : Colors.black45;
      case Brightness.dark:
        return selected ? theme.accentColor : null; // null - use current icon theme color
    }
    assert(theme.brightness != null);
    return null;
  }

  Color _textColor(ThemeData theme, ListTileTheme tileTheme, Color defaultColor) {
    if (!enabled)
      return theme.disabledColor;

    if (selected && tileTheme?.selectedColor != null)
      return tileTheme.selectedColor;

    if (!selected && tileTheme?.textColor != null)
      return tileTheme.textColor;

    if (selected) {
      switch (theme.brightness) {
        case Brightness.light:
          return theme.primaryColor;
        case Brightness.dark:
          return theme.accentColor;
      }
    }
    return defaultColor;
  }

  bool _denseLayout(ListTileTheme tileTheme) {
    return dense != null ? dense : (tileTheme?.dense ?? false);
  }

  TextStyle _titleTextStyle(ThemeData theme, ListTileTheme tileTheme) {
    TextStyle style;
    if (tileTheme != null) {
      switch (tileTheme.style) {
        case ListTileStyle.drawer:
          style = theme.textTheme.body2;
          break;
        case ListTileStyle.list:
          style = theme.textTheme.subhead;
          break;
      }
    } else {
      style = theme.textTheme.subhead;
    }
    final Color color = _textColor(theme, tileTheme, style.color);
    return _denseLayout(tileTheme)
      ? style.copyWith(fontSize: 13.0, color: color)
      : style.copyWith(color: color);
  }

  TextStyle _subtitleTextStyle(ThemeData theme, ListTileTheme tileTheme) {
    final TextStyle style = theme.textTheme.body1;
    final Color color = _textColor(theme, tileTheme, theme.textTheme.caption.color);
    return _denseLayout(tileTheme)
      ? style.copyWith(color: color, fontSize: 12.0)
      : style.copyWith(color: color);
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterial(context));
    final ThemeData theme = Theme.of(context);
    final ListTileTheme tileTheme = ListTileTheme.of(context);

    final bool isTwoLine = !isThreeLine && subtitle != null;
    final bool isOneLine = !isThreeLine && !isTwoLine;
    double tileHeight;
    if (isOneLine)
      tileHeight = _denseLayout(tileTheme) ? 48.0 : 56.0;
    else if (isTwoLine)
      tileHeight = _denseLayout(tileTheme) ? 60.0 : 72.0;
    else
      tileHeight = _denseLayout(tileTheme) ? 76.0 : 88.0;

    // Overall, the list tile is a Row() with these children.
    final List<Widget> children = <Widget>[];

    IconThemeData iconThemeData;
    if (leading != null || trailing != null)
      iconThemeData = new IconThemeData(color: _iconColor(theme, tileTheme));

    if (leading != null) {
      children.add(IconTheme.merge(
        data: iconThemeData,
        child: new Container(
          margin: const EdgeInsetsDirectional.only(end: 16.0),
          width: 40.0,
          alignment: AlignmentDirectional.centerStart,
          child: leading,
        ),
      ));
    }

    final Widget primaryLine = new AnimatedDefaultTextStyle(
      style: _titleTextStyle(theme, tileTheme),
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
            style: _subtitleTextStyle(theme, tileTheme),
            duration: kThemeChangeDuration,
            child: subtitle,
          ),
        ],
      );
    }
    children.add(new Expanded(
      child: center,
    ));

    if (trailing != null) {
      children.add(IconTheme.merge(
        data: iconThemeData,
        child: new Container(
          margin: const EdgeInsetsDirectional.only(start: 16.0),
          alignment: AlignmentDirectional.centerEnd,
          child: trailing,
        ),
      ));
    }

    return new InkWell(
      onTap: enabled ? onTap : null,
      onLongPress: enabled ? onLongPress : null,
      child: new Semantics(
        selected: selected,
        enabled: enabled,
        child: new ConstrainedBox(
          constraints: new BoxConstraints(minHeight: tileHeight),
          child: new Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: new UnconstrainedBox(
              constrainedAxis: Axis.horizontal,
              child: new SafeArea(
                top: false,
                bottom: false,
                child: new Row(children: children),
              ),
            ),
          )
        ),
      ),
    );
  }
}
